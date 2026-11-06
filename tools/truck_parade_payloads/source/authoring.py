"""Deterministic spline-cage authoring data for native 3ds Max Surface modifiers.

The polygon data is a control-net proxy used for topology checks and previews.
It is never imported as scene geometry; MAXScript creates the connected splines.
"""
from __future__ import annotations

import json
import math
from pathlib import Path
import numpy as np


def vec(p):
    return np.asarray(p, dtype=float)


def unit(p):
    p = vec(p)
    n = np.linalg.norm(p)
    if n < 1e-9:
        raise ValueError("Cannot normalize a zero-length vector")
    return p / n


def rotation_matrix(rotation):
    a, b, c = np.radians(rotation)
    rx = np.array([[1, 0, 0], [0, math.cos(a), -math.sin(a)], [0, math.sin(a), math.cos(a)]])
    ry = np.array([[math.cos(b), 0, math.sin(b)], [0, 1, 0], [-math.sin(b), 0, math.cos(b)]])
    rz = np.array([[math.cos(c), -math.sin(c), 0], [math.sin(c), math.cos(c), 0], [0, 0, 1]])
    return rz @ ry @ rx


def points_list(points):
    return [[round(float(x), 6) for x in p] for p in points]


def curve(points, closed=False, smooth=True):
    return {"points": points_list(points), "closed": bool(closed), "smooth": bool(smooth)}


def frame_path(points):
    """Minimal-twist frames; reject an exact reversal instead of creating NaNs."""
    p = np.array(points, dtype=float)
    dirs = [unit(p[i + 1] - p[i]) for i in range(len(p) - 1)]
    tangents = [dirs[0]]
    for a, b in zip(dirs, dirs[1:]):
        t = a + b
        tangents.append(unit(t) if np.linalg.norm(t) > 1e-7 else b)
    tangents.append(dirs[-1])
    helper = vec((0, 0, 1)) if abs(tangents[0][2]) < 0.9 else vec((0, 1, 0))
    u = unit(np.cross(tangents[0], helper))
    frames = []
    previous_t = tangents[0]
    for t in tangents:
        cross = np.cross(previous_t, t)
        sn = np.linalg.norm(cross)
        cs = float(np.dot(previous_t, t))
        if sn > 1e-9:
            axis = cross / sn
            u = u * cs + np.cross(axis, u) * sn + axis * np.dot(axis, u) * (1 - cs)
        u = unit(u - t * np.dot(u, t))
        v = unit(np.cross(t, u))
        frames.append((u, v))
        previous_t = t
    return frames


class Recipe:
    def __init__(self, index, slug, title):
        self.index = int(index)
        self.slug = str(slug)
        self.title = str(title)
        self.parts = []
        self.groups = []
        self.notes = []
        self._names = set()

    def _add(self, name, material, group, **data):
        if name in self._names:
            raise ValueError(f"Duplicate part name in {self.slug}: {name}")
        if not name or any(c not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_" for c in name):
            raise ValueError(f"Use simple stable ASCII part names: {name!r}")
        self._names.add(name)
        part = {"name": name, "material": material, "group": group, **data}
        self.parts.append(part)
        return part

    def _cage(self, name, material, group, vertices, faces, curves, closed=True, thickness=0.0):
        return self._add(name, material, group, kind="cage", vertices=points_list(vertices),
                         faces=[list(f) for f in faces], curves=curves,
                         closed=closed, thickness=float(thickness))

    def box(self, name, center, size, material, rotation=(0, 0, 0), group=None):
        sx, sy, sz = vec(size) / 2
        if min(sx, sy, sz) <= 0:
            raise ValueError(f"Nonpositive box extent: {name}")
        vertices = [[-sx,-sy,-sz],[sx,-sy,-sz],[sx,sy,-sz],[-sx,sy,-sz],
                    [-sx,-sy,sz],[sx,-sy,sz],[sx,sy,sz],[-sx,sy,sz]]
        vertices = np.array(vertices) @ rotation_matrix(rotation).T + vec(center)
        paths = [curve(vertices[:4], True, False), curve(vertices[4:], True, False)]
        paths += [curve([vertices[i],vertices[i+4]], False, False) for i in range(4)]
        faces = [[3,2,1,0],[4,5,6,7],[0,1,5,4],[1,2,6,5],[2,3,7,6],[3,0,4,7]]
        return self._cage(name, material, group, vertices, faces, paths)

    def _section_cage(self, name, ring_points, centers, material, group=None, smooth=True):
        # A section is either a ring of >=6 knots or one true pole. Every rail
        # reuses the same ring-knot coordinates, giving a connected patch lattice.
        sizes = [len(r) for r in ring_points if len(r) > 1]
        if not sizes or len(set(sizes)) != 1 or sizes[0] < 6:
            raise ValueError(f"Inconsistent section rings: {name}")
        sides = sizes[0]
        if any(len(r) == 1 for r in ring_points[1:-1]):
            raise ValueError(f"Interior pole would pinch the surface: {name}")
        rings = list(ring_points)
        if len(rings[0]) > 1:
            rings.insert(0, [vec(centers[0])])
        if len(rings[-1]) > 1:
            rings.append([vec(centers[-1])])
        vertices, ids = [], []
        for r in rings:
            ids.append(list(range(len(vertices), len(vertices) + len(r))))
            vertices.extend(r)
        curves = [curve(r, True, smooth) for r in rings if len(r) > 1]
        for j in range(sides):
            curves.append(curve([r[0] if len(r)==1 else r[j] for r in rings], False, smooth))
        faces = []
        for a,b in zip(ids,ids[1:]):
            if len(a) == 1:
                faces.extend([[a[0],b[(j+1)%sides],b[j]] for j in range(sides)])
            elif len(b) == 1:
                faces.extend([[b[0],a[j],a[(j+1)%sides]] for j in range(sides)])
            else:
                faces.extend([[a[j],a[(j+1)%sides],b[(j+1)%sides],b[j]] for j in range(sides)])
        return self._cage(name, material, group, vertices, faces, curves)

    def loft(self, name, sections, material, sides=12, group=None):
        sections = np.asarray(sections, dtype=float)
        if sections.ndim != 2 or sections.shape[1] != 5 or len(sections) < 2:
            raise ValueError(f"Loft requires [x,y,z,ry,rz] sections: {name}")
        rings = []
        for x,y,z,ry,rz in sections:
            if ry == 0 and rz == 0:
                rings.append([vec((x,y,z))])
            elif min(ry,rz) <= 0:
                raise ValueError(f"Loft radius must be positive or a true pole: {name}")
            else:
                rings.append([vec((x,y+ry*math.cos(t),z+rz*math.sin(t)))
                              for t in np.arange(sides)*2*math.pi/sides])
        return self._section_cage(name,rings,sections[:,:3],material,group)

    def ellipsoid(self, name, center, radii, material, rings=7, sides=12,
                  rotation=(0,0,0), group=None):
        if min(radii) <= 0 or rings < 4:
            raise ValueError(f"Invalid ellipsoid: {name}")
        rx,ry,rz = radii
        secs = []
        for i,a in enumerate(np.linspace(-math.pi/2,math.pi/2,rings)):
            if i in (0,rings-1):
                secs.append([rx*math.sin(a),0,0,0,0])
            else:
                secs.append([rx*math.sin(a),0,0,ry*math.cos(a),rz*math.cos(a)])
        part = self.loft(name,secs,material,sides,group)
        rot,offset = rotation_matrix(rotation),vec(center)
        part['vertices'] = points_list(np.array(part['vertices']) @ rot.T + offset)
        for c in part['curves']:
            c['points'] = points_list(np.array(c['points']) @ rot.T + offset)
        return part

    def sweep(self, name, points, radii, material, sides=8, group=None):
        points = np.asarray(points,dtype=float)
        if np.isscalar(radii):
            radii = [float(radii)] * len(points)
        if len(points) != len(radii) or len(points) < 2:
            raise ValueError(f"Sweep path/radii mismatch: {name}")
        rings = []
        for p,r,(u,v) in zip(points,radii,frame_path(points)):
            if r == 0:
                rings.append([p])
            elif r < 0:
                raise ValueError(f"Negative sweep radius: {name}")
            else:
                rings.append([p+r*(math.cos(t)*u+math.sin(t)*v)
                              for t in np.arange(sides)*2*math.pi/sides])
        return self._section_cage(name,rings,points,material,group)

    def cylinder(self, name, a, b, radius, material, sides=8, group=None):
        # Mid-section gives a readable cage; corner knots keep the cylinder caps flat.
        points = [vec(a), (vec(a)+vec(b))/2, vec(b)]
        frames = frame_path(points)
        rings = [[p+radius*(math.cos(t)*u+math.sin(t)*v)
                  for t in np.arange(sides)*2*math.pi/sides]
                 for p,(u,v) in zip(points,frames)]
        return self._section_cage(name,rings,points,material,group,smooth=False)

    def patch(self, name, grid, material, thickness=0.8, smooth=True, group=None):
        grid = np.asarray(grid,dtype=float)
        if grid.ndim != 3 or grid.shape[0] < 3 or grid.shape[1] < 3 or grid.shape[2] != 3:
            raise ValueError(f"Patch requires a rectangular >=3x3 point lattice: {name}")
        h,w,_ = grid.shape
        vertices = grid.reshape(-1,3)
        paths = [curve(row,False,smooth) for row in grid]
        paths += [curve(grid[:,j],False,smooth) for j in range(w)]
        faces = [[i*w+j,i*w+j+1,(i+1)*w+j+1,(i+1)*w+j]
                 for i in range(h-1) for j in range(w-1)]
        return self._cage(name,material,group,vertices,faces,paths,
                          closed=False,thickness=thickness)

    def leaf(self, name, base, tip, width, material, width_axis=(0,1,0),
             bend=(0,0,0), thickness=0.8, group=None):
        a,b = vec(base),vec(tip)
        d = unit(b-a)
        axis = vec(width_axis)
        axis = unit(axis-d*np.dot(axis,d))
        rows = []
        # Nonzero clipped ends avoid four coincident knots at each leaf tip.
        # Shell provides the tiny closing edge; no degenerate patch faces.
        for t in (0.0,0.22,0.5,0.78,1.0):
            extent = width*(0.035+0.965*math.sin(math.pi*t))/2
            mid = a+(b-a)*t+vec(bend)*math.sin(math.pi*t)
            rows.append([mid+axis*extent*s for s in (-1,-0.5,0,0.5,1)])
        return self.patch(name,rows,material,thickness,smooth=True,group=group)

    def tube(self, name, points, radius, material, closed=False, smooth=True,
             sides=5, group=None):
        p = points_list(points)
        if len(p)<2 or radius<=0:
            raise ValueError(f"Invalid spline tube: {name}")
        if closed and np.linalg.norm(vec(p[0])-vec(p[-1])) < 1e-6:
            p.pop()
        return self._add(name,material,group,kind="tube",points=p,radius=float(radius),
                         sides=int(sides),closed=bool(closed),smooth=bool(smooth))

    def mount(self, pillar_top=190, deck_length=570, deck_width=220,
              pillar_x=190, pillar_y=78, pillar_radius=11,
              material="wood", trim="brass"):
        self.box("MountingSkid",(0,0,4),(deck_length,deck_width,8),material)
        for i,x in enumerate((-pillar_x,pillar_x)):
            for j,y in enumerate((-pillar_y,pillar_y)):
                stem=f"Pillar_{i+1}_{j+1}"
                self.box(stem+"_Foot",(x,y,12),(pillar_radius*3,pillar_radius*3,8),material)
                self.cylinder(stem,(x,y,16),(x,y,pillar_top-15),pillar_radius,material,sides=8)
                self.cylinder(stem+"_BaseBand",(x,y,17),(x,y,22),pillar_radius+1.4,trim,sides=8)
                self.cylinder(stem+"_Capital",(x,y,pillar_top-23),(x,y,pillar_top-14),pillar_radius*1.4,trim,sides=8)
            self.box(f"SaddleBeam_{i+1}",(x,0,pillar_top-7),(pillar_radius*3.5,deck_width-10,14),material)

    def group(self, name, pivot, axis=(0,0,1), kind="hinge", notes=""):
        if any(g['name']==name for g in self.groups):
            raise ValueError(f"Duplicate group {name}")
        self.groups.append({"name":name,"pivot":points_list([pivot])[0],
                            "axis":points_list([unit(axis)])[0],"kind":kind,"notes":notes})
        return name

    def to_dict(self):
        return {"schema":1,"index":self.index,"slug":self.slug,"title":self.title,
                "coordinate_system":"X length, front -X, Y width, Z up",
                "groups":self.groups,"parts":self.parts,"notes":self.notes}

    def save(self,path):
        path=Path(path)
        path.parent.mkdir(parents=True,exist_ok=True)
        path.write_text(json.dumps(self.to_dict(),indent=2)+"\n",encoding="utf-8")
        return path
