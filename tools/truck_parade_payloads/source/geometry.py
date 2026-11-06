"""Geometry proofs for the connected spline control nets; no scene conversion."""
from __future__ import annotations
from collections import Counter
import numpy as np
from authoring import frame_path, unit


def triangulate(faces):
    return np.array([[f[0],f[j],f[j+1]] for f in faces for j in range(1,len(f)-1)],dtype=int)


def shell(vertices, faces, thickness):
    v=np.array(vertices,dtype=float)
    tris=triangulate(faces)
    normals=np.zeros_like(v)
    for a,b,c in tris:
        n=np.cross(v[b]-v[a],v[c]-v[a])
        for i in (a,b,c): normals[i]+=n
    lengths=np.linalg.norm(normals,axis=1)
    if np.any(lengths<1e-9):
        raise ValueError('Undefined shell normal')
    normals/=lengths[:,None]
    edges=Counter(tuple(sorted((a,b))) for f in faces for a,b in zip(f,f[1:]+f[:1]))
    count=len(v)
    out_faces=[list(f) for f in faces]+[[i+count for i in reversed(f)] for f in faces]
    for f in faces:
        for a,b in zip(f,f[1:]+f[:1]):
            if edges[tuple(sorted((a,b)))]==1:
                out_faces.append([b,a,a+count,b+count])
    return np.vstack((v+normals*thickness/2,v-normals*thickness/2)),out_faces


def sample_curve(points, closed=False, smooth=True, steps=2):
    p=np.array(points,dtype=float)
    if not smooth or steps==0:
        return p
    handles=[]
    for i,point in enumerate(p):
        if closed:
            tangent=(p[(i+1)%len(p)]-p[(i-1)%len(p)])/6
        elif i==0: tangent=(p[1]-point)/3
        elif i==len(p)-1: tangent=(point-p[i-1])/3
        else: tangent=(p[i+1]-p[i-1])/6
        handles.append(tangent)
    out=[]
    for i in range(len(p) if closed else len(p)-1):
        j=(i+1)%len(p)
        a,b,c,d=p[i],p[i]+handles[i],p[j]-handles[j],p[j]
        for t in np.arange(steps+1)/(steps+1):
            out.append(a*(1-t)**3+3*b*(1-t)**2*t+3*c*(1-t)*t*t+d*t**3)
    if not closed: out.append(p[-1])
    return np.array(out)


def tube_mesh(part):
    p=sample_curve(part['points'],part['closed'],part['smooth'],2)
    sides=part['sides']; radius=part['radius']
    if part['closed']:
        p=np.vstack((p,p[0]))
    frames=frame_path(p)
    rings=[]
    for pt,(u,w) in zip(p,frames):
        rings.append([pt+radius*(np.cos(t)*u+np.sin(t)*w) for t in np.arange(sides)*2*np.pi/sides])
    if part['closed']:
        rings=rings[:-1]
    v=np.array(rings).reshape(-1,3)
    count=len(rings)
    faces=[]
    for i in range(count if part['closed'] else count-1):
        k=(i+1)%count
        faces.extend([[i*sides+j,i*sides+(j+1)%sides,k*sides+(j+1)%sides,k*sides+j] for j in range(sides)])
    if not part['closed']:
        # Real caps; the source remains Renderable Spline in the Max output.
        faces.extend([list(reversed(range(sides))),list(range((count-1)*sides,count*sides))])
    return v,faces


def evaluate(part):
    if part['kind']=='tube':
        return tube_mesh(part)
    v=np.array(part['vertices'],dtype=float)
    faces=part['faces']
    if part['thickness']>0:
        return shell(v,faces,part['thickness'])
    return v,faces


def scene_triangles(model,palette):
    triangles=[]; colors=[]; emissions=[]
    for part in model['parts']:
        v,f=evaluate(part)
        t=v[triangulate(f)]
        material=palette['patches'][part['material']]
        triangles.append(t)
        colors.extend([np.array(material['preview_rgb'])/255]*len(t))
        emissions.extend([material['emission_R_mean']/255]*len(t))
    triangles=np.concatenate(triangles)
    normals=np.cross(triangles[:,1]-triangles[:,0],triangles[:,2]-triangles[:,0])
    lengths=np.linalg.norm(normals,axis=1)
    valid=lengths>1e-8
    return triangles[valid],np.array(colors)[valid],np.array(emissions)[valid],normals[valid]/lengths[valid,None]
