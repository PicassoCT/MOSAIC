#!/usr/bin/env python3
"""Check topology, source/export parity, atlas use, transforms and native import."""
from pathlib import Path
from collections import Counter
import sys,json,hashlib,re
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/parade_holograms'))
sys.path.insert(0,str(ROOT/'tools/truck_parade_payloads/source'))
from render_preview import load_export,NS
from geometry import evaluate,triangulate
from cage_surface import ROTATION
HERE=Path(__file__).resolve().parent


def main():
    model=json.loads((HERE/'source.json').read_text());manifest=json.loads((HERE/'manifest.json').read_text())
    assert hashlib.sha256((HERE/'source.json').read_bytes()).hexdigest()==manifest['source_sha256']
    document,nodes,pieces=load_export(ROOT/'objects3d/paradeSaintMother.dae')
    assert list(nodes)==['paradesaintmother'] and list(pieces)==['paradesaintmother']
    assert len(document.findall('c:library_materials/c:material',NS))==1
    matrix=np.fromstring(nodes['paradesaintmother'].findtext('c:matrix',namespaces=NS),sep=' ').reshape(4,4)
    assert np.array_equal(matrix,np.eye(4)), 'Malformed nonidentity node transform'
    assert document.find('c:asset/c:unit',NS).get('meter')=='1'
    piece=pieces['paradesaintmother'];expected=[]
    for part in model['parts']:
        assert part['kind']=='cage' and part['closed'] and part['thickness']==0
        verts,faces=evaluate(part)
        edges=Counter(tuple(sorted((a,b))) for f in faces for a,b in zip(f,f[1:]+f[:1]))
        assert set(edges.values())=={2},part['name']+': open/nonmanifold control cage'
        curves={tuple(np.round(p,6)) for c in part['curves'] for p in c['points']}
        assert {tuple(np.round(p,6)) for p in verts} <= curves,part['name']+': polygon without editable knot'
        tris=verts[triangulate(faces)]
        volume=np.einsum('ij,ij->i',tris[:,0],np.cross(tris[:,1],tris[:,2])).sum()/6
        assert volume>0,part['name']+': mirrored/inverted cage'
        expected.append(tris@ROTATION.T)
    expected=np.concatenate(expected)
    assert np.allclose(expected,piece.positions,atol=1e-6),'Source/export geometry mismatch'
    assert len(expected)==manifest['triangles']<=5000
    cross=np.cross(piece.positions[:,1]-piece.positions[:,0],piece.positions[:,2]-piece.positions[:,0])
    lengths=np.linalg.norm(cross,axis=1)
    assert lengths.min()>1e-9
    assert np.allclose(cross/lengths[:,None],piece.normals[:,0],atol=1e-5)
    assert np.isfinite(piece.positions).all() and np.isfinite(piece.uvs).all()
    pal=json.loads((HERE/'palette.json').read_text())
    mask=np.asarray(Image.open(ROOT/'unittextures/house_asian_selfilu_reflection.png').convert('RGBA'))
    diffuse=np.asarray(Image.open(ROOT/'unittextures/house_asian_diffuse.dds').convert('RGBA'))
    for row in manifest['parts']:
        start=row['first_triangle'];uv=piece.uvs[start:start+row['triangles']]
        u0,v0,u1,v1=pal[row['material']]['uv_rect']
        assert uv[:,:,0].min()>=u0-1e-7 and uv[:,:,0].max()<=u1+1e-7
        assert uv[:,:,1].min()>=v0-1e-7 and uv[:,:,1].max()<=v1+1e-7
        assert np.ptp(uv[:,:,1])>1e-5,row['name']+': collapsed gradient'
        # Every possible sampled texel of the chosen rectangle is emissive,
        # opaque and has no unwanted team-colour mask, including edge pixels.
        a,b,c,d=manifest['atlas_rectangles_pixels'][row['material']]
        patch=mask[b:d+1,a:c+1];colour=diffuse[b:d+1,a:c+1]
        assert patch[:,:,0].min()>=245 and patch[:,:,3].min()==255
        assert colour[:,:,3].max()<=12
    script=(HERE/'Build_Saint.ms').read_text(encoding='utf-8-sig')
    # Check emitted mesh buffers independently of the writer.
    def triples(name,following):
        text=script.split('local '+name+' = ',1)[1].split('local '+following+' = ',1)[0]
        return np.asarray([[float(v) for v in match.split(',')] for match in re.findall(r'\[([^\]]+)\]',text)])
    v=triples('saintVerts','saintFaces');f=triples('saintFaces','saintUV').astype(int)-1;uv=triples('saintUV','saintCurves')
    assert np.allclose(v[f]@ROTATION.T,piece.positions,atol=1e-6)
    assert np.allclose(uv[:,:2].reshape(-1,3,2),piece.uvs,atol=1e-7)
    assert 'resetMaxFile' not in script and 'delete objects' not in script
    assert script.count('obj = mesh name:')==1 and script.count('obj = splineShape name:')==1
    print('PASS: one identity-transform mesh/material; all closed source cages have positive volume and editable knots')
    print('PASS: exported positions/normals match source cages; exact Max mesh/UV parity; illuminated atlas gradients verified')
    import assimp_py
    scene=assimp_py.import_file(str(ROOT/'objects3d/paradeSaintMother.dae'),assimp_py.Process_Triangulate|assimp_py.Process_ValidateDataStructure)
    assert len(scene.meshes)==1
    assert scene.meshes[0].num_faces==manifest['triangles']
    print('PASS: native Assimp import; %s triangles'%manifest['triangles'])
    print('NOT RUN: 3ds Max 2018 script execution and in-engine visual inspection')

if __name__=='__main__':main()
