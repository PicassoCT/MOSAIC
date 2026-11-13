"""Exercise street projection with the real three rigs and native YXZ transforms."""
import math, os, subprocess, tempfile
import xml.etree.ElementTree as ET
from pathlib import Path
NS={'c':'http://www.collada.org/2005/11/COLLADASchema'}
def mul(a,b):return [[sum(a[i][k]*b[k][j] for k in range(4))for j in range(4)]for i in range(4)]
def lua(v):
    if isinstance(v,str):return repr(v)
    if isinstance(v,dict):return '{'+','.join('['+lua(k)+']='+lua(x)for k,x in v.items())+'}'
    if isinstance(v,(list,tuple)):return '{'+','.join(lua(x)for x in v)+'}'
    return str(v)
fixtures={}
for filename in ('house_western_hologram.DAE','house_western_brothel_hologram.DAE','advertiseblimp_hologram.DAE'):
    tree=ET.parse(Path('objects3d')/filename)
    nodes={n.get('name'):n for n in tree.findall('.//c:visual_scene//c:node',NS)}
    parents={child:node for node in tree.iter()for child in node}
    anchor=nodes['tiglil_anchor'];death=nodes['deathpivot']
    assert parents[death] is anchor and parents[anchor].get('name')=='brothel_spin'
    def matrix(node):
        v=list(map(float,node.findtext('c:matrix',namespaces=NS).split()))
        return [v[i:i+4]for i in range(0,16,4)]
    I=[[1 if i==j else 0 for j in range(4)]for i in range(4)]
    assert matrix(anchor)==I,'anchor changes authored rest placement'
    def accumulated(node):
        m=matrix(node);parent=parents.get(node)
        return mul(accumulated(parent),m)if parent is not None and parent.tag.endswith('node')else m
    root=accumulated(parents[anchor]);root=[[v*.02 if i<3 else v for v in row]for i,row in enumerate(root)]
    entries={}
    for name in ('tigLil','tlHead','tlhairup','tlhairdown','tlarm','tlarmr','tllegUp','tllegUpR','tllegLow','tllegLowR'):
        node=nodes[name];m=matrix(node);parent=parents[node]
        while parent is not anchor:m=mul(matrix(parent),m);parent=parents[parent]
        ref=node.find('c:instance_geometry',NS).get('url')[1:]
        mesh=tree.find('.//c:geometry[@id="'+ref+'"]/c:mesh',NS)
        src=mesh.find('c:vertices/c:input[@semantic="POSITION"]',NS).get('source')[1:]
        v=list(map(float,mesh.findtext('c:source[@id="'+src+'"]/c:float_array',namespaces=NS).split()))
        entries[name]={'matrix':m,'min':[min(v[i::3])for i in range(3)],'max':[max(v[i::3])for i in range(3)]}
    fixtures[filename]={'parent':root,'parts':entries}
source=Path('tests/tiglil_ground_test.lua').read_text().replace('-- MODEL_FIXTURES', 'local fixtures='+lua(fixtures))
with tempfile.NamedTemporaryFile(mode='w',suffix='.lua')as f:
    f.write(source);f.flush()
    subprocess.run([os.environ.get('LUA','lua5.1'),f.name],check=True)

for script in ('house_western_hologram_script.lua','house_western_brothel_hologram_script.lua'):
    assert 'tigLilAnimations.enablePeopleAnimations()' in (Path('scripts')/script).read_text()
assert 'enablePeopleAnimations' not in Path('scripts/advertisingblimphologramscript.lua').read_text()
print('PASS: pedestrian placement is opt-in for building holograms; blimp is excluded')
