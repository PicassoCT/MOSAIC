"""Check authored solo poses against actual lower-leg meshes in all three rigs."""
import math
import os
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET

NS={'c':'http://www.collada.org/2005/11/COLLADASchema'}
def mul(a,b):return [[sum(a[i][k]*b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
def apply(a,v):return [sum(a[i][k]*v[k] for k in range(3)) for i in range(3)]
def add(a,b):return [x+y for x,y in zip(a,b)]
def rotation(angles):
    x,z,y=map(math.radians,angles[:3]) # authored Y-up -> native Z-up
    cx,sx,cy,sy,cz,sz=math.cos(x),math.sin(x),math.cos(y),math.sin(y),math.cos(z),math.sin(z)
    return mul(mul([[cy,0,sy],[0,1,0],[-sy,0,cy]],[[1,0,0],[0,cx,-sx],[0,sx,cx]]),[[cz,-sz,0],[sz,cz,0],[0,0,1]])
EXPORT='''
local dance=dofile('scripts/lib_tiglil_dance.lua')
local styles={}
for name,style in pairs(dance.styles)do styles[name]=style end
for name,style in pairs(dofile('scripts/lib_tiglil_business.lua'))do styles[name]=style end
for name,style in pairs(dofile('scripts/lib_tiglil_brothel.lua'))do styles[name]=style end
for name,style in pairs(dofile('scripts/lib_tiglil_social.lua'))do styles[name]=style end
for sign=0,1 do
 math.random=function()return sign end
 for name,style in pairs(styles) do
  local state,index={},0
  dance.play(name,{
   turn=function(id,a)state[id]={a[1],a[2],a[3]}end,
   move=function(id,a)state.move=a end,
   sleep=function()
    index=index+1
    for id,a in pairs(state)do print(name..';'..sign..';'..index..';'..id..';'..table.concat(a,','))end
   end,
   finish=function()end,
  },style)
 end
end
'''
with tempfile.NamedTemporaryFile(mode='w',suffix='.lua') as f:
    f.write(EXPORT);f.flush()
    output=subprocess.check_output([os.environ.get('LUA','lua5.1'),f.name],text=True)
poses={}
for line in output.splitlines():
    style,sign,index,piece,angles=line.split(';')
    poses.setdefault((style,sign,int(index)),{})[piece]=list(map(float,angles.split(',')))
for filename in ('house_western_hologram.DAE','house_western_brothel_hologram.DAE','advertiseblimp_hologram.DAE'):
    tree=ET.parse(Path('objects3d')/filename)
    nodes={n.get('name'):n for n in tree.findall('.//c:visual_scene//c:node',NS)}
    def offset(name):
        m=list(map(float,nodes[name].findtext('c:matrix',namespaces=NS).split()))
        return [m[3]/scale,m[7]/scale,m[11]/scale]
    scale=float(nodes['tigLil'].findtext('c:matrix',namespaces=NS).split()[11])/12
    def vertices(name):
        ref=nodes[name].find('c:instance_geometry',NS).get('url')[1:]
        mesh=tree.find('.//c:geometry[@id="'+ref+'"]/c:mesh',NS)
        src=mesh.find('c:vertices/c:input[@semantic="POSITION"]',NS).get('source')[1:]
        a=list(map(float,mesh.findtext('c:source[@id="'+src+'"]/c:float_array',namespaces=NS).split()))
        return [[v/scale for v in a[i:i+3]] for i in range(0,len(a),3)]
    feet={name:vertices(name) for name in ('tllegLow','tllegLowR')}
    maximum_gap=0
    for key,p in poses.items():
        lowest=math.inf
        body=rotation(p['tigLil'])
        for upper,lower in (('tllegUp','tllegLow'),('tllegUpR','tllegLowR')):
            hip,knee=rotation(p[upper]),rotation(p[lower])
            R=mul(body,mul(hip,knee))
            base=apply(body,add(offset(upper),apply(hip,offset(lower))))
            foot=min(apply(R,v)[2] for v in feet[lower])+base[2]+12+p['move'][1]
            lowest=min(lowest,foot)
        assert -.02<lowest<.4,(filename,key,'support foot misses floor',lowest)
        maximum_gap=max(maximum_gap,lowest)
    print(f'PASS: {filename}: {len(poses)} mirrored solo poses, support foot within {maximum_gap:.3f} body units of floor')
