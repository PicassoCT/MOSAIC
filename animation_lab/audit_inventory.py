#!/usr/bin/env python3
"""Read-only authored-rig and clip inventory; not an engine/visual acceptance test."""
from collections import Counter
import argparse
from pathlib import Path
import csv
import hashlib
import json
import re
import subprocess
import xml.etree.ElementTree as ET
from lupa.lua51 import LuaRuntime

GAME = Path('/home/picasso/.spring/games/Mosaic.sdd')
OUT = Path(__file__).resolve().parent / 'review_inventory'
NS = {'c': 'http://www.collada.org/2005/11/COLLADASchema'}
CIV_CORE = 'root center UpBody Head1 UpArm1 UpArm2 LowArm1 LowArm2 UpLeg1 UpLeg2 LowLeg1 LowLeg2 Feet1 Feet2'.split()
OP_CORE = 'center Torso Head UpArm1 UpArm2 LowArm1 LowArm2 UpLeg1 UpLeg2 LowLeg1 LowLeg2'.split()
FAMILIES = {
    'civilian': ('animations_civilian_female.lua', ['animations_civilian_prayers.lua', 'animations_civilian_aerosols.lua']),
    'asset': ('animation_assasin_male.lua', []),
    'propagator': ('animation_operativepropagator_male.lua', []),
    'investigator': ('animation_operativeinvestigator_female.lua', []),
}

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def rig(path, family):
    tree = ET.parse(path)
    unit = tree.find('c:asset/c:unit', NS)
    records = []
    def walk(node, parent):
        name = node.get('name') or node.get('id')
        transforms = []
        for child in node:
            kind = child.tag.split('}')[-1]
            if kind in {'matrix', 'translate', 'rotate', 'scale'}:
                transforms.append({'kind': kind, 'values': [float(v) for v in child.text.split()]})
        records.append({'name': name, 'id': node.get('id'), 'parent': parent, 'transforms': transforms})
        for child in node.findall('c:node', NS):
            walk(child, name)
    for scene in tree.findall('c:library_visual_scenes/c:visual_scene', NS):
        for node in scene.findall('c:node', NS):
            walk(node, None)
    counts = Counter(r['name'] for r in records)
    names = set(counts)
    core = CIV_CORE if family == 'civilian' else OP_CORE
    sidecar = next((p for p in path.parent.iterdir() if p.name.lower() == path.name.lower() + '.lua'), None)
    return {'file': str(path.relative_to(GAME)), 'family': family, 'sha256': digest(path),
            'units': unit.attrib if unit is not None else None,
            'up_axis': tree.findtext('c:asset/c:up_axis', namespaces=NS),
            'node_count': len(records), 'duplicate_names': sorted(k for k, v in counts.items() if v > 1),
            'missing_core': sorted(set(core) - names), 'nodes': records,
            'sidecar': str(sidecar.relative_to(GAME)) if sidecar else None,
            'sidecar_sha256': digest(sidecar) if sidecar else None}

def main():
    global OUT
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=OUT, help='Fresh inventory directory; existing review records are never overwritten')
    OUT = parser.parse_args().output.resolve()
    if (OUT/'inventory.json').exists():
        raise SystemExit('Inventory already exists. Use --output with a fresh directory; never overwrite review records.')
    if OUT.exists() and any(OUT.iterdir()):
        raise SystemExit('Output must be a new or empty directory.')
    OUT.mkdir(parents=True, exist_ok=True)
    models = []
    for path in sorted((GAME / 'objects3d').iterdir()):
        lower = path.name.lower()
        if re.fullmatch(r'civilian\d+_(arab|western)\.dae', lower):
            models.append(rig(path, 'civilian'))
        elif lower in {'operative_asset.dae', 'operative_propagator.dae', 'operative_investigator.dae'}:
            models.append(rig(path, lower.removeprefix('operative_').removesuffix('.dae')))
    comparisons = []
    for family, candidates, core in [('civilian', [m for m in models if m['family'] == 'civilian'], CIV_CORE),
                                     ('operative', [m for m in models if m['family'] != 'civilian'], OP_CORE)]:
        baseline = candidates[0]
        base = {n['name']: n for n in baseline['nodes']}
        for model in candidates[1:]:
            nodes = {n['name']: n for n in model['nodes']}
            comparisons.append({'group': family, 'baseline': baseline['file'], 'model': model['file'],
                'missing_core': sorted(set(core)-set(nodes)),
                'different_core_parents': [k for k in core if k in base and k in nodes and base[k]['parent'] != nodes[k]['parent']],
                'different_core_authored_transforms': [k for k in core if k in base and k in nodes and base[k]['transforms'] != nodes[k]['transforms']],
                'extra_nodes': sorted(set(nodes)-set(base)), 'absent_nodes': sorted(set(base)-set(nodes)),
                'same_asset_units_and_up_axis': (baseline['units'], baseline['up_axis']) == (model['units'], model['up_axis'])})
    clips = []
    module_hashes = {}
    for family, (filename, registrations) in FAMILIES.items():
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute('x_axis=1; y_axis=2; z_axis=3; math.randomseed(1337)')
        path = GAME/'scripts'/filename
        table = lua.execute(path.read_text())
        module_hashes[filename] = digest(path)
        for filename2 in registrations:
            path2 = GAME/'scripts'/filename2
            lua.execute(path2.read_text()).register(table)
            module_hashes[filename2] = digest(path2)
        for name, frames in sorted(table.items()):
            pieces, commands, times, malformed = set(), 0, [], []
            for i in range(1, len(frames)+1):
                frame = frames[i]
                times.append(frame['time'])
                entries = frame['commands']
                if entries is None:
                    malformed.append(f'frame {i}: no commands')
                    continue
                for j in range(1, len(entries)+1):
                    cmd = entries[j]; commands += 1
                    if isinstance(cmd['p'], str): pieces.add(cmd['p'])
                    if cmd['c'] in ('turn', 'move') and cmd['t'] is None and (cmd['rl'] is None or cmd['ru'] is None):
                        malformed.append(f'frame {i} command {j}: no target or complete random range')
            missing = {}
            for model in models:
                if model['family'] == family:
                    absent = sorted(pieces - {n['name'] for n in model['nodes']})
                    if absent: missing[model['file']] = absent
            clips.append({'family': family, 'clip': name, 'source': filename, 'keyframes': len(frames),
                'commands': commands, 'last_time': max((t for t in times if t is not None), default=0),
                'pieces': sorted(pieces), 'authored_missing_targets': missing, 'command_warnings': malformed,
                'status': 'not_reviewed'})
    report = {'source': str(GAME), 'source_commit': subprocess.check_output(['git','-C',str(GAME),'rev-parse','HEAD'],text=True).strip(),
        'scope': 'Authored COLLADA node names, immediate parents and exact stored transforms; no Assimp normalization, pose evaluation, skin-weight or engine-piece validation.',
        'disabled_model': 'civilian_western6 is disabled in its unit definition; its model is absent. Keep excluded until restoration is explicitly authorized.',
        'models': models, 'comparisons': comparisons, 'animation_module_sha256': module_hashes, 'clips': clips}
    (OUT/'inventory.json').write_text(json.dumps(report, indent=2)+'\n')
    with (OUT/'clip-review.csv').open('w', newline='') as f:
        fields = ['family','clip','source','keyframes','commands','last_time','status','scenario','evidence','reviewer','decision']
        writer = csv.DictWriter(f, fieldnames=fields); writer.writeheader()
        for clip in clips: writer.writerow({k: clip.get(k, '') for k in fields})
    summary = {'models': len(models), 'civilian_models': sum(m['family']=='civilian' for m in models),
        'clips_by_family': dict(Counter(c['family'] for c in clips)),
        'models_with_missing_core': [m['file'] for m in models if m['missing_core']],
        'clips_with_authored_missing_targets': sum(bool(c['authored_missing_targets']) for c in clips),
        'clips_with_command_warnings': sum(bool(c['command_warnings']) for c in clips),
        'comparisons': [{k:v for k,v in c.items() if k not in ('extra_nodes','absent_nodes')} for c in comparisons]}
    (OUT/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
    print(json.dumps(summary,indent=2))

if __name__ == '__main__': main()
