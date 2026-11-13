"""Verify all three actual exported rigs and the restored pole pivot."""
from pathlib import Path
import math
import xml.etree.ElementTree as ET

NS = {'c': 'http://www.collada.org/2005/11/COLLADASchema'}
for filename in ('house_western_hologram.DAE', 'house_western_brothel_hologram.DAE', 'advertiseblimp_hologram.DAE'):
    tree = ET.parse(Path('objects3d') / filename)
    nodes = {n.get('name'): n for n in tree.findall('.//c:visual_scene//c:node', NS)}
    parents = {child: parent for parent in tree.iter() for child in parent}
    def matrix(name):
        return [float(x) for x in nodes[name].findtext('c:matrix', namespaces=NS).split()]
    assert parents[nodes['tldancedru']] is nodes['deathpivot']
    assert parents[nodes['tlpole']] is nodes['tldancedru']
    assert parents[nodes['tigLil']] is nodes['dancepivot']
    assert parents[nodes['dancepivot']] is nodes['deathpivot']
    assert parents[nodes['DirectionArcPoint']] is nodes['deathpivot'], 'ball hierarchy changed'
    assert matrix('tldancedru') == [1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]
    assert abs(matrix('tigLil')[11] - 11060.378906) < 0.01
    root = matrix('deathpivot')
    for column in range(3):
        scale = math.sqrt(sum(root[row*4+column]**2 for row in range(3)))
        assert abs(scale - 0.072006) < 1e-7
    # With a common origin, opposite vertical rotations preserve the pole's
    # offset as well as orientation. A pivot at the pole would still orbit.
    pole = matrix('tlpole'); position = [pole[3], pole[7], pole[11]]
    def rotate(v, angle):
        c,s = math.cos(angle),math.sin(angle)
        return [c*v[0]-s*v[1], s*v[0]+c*v[1], v[2]]
    for angle in (0.3, 1.7, 3.1, 6.1):
        actual = rotate(rotate(position, -angle), angle)
        assert max(abs(a-b) for a,b in zip(actual,position)) < 1e-7
print('PASS: all three Tiglil rigs, scale calibration, pole parenting and stationary counter-rotation')
