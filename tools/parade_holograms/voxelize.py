"""Sample authored cage volumes and emit only exposed, merged pixel faces.

This is a deterministic game-mesh evaluator. Native editable spline cages are
retained separately; neither this module nor the MAXScript collapses them.
"""
from __future__ import annotations
from collections import defaultdict
from functools import lru_cache
import math
import numpy as np
from scipy.ndimage import binary_fill_holes
from geometry import evaluate, triangulate


# A proper rotation, preserving triangle winding: source Z-up -> game Y-up.
ROTATION = np.array(((1,0,0),(0,0,1),(0,-1,0)), dtype=float)


@lru_cache(maxsize=128)
def barycentric_samples(n):
    return np.array([(i/n,j/n,1-(i+j)/n)
                     for i in range(n+1) for j in range(n-i+1)])


def part_cells(part, cell):
    vertices, polygons = evaluate(part)
    triangles = np.asarray(vertices)[triangulate(polygons)]
    lo = np.floor(np.min(vertices,axis=0)/cell).astype(int)-1
    hi = np.floor(np.max(vertices,axis=0)/cell).astype(int)+1
    shape = hi-lo+1
    if np.prod(shape)>4_000_000:
        raise ValueError("Unbounded cage voxelization: "+part['name'])
    volume=np.zeros(shape,dtype=bool)
    # Oversampling gives a six-connected closed digital boundary, including
    # thin patches and ribs whose exact volume is smaller than one pixel.
    for triangle in triangles:
        length=max(np.linalg.norm(triangle[(j+1)%3]-triangle[j]) for j in range(3))
        samples=max(2,int(math.ceil(length/cell*2.5)))
        if samples>256:
            raise ValueError("Cage edge is too long for the selected pixel size")
        points=barycentric_samples(samples) @ triangle
        indices=np.floor(points/cell+1e-7).astype(int)-lo
        indices=np.clip(indices,0,shape-1)
        volume[indices[:,0],indices[:,1],indices[:,2]]=True
    volume=binary_fill_holes(volume)
    return [tuple(map(int,p+lo)) for p in np.argwhere(volume)]


def model_cells(model):
    groups=defaultdict(dict)
    for part in model['parts']:
        role=part.get('group') or 'prop'
        for cell in part_cells(part,model['cell_size']):
            # Later trim, faceplates and eye apertures replace the underlying
            # material at the same pixel, without coincident surface faces.
            groups[role][cell]=part['material']
    # Body, head and faceplate remain separately addressable native pieces,
    # but one spatial pixel has exactly one owner. Without this pass a thin
    # faceplate and the front of its head can quantize to the same outward
    # plane, producing depth fighting in importers and mesh previews.
    if model['category']!='prop':
        occupied=set()
        for role in ('mask','head','body'):
            cells=groups[role]
            for cell in occupied.intersection(cells):del cells[cell]
            occupied.update(cells)
    return dict(groups)


def rectangles(cells):
    remaining=set(cells)
    while remaining:
        u,v=min(remaining,key=lambda p:(p[1],p[0]))
        width=1
        while (u+width,v) in remaining: width+=1
        height=1
        while all((x,v+height) in remaining for x in range(u,u+width)): height+=1
        for y in range(v,v+height):
            for x in range(u,u+width): remaining.remove((x,y))
        yield u,v,width,height


def mesh(cells, size, palette):
    # For each signed axis, merge coplanar adjacent cells of the SAME material.
    # The silhouette retains every pixel step, while internal and redundant
    # faces never reach the engine.
    planes=defaultdict(set)
    for p,material in cells.items():
        for axis in range(3):
            others=[i for i in range(3) if i!=axis]
            for sign in (-1,1):
                neighbour=list(p);neighbour[axis]+=sign
                if tuple(neighbour) in cells: continue
                plane=p[axis]+(1 if sign>0 else 0)
                planes[(axis,sign,plane,material)].add((p[others[0]],p[others[1]]))
    records=[]; indices=[]; lookup={}; material_counts=defaultdict(int)
    for (axis,sign,plane,material),face_cells in sorted(planes.items()):
        other=[i for i in range(3) if i!=axis]
        uv0,uv1,uv2,uv3=palette['patches'][material]['uv_rect']
        uv=((uv0,uv1),(uv2,uv1),(uv2,uv3),(uv0,uv3))
        for a,b,w,h in rectangles(face_cells):
            pts=[]
            for u,v in ((a,b),(a+w,b),(a+w,b+h),(a,b+h)):
                point=np.zeros(3);point[axis]=plane;point[other]=[u,v]
                pts.append(point*size)
            normal=np.cross(pts[1]-pts[0],pts[2]-pts[0])
            if normal[axis]*sign<0: pts=list(reversed(pts))
            pts=np.array(pts) @ ROTATION.T
            normal=np.zeros(3);normal[axis]=sign;normal=normal @ ROTATION.T
            quad=[]
            for p,t in zip(pts,uv):
                record=tuple(round(float(x),7) for x in (*p,*normal,*t))
                if record not in lookup:
                    lookup[record]=len(records);records.append(record)
                quad.append(lookup[record])
            indices.extend((quad[0],quad[1],quad[2],quad[0],quad[2],quad[3]))
            material_counts[material]+=2
    if not records:
        raise ValueError('Empty pixel geometry')
    return {'records':records,'indices':indices,'voxel_count':len(cells),
            'materials':dict(material_counts)}
