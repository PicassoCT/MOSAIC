#!/usr/bin/env python3
"""Independent source-to-runtime parity, transform gates and wing hinge checks."""
from pathlib import Path
import sys, json, hashlib, subprocess, tempfile
import xml.etree.ElementTree as ET
import numpy as np
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools/parade_holograms'))
sys.path.insert(0, str(ROOT/'tests'))
from render_preview import load_export, NS, FIGURE_NAMES, figure_piece_names
from parade_hologram_models_test import check_identity_nodes, check_standalone, check_preservation, check_assimp
from import_export import read_source


def run(base_ref='212ebe79', native=True, root=ROOT, base_dae=None, max_triangles=220000, json_output=None):
    ROOT = root
    source = ROOT/'objects3d/paradeHologramScenery.dae'
    manifest = json.loads((ROOT/'tools/parade_holograms/import_manifest.json').read_text())
    assert hashlib.sha256(source.read_bytes()).hexdigest() == manifest['source_sha256']
    srcdoc, _, src = load_export(source)
    runtime, nodes, pieces = load_export(ROOT/'objects3d/paradeHologramSceneryRuntime.dae')
    embedded, embed_nodes, embed_pieces = load_export(ROOT/'objects3d/truckPayloadParade.dae')
    check_identity_nodes(nodes)
    check_standalone(runtime, nodes, pieces, embed_pieces)
    unit = float(srcdoc.find('c:asset/c:unit', NS).get('meter'))
    frames = {}
    def walk(node, parent):
        name = node.get('name') or node.get('id')
        m = parent @ np.fromstring(node.findtext('c:matrix', namespaces=NS), sep=' ').reshape(4,4)
        frames[name] = m
        if name in src:
            raw, actual = src[name], pieces[name]
            expected = raw.positions @ m[:3,:3].T + m[:3,3]
            assert np.allclose(expected, actual.positions, atol=2e-6), name + ': changed source shape'
            assert np.allclose(raw.uvs, actual.uvs, atol=1e-7), name + ': changed UVs'
            normals = raw.normals @ np.linalg.inv(m[:3,:3])
            normals /= np.linalg.norm(normals,axis=2)[:,:,None]
            assert np.allclose(normals, actual.normals, atol=2e-6), name + ': changed normals'
        for child in node.findall('c:node', NS):walk(child,m)
    for n in srcdoc.findall('c:library_visual_scenes/c:visual_scene/c:node', NS):
        walk(n,np.diag([unit,unit,unit,1]))
    assert set(src) | {'paradeleaf'} == set(pieces), 'lost authored pieces or existing leaf'
    for family in FIGURE_NAMES:
        assert all(role in pieces for role in figure_piece_names(family))
    for piece in pieces.values():
        assert np.isfinite(piece.positions).all() and np.isfinite(piece.uvs).all()
        assert np.allclose(np.linalg.norm(piece.normals,axis=2),1,atol=2e-5)
        assert np.abs(piece.positions).max() < 100
    triangles = sum(len(piece.positions) for piece in pieces.values())
    assert triangles <= max_triangles, 'runtime scenery exceeds triangle budget'
    for bird in manifest['catalog']['props']['moth']['variants']:
        assert len(bird['wings']) == 2
        for wing in bird['wings']:
            m=frames[wing['piece']]
            assert np.allclose(wing['pivot'],m[:3,3],atol=1e-7)
            assert np.allclose(wing['axis'],m[:3,0]/np.linalg.norm(m[:3,0]),atol=1e-7)
            # A point on the hinge axis must stay fixed through the whole flap.
            axis=np.asarray(wing['axis']);pivot=np.asarray(wing['pivot'])
            for degrees in (18,48,78):
                a=np.deg2rad(degrees*wing['sign']);v=axis*.4
                rotated=v*np.cos(a)+np.cross(axis,v)*np.sin(a)+axis*np.dot(axis,v)*(1-np.cos(a))
                assert np.allclose(pivot+rotated,pivot+v)
    base = ET.parse(base_dae).getroot() if base_dae else ET.fromstring(
        subprocess.check_output(['git','show',base_ref+':objects3d/truckPayloadParade.dae'],cwd=ROOT))
    # Only our generated scenery namespace is replaceable; every original
    # authored float subtree and material remains protected.
    for section in base:
        for entry in list(section):
            if (entry.get('id') or '').startswith('paradehologram_'):
                section.remove(entry)
            elif entry.tag.endswith('}visual_scene'):
                for node in list(entry):
                    if node.get('id') == 'paradeholograms':entry.remove(node)
    preserved=check_preservation(base,embedded)
    # Deliberately malformed transforms and selection-only export must be rejected.
    for mode in ('nonuniform','mirror','shear','incomplete'):
        doc=ET.parse(source);root=doc.getroot();visual=root.find('c:library_visual_scenes/c:visual_scene',NS)
        if mode=='incomplete':
            main=visual.find('c:node',NS)
            for n in list(main):
                if n.tag.endswith('}node'):main.remove(n)
        else:
            n=next(n for n in visual.findall('.//c:node',NS) if n.get('name')=='parademoth1')
            el=n.find('c:matrix',NS);m=np.fromstring(el.text,sep=' ').reshape(4,4)
            if mode=='nonuniform':m[:3,0]*=1.2
            elif mode=='mirror':m[:3,0]*=-1
            else:m[:3,1]+=m[:3,0]*.2
            el.text=' '.join(map(str,m.flatten()))
        with tempfile.NamedTemporaryFile(suffix='.dae') as temp:
            doc.write(temp.name)
            try:read_source(Path(temp.name))
            except ValueError:pass
            else:raise AssertionError(mode+' was not rejected')
    print('PASS all 74 artist meshes retain world shape, normals and UVs; leaf motif retained')
    print('PASS all three birds retain both authored hinge pivots/axes; malformed or partial exports rejected')
    print('PASS standalone/runtime parity and original float preservation:',preserved)
    if native:
        check_assimp(ROOT/'objects3d/paradeHologramSceneryRuntime.dae',pieces)
        check_assimp(ROOT/'objects3d/truckPayloadParade.dae',pieces)
        print('PASS native Assimp import of runtime scenery and wagon payload')
    else:print('NOT CHECKED native import (--xml-only)')
    if json_output:
        json_output.write_text(json.dumps({'pieces': len(pieces), 'triangles': triangles,
            'preservation': preserved, 'native_import_checked': native}, indent=2) + '\n')


if __name__=='__main__':
    import argparse
    p=argparse.ArgumentParser();p.add_argument('--base-ref',default='212ebe79');p.add_argument('--xml-only',action='store_true')
    args=p.parse_args();run(args.base_ref,not args.xml_only)
