#!/usr/bin/env python3
"""Generate thirteen approved civilian truck payloads as one selectable model.

The meshes use Spring world units (COLLADA metre=1), Y up, +Z toward the cab,
and an empty ``center`` parent for carrier-specific mounting offsets. Their
48-unit skid fits the three existing payload-capable rigid trucks. All UVs
address the unmodified Asian-house atlas; no texture assets are generated.

Run with Python 3 from any directory. Only truckPayloadService.dae, its
sidecar and this directory's manifest are written. Standard library only.
"""
import hashlib
import json
import math
import sys
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
FLOOR = 2.1
# Include both the loose payload and all supported runtime center offsets in
# static culling bounds. The independent native test reads the actual Lua
# carrier table, so changing that contract cannot silently shrink these bounds.
MOUNT_OFFSETS = ((0, 0, 0), (0, 0, -3.5), (0, 3.5, 1), (0, 4.1, 0))
TEXTURES = {
    "diffuse": "unittextures/house_asian_diffuse.dds",
    "special": "unittextures/house_asian_selfilu_reflection.png",
    "normal": "unittextures/house_asian_normal.dds",
}
# Insets measured in the actual 4096-square images, from top left. Broad paint
# surfaces deliberately avoid the fully emissive colour palette at top left.
ATLAS = {
    "paint": (.821045, .844482, .835205, .858643),
    "worn": (.514, .920, .554, .970),
    "teal": (.773926, .734863, .780762, .741699),
    "metal": (.378, .005, .451, .051),
    "dark": (.843, .015, .893, .043),
    "vent": (.139, .440, .163, .494),
    "door": (.500, .058, .580, .137),
    "hazard": (.131, .663, .188, .672),
    "shutter": (.755, .569, .829, .621),
    "window": (.379, .301, .413, .333),
    "amber": (.191, .152, .201, .163),
    "redlamp": (.429, .063, .447, .067),
    "sign": (.255, .671, .284, .699),
    "menu": (.262, .440, .309, .498),
    "warning": (.706, .136, .761, .173),
    "medical": (.036, .284, .082, .332),
}


def add(a, b): return tuple(x + y for x, y in zip(a, b))
def sub(a, b): return tuple(x - y for x, y in zip(a, b))
def mul(v, k): return tuple(x * k for x in v)
def dot(a, b): return sum(x * y for x, y in zip(a, b))
def cross(a, b):
    return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])
def length(v): return math.sqrt(dot(v, v))
def unit(v):
    n = length(v)
    if n < 1e-9: raise ValueError("zero direction")
    return mul(v, 1/n)


class Mesh:
    def __init__(self, name):
        self.name = name
        self.parts = {name: [] for name in ("skid", "body", "equipment", "details")}
        self.features = []

    def face(self, points, material="paint", part="body", normal=None, uv=None):
        points = list(points)
        n = unit(cross(sub(points[1], points[0]), sub(points[2], points[0])))
        if normal is not None and dot(n, normal) < 0:
            points.reverse()
            if uv is not None: uv = list(reversed(uv))
            n = mul(n, -1)
        if uv is None:
            # Project each planar polygon onto its dominant plane. This also
            # preserves sensible UVs on caps with more than four corners.
            axes = sorted(range(3), key=lambda i: abs(n[i]))[:2]
            a, b = axes
            lo = [min(p[i] for p in points) for i in axes]
            hi = [max(p[i] for p in points) for i in axes]
            u0, v0, u1, v1 = ATLAS[material]
            uv = [(u0+(p[a]-lo[0])/(hi[0]-lo[0])*(u1-u0),
                   1-v1+(p[b]-lo[1])/(hi[1]-lo[1])*(v1-v0)) for p in points]
        for k in range(1, len(points)-1):
            # Curved sweep quads can be slightly nonplanar. Each exported
            # triangle needs its own normal, rather than borrowing the first
            # triangle's plane for both halves of the quad.
            triangle_normal=unit(cross(sub(points[k],points[0]),sub(points[k+1],points[0])))
            for i in (0, k, k+1):
                self.parts[part].append((*points[i], *triangle_normal, *uv[i]))

    def box(self, center, size, material="paint", part="body", top=None):
        x, y, z = center
        w, h, d = (q/2 for q in size)
        def p(a,b,c): return (x+a*w, y+b*h, z+c*d)
        faces = [([p(-1,-1,1),p(1,-1,1),p(1,1,1),p(-1,1,1)], (0,0,1)),
                 ([p(1,-1,-1),p(-1,-1,-1),p(-1,1,-1),p(1,1,-1)], (0,0,-1)),
                 ([p(1,-1,1),p(1,-1,-1),p(1,1,-1),p(1,1,1)], (1,0,0)),
                 ([p(-1,-1,-1),p(-1,-1,1),p(-1,1,1),p(-1,1,-1)], (-1,0,0)),
                 ([p(-1,1,1),p(1,1,1),p(1,1,-1),p(-1,1,-1)], (0,1,0)),
                 ([p(-1,-1,-1),p(1,-1,-1),p(1,-1,1),p(-1,-1,1)], (0,-1,0))]
        for ps, n in faces:
            self.face(ps, top if n[1] == 1 and top else material, part, n)

    def bevel(self, center, size, c=0.6, material="paint", part="body", edge="metal"):
        x, y, z = center; w,h,d = (q/2 for q in size)
        c = min(c,w*.45,h*.45,d*.45)
        outline=[(-w+c,-h),(w-c,-h),(w,-h+c),(w,h-c),
                 (w-c,h),(-w+c,h),(-w,h-c),(-w,-h+c)]
        rings=[]
        for zz, inset in [(-d,c),(-d+c,0),(d-c,0),(d,c)]:
            rings.append([(x+px*(w-inset)/w,y+py*(h-inset)/h,z+zz) for px,py in outline])
        self.face(rings[0],material,part,(0,0,-1))
        self.face(rings[-1],material,part,(0,0,1))
        for j in range(3):
            for i in range(8):
                ps=[rings[j][i],rings[j][(i+1)%8],rings[j+1][(i+1)%8],rings[j+1][i]]
                avg=tuple(sum(p[k] for p in ps)/4-center[k] for k in range(3))
                self.face(ps,material if j==1 and i%2==0 else edge,part,avg)

    def prism(self, polygon, depth, axis="x", material="paint", part="body", side=None):
        # Convex 2D polygon extruded along axis. Coordinates are YZ for x,
        # XZ for y, and XY for z. End winding is checked against the axis.
        a,b=depth; axis_i="xyz".index(axis)
        def p(q,v):
            o=list(q);o.insert(axis_i,v);return tuple(o)
        ra=[p(q,a) for q in polygon];rb=[p(q,b) for q in polygon]
        n=[0,0,0];n[axis_i]=-1;self.face(ra,material,part,n)
        n[axis_i]=1;self.face(rb,material,part,n)
        center=tuple((sum(p[k] for p in ra)+sum(p[k] for p in rb))/(2*len(ra)) for k in range(3))
        for i in range(len(ra)):
            j=(i+1)%len(ra);ps=[ra[i],ra[j],rb[j],rb[i]]
            n=tuple(sum(v[k] for v in ps)/4-center[k] for k in range(3))
            self.face(ps,side or material,part,n)

    def beam(self,a,b,width,material="metal",part="details",height=None):
        direction=unit(sub(b,a));u=unit(cross(direction,(0,1,0) if abs(direction[1])<.98 else (1,0,0)))
        v=unit(cross(direction,u));u=mul(u,width/2);v=mul(v,(height or width)/2)
        def ring(p):return [add(add(p,mul(u,s)),mul(v,t)) for s,t in [(-1,-1),(1,-1),(1,1),(-1,1)]]
        ra,rb=ring(a),ring(b)
        self.face(ra,material,part,mul(direction,-1));self.face(rb,material,part,direction)
        for i in range(4):
            j=(i+1)%4;ps=[ra[i],ra[j],rb[j],rb[i]]
            n=sub(mul(add(ra[i],ra[j]),.5),a)
            self.face(ps,material,part,n)

    def cylinder(self,a,b,r,material="metal",n=12,part="equipment",cap=None,r2=None):
        direction=unit(sub(b,a));u=unit(cross(direction,(0,1,0) if abs(direction[1])<.98 else (1,0,0)));v=cross(direction,u)
        def ring(p,r):return [add(p,add(mul(u,math.cos(i*math.tau/n)*r),mul(v,math.sin(i*math.tau/n)*r))) for i in range(n)]
        ra,rb=ring(a,r),ring(b,r if r2 is None else r2)
        self.face(ra,cap or material,part,mul(direction,-1));self.face(rb,cap or material,part,direction)
        for i in range(n):
            j=(i+1)%n;ps=[ra[i],ra[j],rb[j],rb[i]]
            self.face(ps,material,part,sub(mul(add(ra[i],ra[j]),.5),a))

    def tube(self,points,r=0.5,material="metal",n=8,part="equipment"):
        # Ring sweep with averaged tangent avoids gaps or intersecting cap fans
        # between the individual straight sections of a bent coolant pipe.
        rings=[];previous_u=None
        for i,p in enumerate(points):
            t=unit(sub(points[min(i+1,len(points)-1)],points[max(i-1,0)]))
            # Parallel transport the previous ring basis. Switching a fixed
            # reference axis at a vertical tangent can flip it by 180 degrees
            # and cross the connecting quads (visible on the bar tap bends).
            projected=sub(previous_u,mul(t,dot(previous_u,t))) if previous_u is not None else None
            if projected is not None and length(projected)>1e-7:
                u=unit(projected)
            else:
                u=unit(cross(t,(0,1,0) if abs(t[1])<.98 else (1,0,0)))
                if previous_u is not None and dot(u,previous_u)<0:u=mul(u,-1)
            previous_u=u;v=cross(t,u)
            rings.append([add(p,add(mul(u,r*math.cos(j*math.tau/n)),mul(v,r*math.sin(j*math.tau/n)))) for j in range(n)])
        self.face(rings[0],material,part,mul(unit(sub(points[1],points[0])),-1))
        self.face(rings[-1],material,part,unit(sub(points[-1],points[-2])))
        for i in range(len(points)-1):
            for j in range(n):
                k=(j+1)%n;ps=[rings[i][j],rings[i][k],rings[i+1][k],rings[i+1][j]]
                center=mul(add(points[i],points[i+1]),.5)
                self.face(ps,material,part,sub(mul(add(ps[0],ps[2]),.5),center))

    def ring(self,a,b,outer,inner,material="metal",n=16,part="equipment"):
        """Closed annular extrusion: real aperture, no opaque disc shortcut."""
        direction=unit(sub(b,a));u=unit(cross(direction,(0,1,0) if abs(direction[1])<.98 else (1,0,0)));v=cross(direction,u)
        def points(p,r):return [add(p,add(mul(u,math.cos(i*math.tau/n)*r),mul(v,math.sin(i*math.tau/n)*r))) for i in range(n)]
        ao,ai,bo,bi=points(a,outer),points(a,inner),points(b,outer),points(b,inner)
        for i in range(n):
            j=(i+1)%n
            self.face([ao[i],ao[j],ai[j],ai[i]],material,part,mul(direction,-1))
            self.face([bo[i],bo[j],bi[j],bi[i]],material,part,direction)
            radial=sub(mul(add(ao[i],ao[j]),.5),a)
            self.face([ao[i],ao[j],bo[j],bo[i]],material,part,radial)
            self.face([ai[i],ai[j],bi[j],bi[i]],material,part,mul(radial,-1))

    def plate(self,center,width,height,axis="x",material="door",part="details",normal=None):
        x,y,z=center
        if axis=="x":
            ps=[(x,y-height/2,z-width/2),(x,y-height/2,z+width/2),
                (x,y+height/2,z+width/2),(x,y+height/2,z-width/2)]
            n=(1 if x>=0 else -1,0,0)
        elif axis=="z":
            ps=[(x-width/2,y-height/2,z),(x+width/2,y-height/2,z),
                (x+width/2,y+height/2,z),(x-width/2,y+height/2,z)]
            n=(0,0,1 if z>=0 else -1)
        else:
            ps=[(x-width/2,y,z-height/2),(x+width/2,y,z-height/2),
                (x+width/2,y,z+height/2),(x-width/2,y,z+height/2)]
            n=(0,1,0)
        self.face(ps,material,part,normal if normal is not None else n)
        if normal is None:
            # An inset can face +X while sitting at negative X. Two opposing
            # faces avoid guessing a surface orientation from its position.
            # Native backface culling displays one side; four triangles still
            # replace the old twelve-triangle thin box.
            self.face(ps,material,part,mul(n,-1))

    def grille(self,center,width,height,axis="x",bars=7):
        x,y,z=center;self.plate(center,width,height,axis,"vent")
        if axis=="x":
            for zz in (z-width/2,z+width/2):self.box((x,y,zz),(.38,height+.5,.38),"metal","details")
            for yy in (y-height/2,y+height/2):self.box((x,yy,z),(.38,.38,width),"metal","details")
        elif axis=="z":
            for xx in (x-width/2,x+width/2):self.box((xx,y,z),(.38,height+.5,.38),"metal","details")
            for yy in (y-height/2,y+height/2):self.box((x,yy,z),(width,.38,.38),"metal","details")

    def latch(self,x,y,z,side=1):
        self.plate((x+side*.12,y,z),.8,1.8,"x","door")

    def base(self):
        self.box((0,FLOOR+.7,0),(28.0,1.4,47.4),"metal","skid",top="worn")
        for x in (-13.4,13.4):self.box((x,FLOOR+1.4,0),(1.2,1.5,48),"metal","skid")
        for z in (-23.4,23.4):self.box((0,FLOOR+1.4,z),(26,1.5,1.2),"metal","skid")
        for z in (-22.5,22.5):
            self.plate((14.08,FLOOR+1.5,z),1.7,.55,"x","amber")
            self.plate((-14.08,FLOOR+1.5,z),1.7,.55,"x","redlamp")


def scrubber():
    m=Mesh("air_scrubber");m.base()
    m.bevel((0,12.0,1),(25,17,40),1.2,"teal",edge="worn")
    # Main compressor on cab end; three independently latched filter cassettes
    # along each side make the machine read as maintainable industrial plant.
    m.bevel((0,11.0,18),(25,15,8),.8,"worn")
    m.grille((0,11.5,22.18),20,10,"z",9)
    for side in (-1,1):
        for z in (-14,-4,6):
            m.bevel((side*11.65,11.3,z),(2.0,13,8.6),.55,"paint",edge="metal")
            m.latch(side*12.8,10.7,z+2.5,side)
            m.box((side*12.8,6,z),(0.6,.9,6),"metal","details")
            m.box((side*12.8,17,z),(.6,.9,6),"metal","details")
        m.plate((side*12.68,11,-16),2.2,5,"x","warning")
    # Two unequal, forward-leaning scoops; their large dark intake apertures
    # are actual recessed geometry, with physical louvres and a thick rim.
    for z,h,w in [(10,34,16),(-8,29,14)]:
        m.bevel((-2,22,z),(12,6,w-2),.5,"teal")
        # A raked mouth, genuinely leaning up/out instead of a square chimney.
        lower=[(-8,22,z-w/2+2),(3,22,z-w/2+2),(3,22,z+w/2-2),(-8,22,z+w/2-2)]
        middle=[(-9,26,z-w/2),(7,26,z-w/2),(7,26,z+w/2),(-9,26,z+w/2)]
        upper=[(-12,h,z-w/2),(2,h,z-w/2),(2,h,z+w/2),(-12,h,z+w/2)]
        for ra,rb in ((lower,middle),(middle,upper)):
            for i in range(4):
                j=(i+1)%4
                outward=[(0,0,-1),(1,.3,0),(0,0,1),(-1,0,0)][i]
                m.face([ra[i],ra[j],rb[j],rb[i]],"worn" if i%2 else "paint","body",outward)
        m.face(upper,"paint","body",(0,1,0))
        def mouth_x(y):return 7+(2-7)*(y-26)/(h-26)+.12
        ps=[(mouth_x(26.7),26.7,z-w/2+.8),(mouth_x(h-.7),h-.7,z-w/2+.8),
            (mouth_x(h-.7),h-.7,z+w/2-.8),(mouth_x(26.7),26.7,z+w/2-.8)]
        m.face(ps,"dark","details",(1,.5,0))
        for a,b in zip(ps,ps[1:]+ps[:1]):m.beam(a,b,.65,"metal")
        for yy in range(27,int(h)-1):m.box((mouth_x(yy)+.14,yy,z),(.28,.19,w-2.2),"metal","details")
    m.cylinder((-7,22,-19),(7,22,-19),3.6,"metal",14,cap="vent")
    for xx in (-6,0,6):m.cylinder((xx-.35,22,-19),(xx+.35,22,-19),3.85,"worn",14)
    m.tube([(-9,20,-19),(-10,20,-13),(-10,18,-10)],.9,"metal")
    m.features=["unequal twin louvred air scoops","six latched filter cassettes","rear duct and compressor grille"]
    return m


def kitchen():
    m=Mesh("night_kitchen");m.base()
    # A genuine serving recess, with counter, shelves and food preparation
    # geometry inside, instead of a restaurant photograph on a solid wall.
    m.box((-9.7,15,2),(4.1,22,36),"teal")
    m.box((0,7.1,2),(23,6.4,36),"worn")
    m.box((0,22.2,2),(23,2.8,36),"paint")
    for z in (-15.5,19.5):m.bevel((0,15,z),(23,19,2),.5,"teal")
    m.box((-6.9,14.5,2),(.4,11,32),"metal")
    m.box((1,10.1,2),(24.5,1.2,32),"metal","equipment")
    # Rolled part-open shutter and sloped roof remain within carrier envelope.
    m.box((11.7,20.2,2),(.6,3,31),"shutter","equipment")
    m.prism([(22,-16),(27,-13),(27,17),(22,20)],(-12.0,12.2),"x","worn",side="paint")
    m.box((12.1,21.8,2),(.8,.7,33),"metal","details")
    m.plate((12.55,21.0,2),24,.45,"x","amber")
    # Hinged serving ledge is shallow, not an impossible permanent wide awning.
    m.box((12.35,10.0,2),(3.2,.6,31),"worn","equipment")
    for z in (-12,15):m.beam((13.6,9.8,z),(11.8,6.8,z),.3)
    for y in (13.1,17.1):m.box((-3.2,y,3),(7,.35,26),"metal","equipment")
    for z,r in [(-7,1.9),(1,2.2),(10,1.65)]:
        m.cylinder((6,10.75,z),(6,14.3,z),r,"metal",10)
        m.cylinder((6,14.3,z),(6,14.65,z),r+.15,"worn",10)
        m.box((6,15,z),(.5,.6,1.3),"dark","details")
    for i in range(5):
        z=-8+i*4.4
        m.cylinder((-4,17.3,z),(-4,18.8,z),.65,"worn",8,"details")
    m.plate((12.8,16.5,-13.8),2.1,5.2,"x","menu")
    m.bevel((0,29,4),(17,4.5,27),.6,"metal")
    m.grille((8.6,29,4),23,3.2,"x",4)
    m.cylinder((-4,31.3,-7),(-4,34.6,-7),1.65,"metal",10)
    m.cylinder((-4,34.6,-7),(-4,35.1,-7),2.1,"worn",10)
    # Rear refrigerator and two restrained propane cylinders.
    m.bevel((-2,15.2,-20),(18,22,5.4),.7,"paint")
    m.plate((7.15,16,-20),3.8,16,"x","door")
    m.latch(7.35,16,-20)
    for xx in (8.9,12):
        m.cylinder((xx,5.2,-20),(xx,13.2,-20),1.35,"worn",10)
        m.cylinder((xx,13.2,-20),(xx,13.7,-20),1.1,"metal",10)
        m.box((xx,14.05,-20),(.35,.7,.5),"metal","details")
    m.plate((-12.0,16,4),17,9,"x","sign")
    m.features=["open serving recess with cookware and shelves","sloped hood and rooftop extractor","rear fridge and restrained gas cylinders"]
    return m


def battery():
    m=Mesh("battery_exchange");m.base()
    m.bevel((-6,16,1),(12,24,42),.8,"teal")
    # Three large battery drawers span the length forward of the reel.
    for i,y in enumerate((8,15.3,22.6)):
        m.bevel((1.2,y,9.8),(22.5,6.4,22.8),.65,"paint",edge="metal")
        for side in (-1,1):
            m.plate((side*12.6,y,10),18.8,4.5,"x","worn")
            m.latch(side*12.8,y,18,side)
            m.plate((side*12.84,y,-.2),1,2.1,"x","hazard")
            m.plate((side*12.87,y+.8,4),1.2,.35,"x","amber")
        m.box((1.2,y+3.35,9.8),(23,.45,23),"metal","equipment")
    # Large side-mounted cable spool is geometrical, with four cable wraps,
    # a hub, spokes, rim plates and vertical support cradle.
    y,z=15.5,-12.7
    m.cylinder((-5,y,z),(9.5,y,z),8.4,"dark",20)
    for x in (-4.4,-.2,4,8.2):
        m.cylinder((x-.35,y,z),(x+.35,y,z),8.65,"metal",20)
    for x in (-5.4,10):
        m.ring((x-.35,y,z),(x+.35,y,z),9.45,7.8,"teal",20)
        m.cylinder((x-.5,y,z),(x+.5,y,z),2.15,"metal",12)
    for r in (3.5,5.1,6.7):m.ring((9.8,y,z),(10.1,y,z),r,r-.3,"metal",20)
    for a in range(6):
        angle=a*math.tau/6
        m.beam((10.6,y+math.cos(angle)*2,z+math.sin(angle)*2),(10.6,y+math.cos(angle)*8.5,z+math.sin(angle)*8.5),.6,"metal")
    for zz in (-22.3,-3.2):m.box((11.2,15.0,zz),(1.5,23.2,1.4),"metal","equipment")
    m.box((11.2,26.3,-12.7),(1.5,1.4,20.4),"metal","equipment")
    m.bevel((-8,29.2,-9),(7,3.8,15),.5,"paint")
    m.grille((-11.7,17,-12),17,18,"x",10)
    m.tube([(10.9,14,-13),(12.8,12,-16),(12.8,6,-20)],.65,"dark")
    # Stout rectangular lifting handle and a service meter.
    for z in (-13,13):m.box((-2,31,z),(1.5,4.6,1.6),"metal","equipment")
    m.box((-2,33.3,0),(1.5,1.5,27.5),"worn","equipment")
    m.plate((12.85,26.1,11),4.3,2.3,"x","door")
    m.features=["three battery drawers","large spoke-and-cable reel","lifting handle and radiator cabinet"]
    return m


def salvage():
    m=Mesh("salvage_press");m.base()
    m.bevel((0,9.1,0),(17,10.4,43),.9,"teal")
    # Segmented beetle shell rises over the folded compression machinery.
    profile=[(12,-21),(22,-21),(28,-12),(30,7),(27,16),(20,21),(12,21)]
    for x0,x1 in [(-12.5,-5),(-4.4,4.4),(5,12.5)]:
        m.prism(profile,(x0,x1),"x","paint",side="worn")
    for z in (-11,9):m.box((0,30.2,z),(5,.5,3.6),"metal","details")
    # Rear mouth with physical twin rollers inside a frame.
    m.box((0,12.8,-20.3),(21,14,1),"dark","equipment")
    for x in (-11.2,11.2):m.box((x,12.8,-22.4),(1.2,15,1.4),"worn","equipment")
    m.box((0,20.2,-22.4),(23,1.2,1.4),"worn","equipment")
    for y in (9,15):
        m.cylinder((-10,y,-21.25),(10,y,-21.25),2.5,"metal",12)
        for x in (-8,-4,0,4,8):m.cylinder((x-.3,y,-21.25),(x+.3,y,-21.25),2.7,"worn",12)
    m.box((0,5.4,-23.2),(23,.7,1.5),"hazard","details")
    # Two folded hydraulic arms link hinges; they are part of the payload,
    # with no crane or digging attachment extending into neighboring traffic.
    for side in (-1,1):
        xx=side*12.9
        for a,b in [((xx,24,16),(xx,21,-7)),((xx,21,-7),(xx,9,-17))]:
            m.beam(a,b,1.4,"teal",height=2.3)
        for yy,zz in ((24,16),(21,-7),(9,-17)):
            m.cylinder((xx-side*.3,yy,zz),(xx+side*.5,yy,zz),1.8,"metal",10)
            m.cylinder((xx+side*.5,yy,zz),(xx+side*.65,yy,zz),.85,"worn",8)
        m.cylinder((xx,10,13),(xx,18,-3),.65,"metal",8)
        m.cylinder((xx,18,-3),(xx,20,-7),.38,"paint",8)
        # Shallow salvage cage: rails and visible distinct mechanical scraps.
        m.box((side*12.7,7.3,5),(.8,1,26),"metal","details")
        m.box((side*13.1,14.2,5),(.6,.6,26),"metal","details")
        for z in (-8,-3,2,7,12,18):m.box((side*13.1,10.7,z),(.45,7,.45),"metal","details")
        for y in (9.1,11.6):m.box((side*13.1,y,5),(.32,.32,26),"metal","details")
        for z in (-4,4,12):
            m.bevel((side*10.6,11,z),(3.2,4.4,4.8),.35,"door",part="equipment")
    m.plate((0,23.8,21.05),15,2.2,"z","hazard")
    m.features=["segmented beetle compactor shell","two visible compression rollers","folded hydraulic arms and salvage cages"]
    return m


def cold_chain():
    m=Mesh("cold_chain");m.base()
    # Three separately sealed tilted transport caskets, visible from either
    # road side. Their stepped height and dark inspection windows establish
    # the approved refrigerated-organ-cargo silhouette without exposed contents.
    for x,top,tip in [(-8.4,28.2,6.5),(0,32.5,7.5),(8.4,29,6.5)]:
        poly=[(7,-19),(10,-22),(15,-22),(top,9),(top-1.4,14),(top-7,16),(8,0)]
        m.prism(poly,(x-3.65,x+3.65),"x","paint",side="worn")
        for zz in (-15,7):m.box((x,6.8,zz),(7.8,2,2.7),"metal","equipment")
        # Window lies directly on the long sloping roof, with a raised gasket.
        z0,z1=-6,7
        def yy(z):return 15+(top-15)*(z+22)/31
        ps=[(x-1.5,yy(z0)+.14,z0),(x+1.5,yy(z0)+.14,z0),(x+1.5,yy(z1)+.14,z1),(x-1.5,yy(z1)+.14,z1)]
        m.face(ps,"dark","details",(0,1,-.5))
        for a,b in zip(ps,ps[1:]+ps[:1]):m.beam(a,b,.23,"metal")
        m.plate((x,11.1,-22.14),3.4,.6,"z","amber")
        for zz in (-15,5):
            m.box((x-3.8,13 if zz<0 else top-5,zz),(.55,2.2,.8),"metal","details")
            m.box((x+3.8,13 if zz<0 else top-5,zz),(.55,2.2,.8),"metal","details")
    # Two rear refrigeration units are actual boxes and louvres, connected
    # by exposed coolant pipes; no new texture or painted machine billboard.
    m.bevel((0,19,20),(24,27,5),.7,"teal")
    for xx in (-6,6):
        m.bevel((xx,19,20.5),(10.5,23.5,4.4),.5,"paint")
        m.grille((xx,19,22.85),8.4,19.5,"z",12)
    for side in (-1,1):
        for i,y in enumerate((8.5,12.0,15.5)):
            m.tube([(side*12,20-i*3,17),(side*12.6,y+4,11),(side*12.6,y+1,5),(side*11.6,y,-8)],.58,"metal")
        m.plate((side*12.9,21.7,16.9),3.4,4,"x","medical")
    m.features=["three inclined sealed caskets","raised inspection-window gaskets","paired refrigeration cabinets and coolant loops"]
    return m


def sleeper():
    m=Mesh("sleeper_shuttle");m.base()
    # Six sleeping pods run across the width. Their doors face both roadsides
    # and are staggered along the vehicle, so no facade is an untextured wall.
    for row,y in enumerate((11.4,25.3)):
        for col,z in enumerate((-14.5,0,14.5)):
            m.bevel((0,y,z),(25.2,12.1,13.4),1.35,"teal",edge="metal")
            for side in (-1,1):
                # Chamfered end plates have real depth, gasket, window,
                # recessed latch and a very small door-status light.
                m.bevel((side*12.55,y,z),(1.1,10.9,12.0),.38,"paint",edge="worn")
                m.plate((side*13.18,y+2.2,z),8.5,2.25,"x","dark")
                m.plate((side*13.29,y+2.18,z),6.9,1.0,"x","amber" if (row+col)%3==0 else "window")
                m.latch(side*13.3,y-2.1,z+3.6,side)
                m.plate((side*13.3,y,z-4.85),.35,4.5,"x","amber")
            m.box((0,y+6.25,z),(23,.55,10.5),"metal","equipment")
    # Continuous pipes tie the independent pod rack to a narrow HVAC spine.
    for y in (4.4,18.1,32.1):
        m.cylinder((-11.3,y,-22),(11.3,y,-22),.75,"metal",8)
        for x in (-11.3,11.3):m.cylinder((x,y,-22),(x,y,21.5),.58,"metal",8)
    m.bevel((0,18.8,-22),(20.5,29.4,3.4),.65,"paint")
    m.grille((0,20.5,-23.85),16.5,20,"z",12)
    m.bevel((-6.8,34.2,-18),(7.5,3.4,8),.45,"metal")
    m.grille((-2.95,34.2,-18),5.4,2,"x",3)
    # Stowed access ladder against the rear face, within the travel envelope.
    for x in (9.0,12.0):m.beam((x,4.5,-23.5),(x,17.5,-23.5),.45)
    for y in (6,8.5,11,13.5,16):m.beam((9,y,-23.5),(12,y,-23.5),.4,"worn")
    m.features=["six individual chamfered sleeping capsules","lit door slits and separate latches","rear HVAC spine, plumbing and stowed ladder"]
    return m


BUILDERS = [
    (scrubber,"Air Scrubber"), (kitchen,"Night Kitchen"),
    (battery,"Battery Exchange"), (salvage,"Salvage Press"),
    (cold_chain,"Cold Chain"), (sleeper,"Sleeper Shuttle"),
]


def write_dae(meshes,path):
    ns="http://www.collada.org/2005/11/COLLADASchema";ET.register_namespace("",ns)
    def el(parent,tag,attrs=None,text=None):
        e=ET.SubElement(parent,"{"+ns+"}"+tag,attrs or {})
        if text is not None:e.text=str(text)
        return e
    doc=ET.Element("{"+ns+"}COLLADA",{"version":"1.4.1"})
    asset=el(doc,"asset");con=el(asset,"contributor")
    el(con,"authoring_tool",text="MOSAIC truck_service_payloads/generate.py")
    for k in ("created","modified"):el(asset,k,text="2026-10-27T00:00:00Z")
    el(asset,"unit",{"name":"meter","meter":"1"});el(asset,"up_axis",text="Y_UP")
    imgs=el(doc,"library_images");im=el(imgs,"image",{"id":"asian_atlas"})
    el(im,"init_from",text="../"+TEXTURES["diffuse"])
    effects=el(doc,"library_effects");ef=el(effects,"effect",{"id":"atlas_effect"});pr=el(ef,"profile_COMMON")
    pa=el(pr,"newparam",{"sid":"atlas_surface"});su=el(pa,"surface",{"type":"2D"});el(su,"init_from",text="asian_atlas")
    pa=el(pr,"newparam",{"sid":"atlas_sampler"});sa=el(pa,"sampler2D");el(sa,"source",text="atlas_surface")
    te=el(pr,"technique",{"sid":"common"});la=el(te,"lambert");di=el(la,"diffuse")
    el(di,"texture",{"texture":"atlas_sampler","texcoord":"UVMap"})
    mats=el(doc,"library_materials");ma=el(mats,"material",{"id":"atlas_material","name":"AsianHouseAtlas"})
    el(ma,"instance_effect",{"url":"#atlas_effect"})
    geos=el(doc,"library_geometries")
    # All of a variant lives in ONE engine piece. A piece's visibility does
    # not propagate to children in Spring; nested equipment nodes would leak
    # other payloads when the unit script hides unselected container pieces.
    pieces={f"container{i+1}":[v for values in mesh.parts.values() for v in values]
            for i,mesh in enumerate(meshes)}
    for part,verts in pieces.items():
        geo=el(geos,"geometry",{"id":part+"_mesh","name":part});me=el(geo,"mesh")
        for label,start,size,names in [("pos",0,3,"XYZ"),("norm",3,3,"XYZ"),("uv",6,2,"ST")]:
            sid=part+"_"+label;src=el(me,"source",{"id":sid})
            arr=el(src,"float_array",{"id":sid+"_array","count":str(len(verts)*size)},
                   " ".join(f"{v[k]:.6f}" for v in verts for k in range(start,start+size)))
            acc=el(el(src,"technique_common"),"accessor",{"source":"#"+arr.get("id"),"count":str(len(verts)),"stride":str(size)})
            for name in names:el(acc,"param",{"name":name,"type":"float"})
        vs=el(me,"vertices",{"id":part+"_vertices"});el(vs,"input",{"semantic":"POSITION","source":"#"+part+"_pos"})
        tri=el(me,"triangles",{"count":str(len(verts)//3),"material":"atlas"})
        for sem,source,off in [("VERTEX",part+"_vertices",0),("NORMAL",part+"_norm",1),("TEXCOORD",part+"_uv",2)]:
            attrs={"semantic":sem,"source":"#"+source,"offset":str(off)}
            if sem=="TEXCOORD":attrs["set"]="0"
            el(tri,"input",attrs)
        el(tri,"p",text=" ".join(f"{i} {i} {i}" for i in range(len(verts))))
    scene=el(el(doc,"library_visual_scenes"),"visual_scene",{"id":"Scene","name":"Scene"})
    center=el(scene,"node",{"id":"center","name":"center","type":"NODE"})
    el(center,"matrix",text="1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1")
    for part,verts in pieces.items():
        node=el(center,"node",{"id":part,"name":part,"type":"NODE"})
        inst=el(node,"instance_geometry",{"url":"#"+part+"_mesh"})
        mat=el(el(el(inst,"bind_material"),"technique_common"),"instance_material",{"symbol":"atlas","target":"#atlas_material"})
        el(mat,"bind_vertex_input",{"semantic":"UVMap","input_semantic":"TEXCOORD","input_set":"0"})
    el(el(doc,"scene"),"instance_visual_scene",{"url":"#Scene"})
    ET.indent(doc,space="  ");ET.ElementTree(doc).write(path,encoding="utf-8",xml_declaration=True)


def main():
    from additional import ADDITIONAL_SPECS as ADDITIONAL_BUILDERS
    from unato import UNATO_SPECS
    all_builders=BUILDERS+ADDITIONAL_BUILDERS+UNATO_SPECS
    assert len(all_builders)==13,"Approved service payload bundle requires thirteen variants"
    entries=[];meshes=[]
    for index,(build,title) in enumerate(all_builders,1):
        mesh=build();name=mesh.name;meshes.append(mesh)
        verts=[v for values in mesh.parts.values() for v in values]
        lo=[min(v[k] for v in verts) for k in range(3)]
        hi=[max(v[k] for v in verts) for k in range(3)]
        # Useful bound checks protect against accidentally giving a rigid
        # truck the dimensions of the explicitly excluded long-truck asset.
        assert lo[0]>=-14.3 and hi[0]<=14.3,(name,"width",lo,hi)
        assert lo[2]>=-24.1 and hi[2]<=24.1,(name,"length",lo,hi)
        assert abs(lo[1]-FLOOR)<1e-7,(name,"mount floor",lo)
        assert hi[1]<39,(name,"height",hi)
        mid=[(lo[k]+hi[k])/2 for k in range(3)]
        radius=math.ceil(max(length(sub(v[:3],mid)) for v in verts));height=math.ceil(hi[1])
        entries.append({"name":name,"title":title,"piece":f"container{index}",
                        "triangles":len(verts)//3,"parts":{k:len(v)//3 for k,v in mesh.parts.items()},
                        "bounds":[[round(x,6) for x in lo],[round(x,6) for x in hi]],
                        "radius":radius,"height":height,"midpos":mid,
                        "features":mesh.features})
        if hasattr(mesh,"stack"):
            entries[-1]["stack"]=mesh.stack
    path=ROOT/"objects3d"/"truckPayloadService.dae";write_dae(meshes,path)
    allverts=[v for mesh in meshes for values in mesh.parts.values() for v in values]
    lo=[min(v[k] for v in allverts) for k in range(3)];hi=[max(v[k] for v in allverts) for k in range(3)]
    mid=[(lo[k]+hi[k])/2 for k in range(3)]
    radius=math.ceil(max(length(sub(add(v[:3],offset),mid))
                         for offset in MOUNT_OFFSETS for v in allverts))+1
    height=math.ceil(max(hi[1]+offset[1] for offset in MOUNT_OFFSETS))+1
    sidecar=ROOT/"objects3d"/"truckPayloadService.dae.lua"
    sidecar.write_text("-- Generated by tools/truck_service_payloads/generate.py.\n"
                      "-- Bounds include the runtime center offsets on all supported carriers.\n"
                      "return {\n"
                      f"    radius = {radius}, height = {height}, midpos = {{{mid[0]:.4f}, {mid[1]:.4f}, {mid[2]:.4f}}},\n"
                      '    tex1 = "house_asian_diffuse.dds",\n'
                      '    tex2 = "house_asian_selfilu_reflection.png",\n'
                      "}\n")
    manifest={"schema_version":1,"generator":"tools/truck_service_payloads/generate.py",
              "model":"objects3d/truckPayloadService.dae","sha256":hashlib.sha256(path.read_bytes()).hexdigest(),
              "coordinates":{"up":"Y","forward":"+Z","unit_meters":1,"root":"center","floor_y":FLOOR},
              "culling":{"radius":radius,"height":height,"midpos":mid,
                         "includes_mount_offsets":MOUNT_OFFSETS},
              "mounting":"Existing truck attachment point plus validated per-carrier center offsets in lib_truck_service_payloads.lua",
              "textures":TEXTURES,"atlas_rectangles_top_left":ATLAS,"variants":entries}
    (Path(__file__).parent/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n")
    for e in entries:print(f"{e['name']}: {e['triangles']} triangles; bounds {e['bounds']}")


if __name__=="__main__":
    # additional.py imports the common Mesh/ATLAS module. Share this exact
    # module when invoked as a script so its measured skin/cloth UV islands
    # also appear in the manifest, and do not load duplicate helper globals.
    sys.modules.setdefault("generate",sys.modules[__name__])
    main()
