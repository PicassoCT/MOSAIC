"""Check palm contacts on the actual flute mesh in all exported hologram rigs."""
from pathlib import Path
import math
import re
import xml.etree.ElementTree as ET

NS = {'c': 'http://www.collada.org/2005/11/COLLADASchema'}
def mul(a,b): return [[sum(a[i][k]*b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
def apply(a,v): return [sum(a[i][k]*v[k] for k in range(3)) for i in range(3)]
def add(a,b): return [x+y for x,y in zip(a,b)]
def sub(a,b): return [x-y for x,y in zip(a,b)]
def dot(a,b): return sum(x*y for x,y in zip(a,b))
def norm(v): return math.sqrt(dot(v,v))
def rotation(angles):
    x,y,z=map(math.radians,angles)
    cx,sx,cy,sy,cz,sz=math.cos(x),math.sin(x),math.cos(y),math.sin(y),math.cos(z),math.sin(z)
    # Recoil ComposeTransform uses native YXZ script rotation.
    return mul(mul([[cy,0,sy],[0,1,0],[-sy,0,cy]],[[1,0,0],[0,cx,-sx],[0,sx,cx]]),[[cz,-sz,0],[sz,cz,0],[0,0,1]])
source=Path('scripts/lib_tiglil_flute.lua').read_text()
poses={name:{piece:list(map(float,values.split(','))) for piece,values in re.findall(r'(\w+)=\{([^}]+)\}',block)}
       for name,block in re.findall(r'    (\w+) = \{\n(.*?)    \},',source,re.S)}
head_angles={'across':[0,0,0],'acrossSway':[1,0,6],'forward':[0,0,0],'down':[20,0,0],'up':[-50,0,0]}
assert poses.keys()==head_angles.keys()
for filename in ('house_western_hologram.DAE','house_western_brothel_hologram.DAE','advertiseblimp_hologram.DAE'):
    tree=ET.parse(Path('objects3d')/filename)
    nodes={n.get('name'):n for n in tree.findall('.//c:visual_scene//c:node',NS)}
    def offset(name):
        m=list(map(float,nodes[name].findtext('c:matrix',namespaces=NS).split()))
        return [m[3],m[7],m[11]]
    scale=offset('tigLil')[2]/12
    def body_offset(name): return [v/scale for v in offset(name)]
    def vertices(name):
        geometry=nodes[name].find('c:instance_geometry',NS).get('url')[1:]
        mesh=tree.find('.//c:geometry[@id="'+geometry+'"]/c:mesh',NS)
        coords=mesh.find('c:vertices/c:input[@semantic="POSITION"]',NS).get('source')[1:]
        values=list(map(float,mesh.findtext('c:source[@id="'+coords+'"]/c:float_array',namespaces=NS).split()))
        return [[v/scale for v in values[i:i+3]] for i in range(0,len(values),3)]
    flute_length=-min(v[1] for v in vertices('tlflute'))
    for name,pose in poses.items():
        head=rotation(head_angles[name]);flute=rotation(pose['tlflute'])
        mouth=add(body_offset('tlHead'),apply(head,body_offset('tlflute')))
        direction=apply(mul(head,flute),[0,-1,0])
        contacts=[]
        for arm,sign in (('tlarm',1),('tlarmr',-1)):
            palm=[sign*5.1,-.2,.15]
            assert min(norm(sub(v,palm)) for v in vertices(arm))<.5,'calibration misses the hand mesh'
            hand=add(body_offset(arm),apply(rotation(pose[arm]),palm))
            distance=dot(sub(hand,mouth),direction)
            closest=add(mouth,[distance*v for v in direction])
            assert norm(sub(hand,closest))<.001,(filename,name,arm,'hand misses flute')
            assert .5<distance<flute_length-.5,(filename,name,arm,'hand beyond instrument')
            contacts.append(distance)
        assert abs(contacts[0]-contacts[1])>.6,(filename,name,'hands overlap')
print('PASS: five flute poses contact the actual instrument with separate hands in all three rigs')
