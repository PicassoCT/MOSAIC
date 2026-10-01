"""Validate exported models with Assimp (the engine importer family) and NumPy."""
import json
import sys
from pathlib import Path
import assimp_py
import numpy as np

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools/civic_objectives'))
from generate import ATLAS
from render import load_geometry

for spec in json.loads((ROOT/'tools/civic_objectives/manifest.json').read_text()):
    path=ROOT/'objects3d'/(spec['name']+'.dae')
    scene=assimp_py.import_file(str(path),assimp_py.Process_Triangulate|assimp_py.Process_ValidateDataStructure|assimp_py.Process_CalcTangentSpace|assimp_py.Process_JoinIdenticalVertices)
    assert scene.num_meshes==4
    assert sum(m.num_faces for m in scene.meshes)==spec['triangles']
    assert all(m.normals is not None and m.texcoords is not None and m.tangents is not None for m in scene.meshes)
    names=[]
    def walk(node):
        names.append(node.name)
        for child in node.children: walk(child)
    walk(scene.root_node)
    assert all(p in names for p in spec['pieces'])
    vertices=load_geometry(path)
    assert np.isfinite(vertices).all()
    assert np.allclose(vertices[:,:3].min(0),spec['bounds'][0],atol=1e-4)
    assert np.allclose(vertices[:,:3].max(0),spec['bounds'][1],atol=1e-4)
    assert np.allclose(np.linalg.norm(vertices[:,3:6],axis=1),1,atol=1e-5)
    tri=vertices.reshape(-1,3,8)
    cross=np.cross(tri[:,1,:3]-tri[:,0,:3],tri[:,2,:3]-tri[:,0,:3])
    area=np.linalg.norm(cross,axis=1)
    assert (area>1e-5).all()
    assert ((cross*tri[:,0,3:6]).sum(1)/area>.999).all(), 'normal/winding mismatch'
    # Every triangle belongs wholly to one approved atlas island.
    contained=np.zeros(len(tri),dtype=bool)
    for u0,v0,u1,v1 in ATLAS.values():
        uv=tri[:,:,6:8]
        contained|=((uv[:,:,0]>=u0-1e-5)&(uv[:,:,0]<=u1+1e-5)&(uv[:,:,1]>=1-v1-1e-5)&(uv[:,:,1]<=1-v0+1e-5)).all(1)
    assert contained.all(), 'UV outside its atlas island'
    assert vertices[:,1].min()>=0 and vertices[:,1].max()<=spec['height']
    assert np.abs(vertices[:,[0,2]]).max()<=64, 'geometry spills beyond 8x8 footprint'
    assert spec['triangles']<=4000
    print(spec['name'],spec['triangles'],'triangles: Assimp, UVs, normals, bounds PASS')
