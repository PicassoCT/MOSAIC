"""Low-poly surfaces evaluated directly from editable cages, with atlas gradients."""
from collections import defaultdict
import numpy as np
from geometry import evaluate, triangulate
ROTATION=np.array(((1,0,0),(0,0,1),(0,-1,0)),dtype=float)
def model_cells(model):
    groups=defaultdict(list)
    for part in model['parts']: groups[part.get('group') or 'prop'].append(part)
    return groups

def mesh(parts, unused_size, palette):
    records=[];indices=[];counts=defaultdict(int)
    for part in parts:
        vertices,faces=evaluate(part)
        vertices=np.asarray(vertices)@ROTATION.T
        triangles=triangulate(faces)
        lo=vertices.min(0);span=np.maximum(np.ptp(vertices,axis=0),1e-8)
        u0,v0,u1,v1=palette['patches'][part['material']]['uv_rect']
        for tri in triangles:
            xyz=vertices[tri];normal=np.cross(xyz[1]-xyz[0],xyz[2]-xyz[0]);length=np.linalg.norm(normal)
            if length<1e-10:continue
            normal/=length
            # Project onto the best face plane. Continuous coordinates across
            # each cage span the full luminous gradient, never a constant UV.
            axes=sorted(np.argsort(abs(normal))[:2])
            # Prefer vertical progression through the horizontal atlas ramp.
            if 1 in axes: axes=[1,axes[0] if axes[1]==1 else axes[1]]
            uv=(xyz[:,axes]-lo[axes])/span[axes]
            uv=uv*np.array([u1-u0,v1-v0])+[u0,v0]
            for p,t in zip(xyz,uv):
                indices.append(len(records));records.append(tuple(p)+tuple(normal)+tuple(t))
            counts[part['material']]+=1
    return dict(records=records,indices=indices,voxel_count=0,materials=dict(counts))
