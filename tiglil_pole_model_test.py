"""Validate moving pole grips and floor clearance against all three DAE rigs."""
import math, os, subprocess, tempfile
from pathlib import Path
import xml.etree.ElementTree as ET
NS={'c':'http://www.collada.org/2005/11/COLLADASchema'}
def add(a,b):return [x+y for x,y in zip(a,b)]
def mul(a,b):return [[sum(a[i][k]*b[k][j] for k in range(3)) for j in range(3)]for i in range(3)]
def apply(a,v):return [sum(a[i][k]*v[k] for k in range(3))for i in range(3)]
def rotation(a):
    x,y,z=map(math.radians,a)
    cx,sx,cy,sy,cz,sz=math.cos(x),math.sin(x),math.cos(y),math.sin(y),math.cos(z),math.sin(z)
    return mul(mul([[cy,0,sy],[0,1,0],[-sy,0,cy]],[[1,0,0],[0,cx,-sx],[0,sx,cx]]),[[cz,-sz,0],[sz,cz,0],[0,0,1]])
FILES=('house_western_hologram.DAE','house_western_brothel_hologram.DAE','advertiseblimp_hologram.DAE')
profiles=[]
for filename in FILES:
    tree=ET.parse(Path('objects3d')/filename)
    nodes={n.get('name'):n for n in tree.findall('.//c:visual_scene//c:node',NS)}
    entries=[]
    for name in ('tigLil','dancepivot','tlpole'):
        n=nodes[name];m=list(map(float,n.findtext('c:matrix',namespaces=NS).split()))
        entry='offset={'+','.join(str(m[i])for i in (3,7,11))+'}'
        if name=='tlpole':
            ref=n.find('c:instance_geometry',NS).get('url')[1:];mesh=tree.find('.//c:geometry[@id="'+ref+'"]/c:mesh',NS)
            src=mesh.find('c:vertices/c:input[@semantic="POSITION"]',NS).get('source')[1:]
            a=list(map(float,mesh.findtext('c:source[@id="'+src+'"]/c:float_array',namespaces=NS).split()))
            entry+=',min={'+','.join(str(min(a[i::3]))for i in range(3))+'},max={'+','.join(str(max(a[i::3]))for i in range(3))+'}'
        entries.append(name+'={'+entry+'}')
    profiles.append('["'+filename+'"]={'+','.join(entries)+'}')
EXPORT='''
function include(name)return dofile('scripts/'..name)end
local pole=include('lib_tiglil_pole.lua')
for filename,info in pairs(PROFILES)do
local rig=pole.calibrate(function(name)return info[name]end,11060.378906/12)
for _,stage in ipairs({0,9})do
 local index=0
 pole.play({show=function()end,sleep=function()end,apply=function(p,ms)
  index=index+1
  print(filename..';'..stage..';'..index..';move;'..table.concat(p.move,','))
  for name,a in pairs(p.turns)do print(filename..';'..stage..';'..index..';'..name..';'..table.concat(a,','))end
  local contacts=0
  for name,v in pairs(p.contacts)do contacts=contacts+1;print(filename..';'..stage..';'..index..';contact_'..name..';'..table.concat(v,','))end
  assert(contacts>=1,'both hands release during the pole sequence')
 end},stage,rig)
end
end
'''
EXPORT=EXPORT.replace('PROFILES','{'+','.join(profiles)+'}')
with tempfile.NamedTemporaryFile(mode='w',suffix='.lua') as f:
    f.write(EXPORT);f.flush()
    output=subprocess.check_output([os.environ.get('LUA','lua5.1'),f.name],text=True)
poses={}
for line in output.splitlines():
    filename,stage,index,name,values=line.split(';')
    poses.setdefault((filename,int(stage),int(index)),{})[name]=list(map(float,values.split(',')))
for filename in FILES:
    tree=ET.parse(Path('objects3d')/filename)
    nodes={n.get('name'):n for n in tree.findall('.//c:visual_scene//c:node',NS)}
    scale=float(nodes['tigLil'].findtext('c:matrix',namespaces=NS).split()[11])/12
    def offset(name):
        m=list(map(float,nodes[name].findtext('c:matrix',namespaces=NS).split()))
        return [m[i]/scale for i in (3,7,11)]
    def vertices(name):
        ref=nodes[name].find('c:instance_geometry',NS).get('url')[1:]
        mesh=tree.find('.//c:geometry[@id="'+ref+'"]/c:mesh',NS)
        src=mesh.find('c:vertices/c:input[@semantic="POSITION"]',NS).get('source')[1:]
        a=list(map(float,mesh.findtext('c:source[@id="'+src+'"]/c:float_array',namespaces=NS).split()))
        return [[v/scale for v in a[i:i+3]] for i in range(0,len(a),3)]
    pole=offset('tlpole');pole_mesh=vertices('tlpole')
    pm=list(map(float,nodes['tlpole'].findtext('c:matrix',namespaces=NS).split()))
    pole_z=[pm[8]*v[0]+pm[9]*v[1]+pm[10]*v[2]+pole[2]for v in pole_mesh]
    low,high=min(pole_z),max(pole_z)
    feet={name:vertices(name)for name in ('tllegLow','tllegLowR')}
    errors=[];minimum_floor=math.inf
    for (model,stage,index),p in poses.items():
        if model!=filename:continue
        center=add(add(offset('dancepivot'),offset('tigLil')),p['move'])
        body=rotation(p['tigLil'])
        for name,sign in (('tlarm',1),('tlarmr',-1)):
            if 'contact_'+name not in p:continue
            palm=add(offset(name),apply(rotation(p[name]),[sign*5.1,-.2,.15]))
            actual=add(center,apply(body,palm))
            expected=p['contact_'+name]
            error=math.sqrt(sum((a-b)**2 for a,b in zip(actual,expected)));errors.append(error)
            assert error<.001,(filename,stage,index,name,'grip detached',error)
            radius=math.hypot(actual[0]-pole[0],actual[1]-pole[1])
            assert .25<radius<.29 and low+stage<actual[2]<high+stage,(filename,index,'hand beyond pole')
        floor=math.inf
        for upper,lower in (('tllegUp','tllegLow'),('tllegUpR','tllegLowR')):
            hip,knee=rotation(p[upper]),rotation(p[lower]);R=mul(body,mul(hip,knee))
            base=apply(body,add(offset(upper),apply(hip,offset(lower))))
            floor=min(floor,min(apply(R,v)[2]for v in feet[lower])+base[2]+center[2]-stage)
        minimum_floor=min(minimum_floor,floor)
        assert floor>-.03,(filename,stage,index,'foot penetrates stage',floor)
    print(f'PASS: {filename}: {sum(k[0]==filename for k in poses)} pole samples; max grip error {max(errors):.5f}, min floor {minimum_floor:.5f}')
