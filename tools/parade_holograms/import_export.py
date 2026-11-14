#!/usr/bin/env python3
"""Validate the artist export, then embed world-space buffers for gl.UnitPiece.

The input DAE is never rewritten. Refuse malformed local OR inherited transforms
before producing output. Valid uniform scale/rotation is evaluated explicitly;
wing pivots and axes are converted with the same transform as their geometry.
"""
from pathlib import Path
import hashlib
import json
import numpy as np
from lxml import etree as ET
import build
from render_preview import read_geometry, NS

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
SOURCE = ROOT / 'objects3d/paradeHologramScenery.dae'
OUTPUT = ROOT / 'objects3d/paradeHologramSceneryRuntime.dae'


def validate_transform(matrix, name):
    if matrix.shape != (4, 4) or not np.isfinite(matrix).all():
        raise ValueError(name + ': invalid matrix')
    basis = matrix[:3, :3]
    scale = np.linalg.norm(basis, axis=0)
    if scale.min() < 1e-8 or scale.max() / scale.min() > 1.0001:
        raise ValueError(name + ': singular or non-uniform scale ' + str(scale))
    if not np.allclose((basis / scale).T @ (basis / scale), np.eye(3), atol=1e-4):
        raise ValueError(name + ': shear')
    if np.linalg.det(basis) < 0:
        raise ValueError(name + ': mirrored transform')
    if not np.allclose(matrix[3], [0, 0, 0, 1], atol=1e-6):
        raise ValueError(name + ': non-affine matrix')


def read_source(path=SOURCE):
    doc = ET.parse(str(path)).getroot()
    if doc.findtext('c:asset/c:up_axis', namespaces=NS) != 'Y_UP':
        raise ValueError('Expected Y_UP export')
    meter = float(doc.find('c:asset/c:unit', NS).get('meter'))
    geometries = {g.get('id'): g for g in doc.findall('c:library_geometries/c:geometry', NS)}
    pieces, frames, parents = {}, {}, {}

    def visit(node, parent_matrix, parent_name=None):
        name = node.get('name') or node.get('id')
        if name in frames:
            raise ValueError('Duplicate piece name: ' + name)
        transforms = [c for c in node if ET.QName(c).localname in ('matrix', 'scale', 'rotate', 'translate', 'skew', 'lookat')]
        if len(transforms) != 1 or ET.QName(transforms[0]).localname != 'matrix':
            raise ValueError(name + ': unsupported transform stack')
        local = np.fromstring(transforms[0].text, sep=' ').reshape(4, 4)
        world = parent_matrix @ local
        validate_transform(local, name + ' local')
        validate_transform(world, name + ' inherited')
        frames[name], parents[name] = world, parent_name
        buffers = []
        for instance in node.findall('c:instance_geometry', NS):
            positions, normals, uv = read_geometry(geometries[instance.get('url')[1:]])
            positions = positions.reshape(-1, 3) @ world[:3, :3].T + world[:3, 3]
            normals = normals.reshape(-1, 3) @ np.linalg.inv(world[:3, :3])
            lengths = np.linalg.norm(normals, axis=1)
            if np.any(lengths < 1e-10):
                raise ValueError(name + ': zero normal')
            normals /= lengths[:, None]
            buffers.append(np.column_stack((positions, normals, uv.reshape(-1, 2))))
        if buffers:
            if not name.startswith('parade'):
                raise ValueError('Unexpected scene geometry: ' + name)
            records = np.concatenate(buffers)
            pieces[name] = {'records': records, 'indices': list(range(len(records)))}
        for child in node.findall('c:node', NS):
            visit(child, world, name)

    for node in doc.findall('c:library_visual_scenes/c:visual_scene/c:node', NS):
        visit(node, np.diag([meter, meter, meter, 1]))
    required = {f'parade{family}{i}{role}' for family in ('civilian','dead','ai','helper')
                for i in range(1,5) for role in ('body','head','mask')}
    required |= {f'parademoth{i}{suffix}' for i in range(1,4) for suffix in ('','Sub1','Sub2')}
    required |= {'paradelotus1', 'paradelantern1', 'paradelantern2', 'paradecandle1'}
    missing = required - pieces.keys()
    if missing:
        raise ValueError('Incomplete export: ' + ', '.join(sorted(missing)))
    return pieces, frames, parents


def import_export():
    pieces, frames, parents = read_source()  # Entire gate runs before any writes.
    # The artist export omits the existing leaf. Preserve that motif from its
    # editable source rather than dropping a configured scene decoration.
    from cage_surface import mesh
    from props import build as build_props
    palette = json.loads((HERE / 'palette.json').read_text())
    leaf = next(m for m in build_props() if m['prop_key'] == 'leaf')
    pieces['paradeleaf'] = mesh(leaf['parts'], leaf['cell_size'], palette)
    frames['paradeleaf'] = np.eye(4)
    parents['paradeleaf'] = 'paradeholograms'

    original = json.loads((HERE / 'manifest.json').read_text())
    catalog = {'root': 'paradeholograms', 'figures': {}, 'props': {}}
    for model in original['models']:
        name = model['name']
        if model['category'] == 'prop':
            continue
        entry = {k: model[k] for k in ('label','category','pieces')}
        all_positions = np.concatenate([np.asarray(pieces[p]['records'])[:, :3] for p in entry['pieces'].values()])
        entry['bounds'] = [all_positions.min(0).tolist(), all_positions.max(0).tolist()]
        entry['height'] = float(all_positions[:, 1].max())
        # Original pivot is in figure space; apply any exported figure offset.
        p = np.array([*model['headPivot'], 1.0])
        entry['headPivot'] = (frames[name] @ p)[:3].tolist()
        catalog['figures'][name] = entry

    variants = {
        'candle': ['paradecandle1','paradecandle2','paradecandle003','paradecandle004','paradecandle005'],
        'lantern': ['paradelantern1','paradelantern2'],
        'lotus': ['paradelotus1'],
        'moth': ['parademoth1','parademoth2','parademoth3'],
        'cloud': ['paradecloud','paradecloud001','paradecloud002'],
    }
    for key in ('candle','lantern','moon','envelope','money','koi','lotus','leaf','star','cloud','pinwheel','moth'):
        choices = []
        for name in variants.get(key, ['parade' + key]):
            data = {'piece': name}
            if key == 'moth':
                data['wings'] = []
                for index in (1, 2):
                    wing = name + 'Sub' + str(index)
                    axis = frames[wing][:3, 0]
                    axis = axis / np.linalg.norm(axis)
                    data['wings'].append({'piece': wing, 'pivot': frames[wing][:3, 3].tolist(),
                                          'axis': axis.tolist(), 'sign': 1 if index == 1 else -1})
            choices.append(data)
        catalog['props'][key] = {'piece': choices[0]['piece'], 'variants': choices,
            'label': {'moth': 'Origami bird', 'lotus': 'Cherry blossom petal'}.get(key, key.capitalize())}

    # Build identity nodes from explicitly transformed records, retaining all
    # source geometry and named hierarchy. The original FBX DAE remains intact.
    doc = build.make_document([], pieces)
    root = doc.find('c:library_visual_scenes/c:visual_scene/c:node', NS)
    nodes = {'paradeholograms': root}
    for name in frames:
        if name == 'paradeholograms' or not name.startswith('parade'):
            continue
        parent = nodes.get(parents[name], root)
        gid = build.PREFIX + name + '_mesh' if name in pieces else None
        nodes[name] = build.node(parent, name, gid)
    ET.indent(doc, space='  ')
    payload_preservation = build.patch_payload(build.PAYLOAD, doc)
    OUTPUT.write_bytes(ET.tostring(doc, encoding='utf-8', xml_declaration=True))
    (ROOT/'luarules/configs/parade_hologram_models.lua').write_text(
        '-- Imported from artist DAE by tools/parade_holograms/import_export.py.\nreturn ' + build.lua(catalog) + '\n')
    report = {'source': str(SOURCE.relative_to(ROOT)), 'source_sha256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
              'runtime': str(OUTPUT.relative_to(ROOT)), 'pieces': {n: len(p['indices'])//3 for n,p in pieces.items()},
              'preserved_payload_definitions': payload_preservation, 'catalog': catalog,
              'preserved_missing_motifs': ['paradeleaf']}
    (HERE/'import_manifest.json').write_text(json.dumps(report, indent=2)+'\n')
    print(f'PASS: {len(frames)-1} authored nodes checked; {len(pieces)} embedded meshes, {sum(report["pieces"].values())} triangles')


if __name__ == '__main__':
    import_export()
