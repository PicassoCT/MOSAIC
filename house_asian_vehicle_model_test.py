"""Validate authored tool paths against the actual exported assembly geometry."""
from pathlib import Path
import math
import re
import xml.etree.ElementTree as ET

NS = {'c': 'http://www.collada.org/2005/11/COLLADASchema'}
PREFIX = 'ID_l100_Industrial_RoofBlock1Sub'


def mul(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(4)) for j in range(4)] for i in range(4)]


def apply(a, v):
    return [sum(a[i][k] * (v + [1])[k] for k in range(4)) for i in range(3)]


def rotation(axis, angle):
    c, s = math.cos(math.radians(angle)), math.sin(math.radians(angle))
    if axis == 1:
        return [[1, 0, 0, 0], [0, c, -s, 0], [0, s, c, 0], [0, 0, 0, 1]]
    return [[c, -s, 0, 0], [s, c, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]


def distance(a, b):
    return math.sqrt(sum((x-y)**2 for x, y in zip(a, b)))


tree = ET.parse('objects3d/house_asian.dae')
nodes = {n.get('name'): n for n in tree.findall('.//c:visual_scene//c:node', NS)}
geometries = {g.get('id'): g for g in tree.findall('.//c:geometry', NS)}


def matrix(node):
    v = list(map(float, node.findtext('c:matrix', namespaces=NS).split()))
    return [v[i:i+4] for i in range(0, 16, 4)]


def vertices(node):
    mesh = geometries[node.find('c:instance_geometry', NS).get('url')[1:]].find('c:mesh', NS)
    source = mesh.find('c:vertices/c:input[@semantic="POSITION"]', NS).get('source')[1:]
    v = list(map(float, mesh.findtext('c:source[@id="'+source+'"]/c:float_array', namespaces=NS).split()))
    return [v[i:i+3] for i in range(0, len(v), 3)]


source = Path('scripts/lib_house_asian_vehicle_assembly.lua').read_text().split('local M = {}')[0]
profiles = []
for block in re.findall(r'^    \{\n(.*?)^    \},', source, re.M | re.S):
    profile = {key: list(map(float, values.split(','))) for key, values in
               re.findall(r'(park|approach|clearEnd)=\{([^}]+)\}', block)}
    profile['seam'] = [list(map(float, values.split(','))) for values in
                       re.findall(r'^            \{([^}]+)\}', block, re.M)]
    profiles.append(profile)
assert len(profiles) == 4
raw_node = nodes[PREFIX+'26']
raw = [apply(matrix(raw_node), v) for v in vertices(raw_node)]
elevator = nodes[PREFIX+'25']
assert nodes[PREFIX+'27'] in list(elevator), 'VTOL parent changed; review departure compensation'

for arm, (base, profile) in enumerate(zip((1, 7, 13, 19), profiles), 1):
    chain = [nodes[PREFIX+str(base)]]
    for _ in range(5):
        children = chain[-1].findall('c:node', NS)
        assert len(children) == 1, ('robot no longer has a single six-joint chain', arm)
        chain.append(children[0])
    assert chain[0] in list(elevator)
    tool = vertices(chain[-1])
    tip = [(min(v[a] for v in tool)+max(v[a] for v in tool))/2 for a in (0, 1)] + [max(v[2] for v in tool)]
    assert min(distance(tip, v) for v in tool) < 1, 'tooltip calibration misses tool mesh'

    def endpoint(pose, roll=0):
        # Recoil ComposeTransform uses baked rotation followed by script YXZ.
        # Its clockwise Rotate* and negative script angles cancel: ordinary
        # right-handed Rx/Rz below match the native unit-script commands.
        transform = rotation(1, 0)
        for joint, node in enumerate(chain):
            transform = mul(transform, matrix(node))
            if joint == 1:
                transform = mul(transform, rotation(3, pose[0]))
            elif joint in (2, 3, 4):
                transform = mul(transform, rotation(1, pose[joint-1]))
            elif joint == 5:
                transform = mul(transform, rotation(3, roll))
        return apply(transform, tip)

    seam = profile['seam']
    assert len(seam) == 5
    start, finish = endpoint(seam[0]), endpoint(seam[-1])
    for point in (start, finish):
        assert min(distance(point, v) for v in raw) < .7, ('tool misses actual frame', arm, point)
    for name, point in (('approach', start), ('clearEnd', finish)):
        assert distance(endpoint(profile[name]), [point[0], point[1], point[2]+9]) < .01, ('tool failed to lift clear', arm)
    park = endpoint(profile['park'])
    assert abs(park[0]) > 63 and park[0]*start[0] > 0, ('parked tool obstructs vehicle', arm)
    for segment in range(4):
        for step in range(11):
            t = step/10
            pose = [a*(1-t)+b*t for a, b in zip(seam[segment], seam[segment+1])]
            along = (segment+t)/4
            target = [a*(1-along)+b*along for a, b in zip(start, finish)]
            for roll in (-60, 0, 60):
                assert distance(endpoint(pose, roll), target) < .45, ('tool strays off seam', arm, segment, step)

for number, sign in ((28, -1), (29, 1)):
    door = nodes[PREFIX+str(number)]
    verts = vertices(door)
    far = max(verts, key=lambda v: abs(v[1]))
    opened = apply(mul(matrix(door), rotation(1, sign*110)), far)
    closed = apply(matrix(door), far)
    assert opened[2] > closed[2]+45, 'door opens down into launch bay'
print('PASS assembly model: four complete arm chains, frame contacts, seam traversal, tool withdrawal and upward hatches')
