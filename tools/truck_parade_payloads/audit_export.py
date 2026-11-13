#!/usr/bin/env python3
"""Audit the authored COLLADA against the runtime catalog; optionally refresh bounds.

Uses the exported matrices and unit scale, without running the legacy generator.
Requires NumPy and Lua. This validates source geometry, not an in-engine render.
"""
from pathlib import Path
import argparse
import hashlib
import json
import math
import shutil
import subprocess
import xml.etree.ElementTree as ET
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
MODEL = ROOT / 'objects3d/truckPayloadParade.dae'
NS = {'c': 'http://www.collada.org/2005/11/COLLADASchema'}


def read_model(path=MODEL):
    root = ET.parse(path).getroot()
    assert root.findtext('c:asset/c:up_axis', namespaces=NS) == 'Y_UP'
    scale = float(root.find('c:asset/c:unit', NS).get('meter'))
    ids = {e.get('id'): e for e in root.iter() if e.get('id')}
    pieces, transforms, parents = {}, {}, {}
    degenerate_uv = 0

    def visit(node, parent, parent_name=None):
        nonlocal degenerate_uv
        name = node.get('name')
        assert name not in transforms, 'Duplicate piece: ' + name
        matrix = parent @ np.fromstring(node.find('c:matrix', NS).text, sep=' ').reshape(4, 4)
        assert np.isfinite(matrix).all()
        transforms[name], parents[name] = matrix, parent_name
        chunks = []
        for instance in node.findall('c:instance_geometry', NS):
            mesh = ids[instance.get('url')[1:]].find('c:mesh', NS)
            sources = {}
            for src in mesh.findall('c:source', NS):
                array = src.find('c:float_array', NS)
                data = np.fromstring(array.text, sep=' ')
                assert len(data) == int(array.get('count')) and np.isfinite(data).all()
                acc = src.find('c:technique_common/c:accessor', NS)
                sources[src.get('id')] = data.reshape(-1, int(acc.get('stride', '1')))
            for triangles in mesh.findall('c:triangles', NS):
                count = int(triangles.get('count'))
                if not count:
                    continue
                inputs = triangles.findall('c:input', NS)
                stride = 1 + max(int(i.get('offset', '0')) for i in inputs)
                indices = np.fromstring(triangles.find('c:p', NS).text, sep=' ', dtype=int).reshape(-1, stride)
                assert len(indices) == count * 3
                attributes = {}
                for inp in inputs:
                    source = inp.get('source')[1:]
                    if inp.get('semantic') == 'VERTEX':
                        source = ids[source].find('c:input[@semantic="POSITION"]', NS).get('source')[1:]
                    ix = indices[:, int(inp.get('offset', '0'))]
                    assert ix.min() >= 0 and ix.max() < len(sources[source])
                    attributes[inp.get('semantic')] = sources[source][ix]
                xyz = attributes['VERTEX'][:, :3]
                xyz = (matrix @ np.column_stack((xyz, np.ones(len(xyz)))).T).T[:, :3]
                normals = attributes['NORMAL'][:, :3] @ np.linalg.inv(matrix[:3, :3])
                length = np.linalg.norm(normals, axis=1)
                assert (length > 1e-12).all(), name + ': zero normal'
                normals /= length[:, None]
                uv = attributes['TEXCOORD'][:, :2]
                faces = xyz.reshape(-1, 3, 3)
                cross = np.cross(faces[:, 1] - faces[:, 0], faces[:, 2] - faces[:, 0])
                assert (np.linalg.norm(cross, axis=1) > 1e-8).all(), name + ': degenerate triangle'
                uvt = uv.reshape(-1, 3, 2)
                a, b = uvt[:, 1] - uvt[:, 0], uvt[:, 2] - uvt[:, 0]
                degenerate_uv += int((np.abs(a[:, 0]*b[:, 1] - a[:, 1]*b[:, 0]) < 1e-12).sum())
                chunks.append(np.column_stack((xyz, normals, uv)))
        if chunks:
            pieces[name] = np.concatenate(chunks)
        for child in node.findall('c:node', NS):
            visit(child, matrix, name)

    scene = root.find('c:library_visual_scenes/c:visual_scene', NS)
    for node in scene.findall('c:node', NS):
        if node.get('name') == 'paradeholograms':
            continue  # Independently audited, engine-hidden scenery stock.
        visit(node, np.diag([scale, scale, scale, 1]))
    return pieces, transforms, parents, scale, degenerate_uv


def read_catalog(lua):
    source = '''local c=dofile('scripts/lib_truck_parade_payloads.lua')
print('SCALE',c.centerMoveScale)
for k,v in pairs(c.carrierOffsets) do print('MOUNT',k,v.y,v.z) end
for i,v in ipairs(c.variants) do
 print('VARIANT',i,v.key,v.title,table.concat(v.pieces,','))
 for _,m in ipairs(v.motion or {}) do print('MOTION',i,m.pieceName,m.axis,m.spin or 0,m.angle or 0) end
end
'''
    text = subprocess.check_output([lua, '-'], input=source, cwd=ROOT, text=True)
    variants, mounts, move_scale = [], [np.zeros(3)], None
    for line in text.splitlines():
        f = line.split('\t')
        if f[0] == 'SCALE': move_scale = float(f[1])
        elif f[0] == 'MOUNT': mounts.append(np.array([0, float(f[2]), float(f[3])]))
        elif f[0] == 'VARIANT':
            variants.append({'index': int(f[1]), 'key': f[2], 'title': f[3], 'pieces': f[4].split(','), 'motion': []})
        elif f[0] == 'MOTION':
            variants[int(f[1])-1]['motion'].append({'piece': f[2], 'axis': f[3], 'spin': float(f[4]), 'angle': float(f[5])})
    return variants, mounts, move_scale


def audit(lua, write=False):
    pieces, transforms, parents, scale, uv_warnings = read_model()
    variants, mounts, move_scale = read_catalog(lua)
    assert len(variants) == 24 and len(transforms) == 41
    assert parents['center'] is None and np.isclose(move_scale * scale, 1)
    assert {name for name, parent in parents.items() if parent == 'center'} == {f'Float{i:02}' for i in range(1, 25)}
    expected = {name for variant in variants for name in variant['pieces']}
    assert expected == set(pieces) - {'center'}
    animated = {m['piece'] for v in variants for m in v['motion']}
    assert animated == {n for n in pieces if 'Sub' in n} and len(animated) == 16
    spinners = [m for v in variants for m in v['motion'] if m['spin']]
    assert len(spinners) == 1 and spinners[0]['piece'] == 'Float24Sub1' and spinners[0]['axis'] == 'x'
    rotor = pieces['Float24Sub1'][:, :3]
    pivot = transforms['Float24Sub1'][:3, 3]
    assert np.linalg.norm((rotor.min(0) + rotor.max(0))[:2] / 2 - pivot[:2]) < .01, 'Rotor pivot is not at its axle'
    axis = transforms['Float24Sub1'][:3, 0]
    assert abs(axis[2]) / np.linalg.norm(axis) > .999, 'Rotor axle is not horizontal'
    all_points = np.concatenate([pieces[n][:, :3] for n in expected])
    mid = (all_points.min(0) + all_points.max(0)) / 2
    radius, high = 0, -math.inf
    for variant in variants:
        name = f"Float{variant['index']:02}"
        assert variant['pieces'][0] == name
        for child in variant['pieces'][1:]: assert parents[child] == name
        points = np.concatenate([pieces[n][:, :3] for n in variant['pieces']])
        variant['bounds'] = [points.min(0).tolist(), points.max(0).tolist()]
        variant['triangles'] = len(points) // 3
        variant['pivots'] = {n: transforms[n][:3, 3].tolist() for n in variant['pieces'][1:]}
        for n in variant['pieces']:
            xyz = pieces[n][:, :3]
            for offset in mounts:
                if n in animated:
                    p = transforms[n][:3, 3] + offset
                    # Full pivot sphere encloses all poses, including a full rotor revolution.
                    reach = np.linalg.norm(xyz - transforms[n][:3, 3], axis=1).max()
                    radius = max(radius, np.linalg.norm(p - mid) + reach)
                    high = max(high, p[1] + reach)
                else:
                    radius = max(radius, np.linalg.norm(xyz + offset - mid, axis=1).max())
                    high = max(high, (xyz + offset)[:, 1].max())
    bounds = {'radius': math.ceil(radius) + 1, 'height': math.ceil(high) + 1, 'midpos': mid.tolist()}
    report = {'schema': 2, 'source': 'User-authored FBX COLLADA export, 2026-11-05',
        'generator': 'tools/truck_parade_payloads/audit_export.py --write-metadata',
        'model_sha256': hashlib.sha256(MODEL.read_bytes()).hexdigest(), 'unit_meter': scale,
        'culling': bounds, 'zero_area_uv_triangles': uv_warnings, 'variants': variants}
    manifest = ROOT / 'tools/truck_parade_payloads/manifest.json'
    sidecar = MODEL.with_suffix('.dae.lua')
    if write:
        manifest.write_text(json.dumps(report, indent=2) + '\n')
        sidecar.write_text('-- Generated by tools/truck_parade_payloads/audit_export.py.\n'
            '-- Bounds enclose all articulated poses and carrier mounting offsets.\n'
            f"return {{radius = {bounds['radius']}, height = {bounds['height']}, midpos = {{"
            + ', '.join(f'{x:.6f}' for x in mid) + '},\n'
            '    tex1 = "house_asian_diffuse.dds",\n'
            '    tex2 = "house_asian_selfilu_reflection.png",\n}\n')
    else:
        assert json.loads(manifest.read_text()) == report, 'Stale manifest: run audit_export.py --write-metadata'
        actual = subprocess.check_output([lua, '-'], cwd=ROOT, text=True,
            input="local b=dofile('objects3d/truckPayloadParade.dae.lua'); print(b.radius,b.height,unpack(b.midpos))")
        v = list(map(float, actual.split()))
        assert v[:2] == [bounds['radius'], bounds['height']] and np.allclose(v[2:], mid, atol=1e-6)
    print(f"PASS: 24 floats, 16 articulated children; {sum(v['triangles'] for v in variants):,} triangles")
    print('PASS: actual catalog, hierarchy, geometry indices, nonzero triangles/normals, rotor axle and animated bounds')
    print(f"Bounds: radius={bounds['radius']}, height={bounds['height']}")
    if uv_warnings:
        print(f'NOTE: {uv_warnings} exported triangles have zero UV area; tangent shading needs in-engine review')
    return pieces, transforms


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--lua', default=shutil.which('lua'))
    parser.add_argument('--write-metadata', action='store_true')
    args = parser.parse_args()
    assert args.lua, 'Lua interpreter required'
    audit(args.lua, args.write_metadata)
