#!/usr/bin/env python3
"""Check the 24-float export, runtime catalog and full animated bounds.

NumPy and Lua are required. When installed, assimp_py additionally verifies
that the native importer exposes the same named geometry pieces.
"""
from pathlib import Path
import argparse
import importlib.util
import shutil
import sys
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools/truck_parade_payloads'))
from audit_export import audit, read_catalog, MODEL


def rotation(axis, radians):
    axis = axis / np.linalg.norm(axis)
    x, y, z = axis
    cross = np.array([[0, -z, y], [z, 0, -x], [-y, x, 0]])
    return np.eye(3) * np.cos(radians) + (1 - np.cos(radians)) * np.outer(axis, axis) + np.sin(radians) * cross


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--lua', default=shutil.which('lua'))
    args = parser.parse_args()
    pieces, transforms = audit(args.lua)
    variants, mounts, _ = read_catalog(args.lua)
    # Independently exercise the authored local rotation axes at both sway
    # extrema and around a whole rotor revolution, in world/model coordinates.
    import json
    bounds = json.loads((ROOT / 'tools/truck_parade_payloads/manifest.json').read_text())['culling']
    for variant in variants:
        for motion in variant['motion']:
            name = motion['piece']
            pivot = transforms[name][:3, 3]
            axis = transforms[name][:3, 'xyz'.index(motion['axis'])]
            if name == 'Float2Sub1':
                assert abs(axis[1]) / np.linalg.norm(axis) > .999, 'Flag should rock around its upright pole'
            elif name != 'Float3Sub1':
                assert abs(axis[1]) / np.linalg.norm(axis) < .001, 'Pendulum/rotor axis must be horizontal'
            angles = range(0, 361, 15) if motion['spin'] else [-motion['angle'], 0, motion['angle']]
            for degrees in angles:
                posed = (pieces[name][:, :3] - pivot) @ rotation(axis, np.radians(degrees)).T + pivot
                for offset in mounts:
                    assert np.linalg.norm(posed + offset - bounds['midpos'], axis=1).max() < bounds['radius']
                    assert (posed + offset)[:, 1].max() < bounds['height']
    print('PASS: flag pole, hanging-piece axes and all sampled animation poses fit culling bounds')
    if importlib.util.find_spec('assimp_py') is None:
        print('SKIP: native Assimp import (assimp_py is not installed); source COLLADA checks passed')
    else:
        import assimp_py
        scene = assimp_py.import_file(str(MODEL), assimp_py.Process_Triangulate | assimp_py.Process_ValidateDataStructure)
        imported = set()
        def visit(node):
            if len(node.mesh_indices): imported.add(node.name)
            for child in node.children: visit(child)
        visit(scene.root_node)
        assert imported == set(pieces)
        print('PASS: native Assimp piece import')


if __name__ == '__main__':
    main()
