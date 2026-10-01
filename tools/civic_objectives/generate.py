#!/usr/bin/env python3
"""Build the eight civic objective prototypes. Standard library only.

Y is up, metres are Spring world units, and all UVs address the existing Asian
atlas. No textures are generated or modified. Run from any working directory.
"""
import json
import math
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
# Normalized rectangles measured from the TOP LEFT of the 4096x4096 atlas.
# Insets keep bilinear filtering away from neighbouring atlas islands.
ATLAS = {
    'concrete': (.505, .884, .624, .997),
    'roof': (.680, .758, .745, .870),
    'facade': (.376, .152, .481, .243),
    'glass': (.376, .302, .481, .353),
    'blueglass': (.601, .253, .683, .293),
    'metal': (.376, .004, .455, .054),
    'paving': (.089, .758, .245, .873),
    'hvac': (.135, .440, .243, .497),
    'medical': (.036, .284, .082, .332),
    'shop': (.264, .514, .346, .556),
    'bronze': (.462, .373, .505, .416),
    'niches': (.689, .358, .772, .422),
    'red': (.022, .038, .030, .046),
    'teal': (.022, .071, .030, .078),
    'yellow': (.198, .150, .211, .168),
    'white': (.005, .005, .014, .013),
    'green': (.055, .037, .064, .046),
    'shutter': (.752, .567, .832, .626),
    'produce': (.135, .177, .164, .195),
    'sign': (.683, .575, .748, .600),
}


def sub(a, b): return tuple(x-y for x, y in zip(a, b))
def cross(a, b): return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])
def length(v): return math.sqrt(sum(x*x for x in v))


class Mesh:
    def __init__(self, name):
        self.name = name
        self.parts = {p: [] for p in ('base', 'structure', 'facades', 'details')}

    def face(self, points, mat='concrete', part='structure', uv=None):
        a, b, c = points[:3]
        n = cross(sub(b, a), sub(c, a))
        ln = length(n)
        if ln < 1e-8: raise ValueError('degenerate face')
        n = tuple(v/ln for v in n)
        x0, y0, x1, y1 = ATLAS[mat]
        # Collada uses bottom-left UV origin; image inspection uses top-left.
        rect = [(x0, 1-y1), (x1, 1-y1), (x1, 1-y0), (x0, 1-y0)]
        coords = uv if uv is not None else rect[:len(points)]
        for k in range(1, len(points)-1):
            for i in (0, k, k+1):
                self.parts[part].append((*points[i], *n, *coords[i]))

    def panel(self, points, mat, part='facades', tile=(28, 24)):
        # Subdivide the surface instead of repeating UVs outside an atlas island.
        a, b, c, d = points
        w, h = length(sub(b, a)), length(sub(d, a))
        nx, ny = max(1, math.ceil(w/tile[0])), max(1, math.ceil(h/tile[1]))
        def at(u,v): return tuple(a[k]+(b[k]-a[k])*u+(d[k]-a[k])*v for k in range(3))
        for j in range(ny):
            for i in range(nx):
                self.face([at(i/nx,j/ny),at((i+1)/nx,j/ny),at((i+1)/nx,(j+1)/ny),at(i/nx,(j+1)/ny)],mat,part)

    def box(self, x, y, z, w, h, d, mat='concrete', top=None, angle=0, part='structure', facade=False):
        cs, sn = math.cos(angle), math.sin(angle)
        def p(a,b,c): return (x+a*cs-c*sn,y+b,z+a*sn+c*cs)
        faces = [
            [p(-w/2,0,d/2),p(w/2,0,d/2),p(w/2,h,d/2),p(-w/2,h,d/2)],
            [p(w/2,0,-d/2),p(-w/2,0,-d/2),p(-w/2,h,-d/2),p(w/2,h,-d/2)],
            [p(w/2,0,d/2),p(w/2,0,-d/2),p(w/2,h,-d/2),p(w/2,h,d/2)],
            [p(-w/2,0,-d/2),p(-w/2,0,d/2),p(-w/2,h,d/2),p(-w/2,h,-d/2)],
        ]
        for f in faces:
            if facade: self.panel(f,mat)
            else: self.face(f,mat,part)
        self.face([p(-w/2,h,d/2),p(w/2,h,d/2),p(w/2,h,-d/2),p(-w/2,h,-d/2)],top or mat,part)
        self.face([p(-w/2,0,-d/2),p(w/2,0,-d/2),p(w/2,0,d/2),p(-w/2,0,d/2)],mat,part)

    def building(self,x,z,w,d,h,y=2,mat='facade',angle=0):
        self.box(x,y,z,w,h,d,mat,top='roof',angle=angle,facade=True)
        self.box(x,y+h,z,w+.8,1,d+.8,'concrete',top='roof',angle=angle)

    def cylinder(self,x,y,z,r,h,mat='concrete',n=16,top='roof',part='structure'):
        ring=[(x+math.cos(i*math.tau/n)*r,z+math.sin(i*math.tau/n)*r) for i in range(n)]
        u0,v0,u1,v1=ATLAS[top]
        def cap_uv(p): return (u0+(p[0]-x+r)/(2*r)*(u1-u0),1-v0-(p[1]-z+r)/(2*r)*(v1-v0))
        for i in range(n):
            a,b=ring[i],ring[(i+1)%n]
            self.face([(b[0],y,b[1]),(a[0],y,a[1]),(a[0],y+h,a[1]),(b[0],y+h,b[1])],mat,part)
            self.face([(x,y+h,z),(b[0],y+h,b[1]),(a[0],y+h,a[1])],top,part,[cap_uv((x,z)),cap_uv(b),cap_uv(a)])
            self.face([(x,y,z),(a[0],y,a[1]),(b[0],y,b[1])],mat,part)

    def beam(self,a,b,width,mat='concrete',part='structure'):
        v=sub(b,a);lv=length(v);v=tuple(k/lv for k in v)
        side=cross(v,(0,1,0) if abs(v[1])<.98 else (1,0,0))
        ls=length(side);side=tuple(k/ls*width/2 for k in side)
        up=cross(v,side)
        def corners(p): return [tuple(p[k]+s*side[k]+t*up[k] for k in range(3)) for s,t in [(-1,-1),(1,-1),(1,1),(-1,1)]]
        ca,cb=corners(a),corners(b)
        self.face(list(reversed(ca)),mat,part);self.face(cb,mat,part)
        for i in range(4): self.face([ca[i],ca[(i+1)%4],cb[(i+1)%4],cb[i]],mat,part)

    def vault(self,x,y,z,w,d,rise,mat='metal',segments=12):
        # Elliptical barrel roof, closed glazed gables, ridge along Z.
        arc=[(x+math.cos(i*math.pi/segments)*w/2,y+math.sin(i*math.pi/segments)*rise) for i in range(segments+1)]
        for i in range(segments):
            a,b=arc[i],arc[i+1]
            self.face([(a[0],a[1],z+d/2),(a[0],a[1],z-d/2),(b[0],b[1],z-d/2),(b[0],b[1],z+d/2)],mat)
            self.face([(x,y,z+d/2),(a[0],a[1],z+d/2),(b[0],b[1],z+d/2)],'blueglass','facades')
            self.face([(x,y,z-d/2),(b[0],b[1],z-d/2),(a[0],a[1],z-d/2)],'blueglass','facades')
        for zz in (z-d/2,z,z+d/2):
            for a,b in zip(arc,arc[1:]): self.beam((a[0],a[1]+.15,zz),(b[0],b[1]+.15,zz),.5)

    def plant(self,x,y,z,w=6,d=6):
        self.box(x,y,z,w,1.2,d,'concrete',top='green',part='details')

    def hvac(self,x,y,z):
        self.box(x,y,z,7,3,4,'hvac',top='metal',part='details')

    def helipad(self,x,y,z,r=13):
        self.cylinder(x,y,z,r,1,'concrete',24,'roof')
        for dx in (-3,3): self.box(x+dx,y+1.05,z,1,.12,8,'white',part='details')
        self.box(x,y+1.05,z,6,.12,1,'white',part='details')
        for i in range(24):
            a=i*math.tau/24
            self.box(x+math.cos(a)*(r-1.5),y+1.05,z+math.sin(a)*(r-1.5),2,.12,.6,'yellow',angle=a+math.pi/2,part='details')

    def stairs(self,x,z,w,count=6,y=2):
        for i in range(count): self.box(x,y,z-i*1.2,w,(i+1)*.65,1.3,'concrete')

    def base(self): self.box(0,0,0,124,2,124,'concrete',top='paving',part='base')

    def gate(self,x,z,w=8,h=6):
        self.box(x,2+h/2,z,w,.7,1,'yellow',part='details')
        for dx in (-w/2,w/2): self.box(x+dx,2,z,1,h,1,'concrete')


def prison():
    m=Mesh('prison');m.base()
    # Eight tangential cell wings produce an open octagonal courtyard.
    for i in range(8):
        a=i*math.pi/4
        x,z=math.cos(a)*41,math.sin(a)*41
        m.building(x,z,34.8,15,34,angle=a+math.pi/2)
        m.box(x,36,z,35,2,16,'concrete',top='roof',angle=a+math.pi/2)
        for off in (-13,0,13):
            xx=x-math.sin(a)*off;zz=z+math.cos(a)*off
            m.box(xx,2,zz,1.8,37,16,'concrete',angle=a+math.pi/2)
    for x,z,w,d in [(0,-59,118,2),(-59,0,2,118),(59,0,2,118),(-36,59,46,2),(36,59,46,2)]: m.box(x,2,z,w,7,d)
    for x in (-55,55):
        for z in (-55,55):
            m.box(x,2,z,6,12,6);m.building(x,z,9,9,4,y=14,mat='glass')
    m.cylinder(0,2,0,5,25);m.cylinder(0,27,0,9,5,'glass',8,part='facades');m.cylinder(0,32,0,10,1)
    for a in range(4):
        angle=a*math.pi/2
        m.beam((math.sin(angle)*8,24,math.cos(angle)*8),(math.sin(angle)*32,24,math.cos(angle)*32),3,'metal')
        for j in range(4,29,5): m.box(math.sin(angle)*j,2,math.cos(angle)*j,.35,6,.35,'metal',part='details')
        for height in (4,7): m.beam((math.sin(angle)*4,height,math.cos(angle)*4),(math.sin(angle)*29,height,math.cos(angle)*29),.25,'metal','details')
    m.building(0,53,23,13,10,mat='bronze');m.gate(0,61,10)
    return m


def hospital():
    m=Mesh('hospital');m.base()
    m.building(0,-42,104,23,48)
    for x in (-40,40):
        for j in range(4):
            z=-22+j*19;h=46-j*9
            m.building(x,z,24,19,h)
            m.plant(x-6,3+h,z,8,12);m.hvac(x+5,3+h,z)
            m.box(x,7,z,24.3,1.8,19.3,'teal',part='details')
    m.building(0,38,53,24,12,mat='blueglass')
    m.box(0,12,56,42,1.5,11,top='roof')
    for x in (-18,18): m.box(x,2,59,1.3,10,1.3)
    m.box(0,16,50.1,7,7,.3,'medical',part='facades')
    m.building(0,-4,60,6,5,y=17,mat='blueglass')
    m.helipad(34,51,-42,13)
    for x in (-13,13):
        for z in (-22,12): m.plant(x,2,z,9,13)
    for x in (-32,-12,8): m.hvac(x,51,-42)
    return m


def university():
    m=Mesh('university');m.base()
    for side in (-1,1):
        for k in range(9):
            x=side*(43-k*2.7);y=2+k*6
            m.building(x,-8,24,68,5,y=y,mat='facade')
            m.box(x,y+5,-8,26,1,71,'concrete')
            m.plant(x+side*9,y+6,-25,3,11)
        for z in (-39,23): m.beam((side*56,2,z),(side*21.4,57,z),3)
    m.building(0,-8,50,17,9,y=35,mat='blueglass')
    for x in (-38,38): m.building(x,43,30,23,12,mat='glass')
    m.cylinder(0,2,45,14,12,'bronze',24,part='facades');m.cylinder(0,14,45,15,1)
    m.cylinder(0,15,45,9,1,'blueglass',24,part='facades')
    for x in (-30,30): m.hvac(x,57,-26)
    for x in (-12,12): m.plant(x,2,15,7,10)
    m.stairs(0,61,24,7)
    return m


def recycling():
    m=Mesh('recycling');m.base()
    m.building(0,-43,107,23,44)
    for x in range(-48,49,16): m.box(x,2,-43,1.3,46,24)
    m.building(16,3,76,44,12,mat='shutter')
    for x in (-9,16,41):
        m.vault(x,14,3,24,46,7)
        m.box(x,2,25.2,13,10,.4,'shutter',part='details')
        m.box(x,12,25.7,14,1,1,'yellow',part='details')
    for z in (-6,12,30): m.cylinder(-42,2,z,7,21,'metal',16)
    m.box(-25,2,36,9,38,11,'concrete');m.box(-25,24,41.6,7,12,.3,'shutter',part='details')
    m.beam((-42,18,10),(-25,18,36),3,'metal','details')
    m.beam((-25,25,36),(4,25,15),3,'metal','details')
    for x in (-9,16,41):
        m.box(x,2,43,10,3,8,'metal',part='details')
        m.box(x,2,54,10,3,8,'shutter',part='details')
    for x in (-32,0,32): m.hvac(x,47,-43);m.plant(x,47,-36,12,5)
    return m


def courthouse():
    m=Mesh('courthouse');m.base()
    m.building(-40,-28,28,41,54,mat='bronze')
    for x in (-54,-47,-40,-33,-26): m.box(x,2,-28,1.5,57,42)
    m.building(14,0,72,73,19,mat='concrete')
    for x in (-13,5,23,41): m.vault(x,22,-3,15,54,6,'blueglass')
    m.box(13,18,44,78,4,12)
    for x in range(-24,52,8): m.box(x,2,47,2.6,17,3)
    m.box(13,3,37,62,14,.4,'bronze',part='facades')
    m.stairs(13,61,74,10)
    for x in (-46,-33): m.plant(x,2,40,8,11)
    m.box(-40,2,19,6,6,6);m.box(-40,8,19,11,2,4);m.box(-40,10,19,4,5,4)
    m.hvac(-40,58,-28)
    return m


def market():
    m=Mesh('market');m.base()
    for x in (-43,-9,25):
        m.building(x,5,26,92,10,mat='shop')
        m.vault(x,13,5,28,94,9)
        for z in (-35,-12,11,34):
            m.box(x,22,z,4,2,5,'metal',part='details')
        for xx in (-7,7):
            m.box(x+xx,2,54,8,3,5,'concrete',top='produce',part='details')
            m.box(x+xx,8,55,10,.6,10,'teal',part='details')
            m.box(x+xx-4,2,59,.4,6,.4,'metal',part='details')
    m.building(49,-28,18,42,40,mat='facade')
    m.cylinder(47,2,28,2,27);m.cylinder(47,29,28,7,10,'metal',12)
    m.cylinder(47,39,28,7.5,1)
    m.hvac(49,43,-35);m.hvac(49,43,-22)
    for x in (-26,8):
        for z in (-22,25): m.box(x,12,z,9,.6,12,'teal',part='details')
    return m


def cemetery():
    m=Mesh('cemetery');m.base()
    m.building(0,0,112,108,9,mat='bronze')
    for x,z,h,r in [(-29,-20,36,21),(26,-21,54,22),(0,26,24,18)]:
        for y in range(12,12+h,6):
            m.cylinder(x,y,z,r,5,'niches',20,part='facades')
            m.cylinder(x,y+5,z,r+1.4,1,'concrete',20)
        m.cylinder(x,12+h,z,r+1.5,1,'concrete',20,top='green')
        m.cylinder(x,13+h,z,r*.42,2,'blueglass',16,part='facades')
    m.beam((-9,28,-20),(5,28,-21),4,'metal')
    m.beam((-20,22,-1),(-9,22,11),4,'metal')
    for x,z in [(-43,33),(39,35),(-44,-44),(43,-45)]: m.plant(x,12,z,10,9)
    m.stairs(0,61,34,12)
    return m


def firestation():
    m=Mesh('fire_rescue');m.base()
    m.building(0,25,105,27,11,mat='concrete')
    for x in (-43,-26,-9,8,25,42):
        m.box(x,2,38.6,13,8,.35,'shutter',part='details')
        m.box(x,10,39,15,2,.8,'red',part='details')
        for dx in (-7,7): m.box(x+dx,2,39,1,9,1,'red',part='details')
        m.box(x,2.03,48,12,.1,.6,'yellow',part='details')
    m.building(0,-44,104,20,20)
    m.building(-44,-12,16,46,20)
    m.box(44,2,-20,10,42,12)
    for y in range(6,42,6):
        m.box(44,y,-13.9,6,3,.25,'roof',part='details')
        m.box(50,y,-20,3,.6,13,'metal',part='details')
        m.beam((51,y,-26),(51,y+6,-14),.8,'metal','details')
    m.cylinder(26,2,-12,3,26);m.helipad(26,28,-12,13)
    m.building(-46,48,19,19,9,mat='shutter')
    for x in (-25,0,25): m.hvac(x,23,-44)
    m.box(-8,22,-44,.6,13,.6,'metal',part='details')
    for y in (26,30): m.box(-8,y,-44,7,.3,.3,'metal',part='details')
    return m


BUILDERS = [
    (prison,'Prison Megablock','Detention blocks and civic administration'),
    (hospital,'Hospital Arcology','Medical wards, emergency care and staff housing'),
    (university,'University Megaproject','Teaching, research and student housing'),
    (recycling,'Recycling and Housing','Municipal materials recovery and worker housing'),
    (courthouse,'Courthouse and Archive','Civil courts and public records'),
    (market,'Wholesale Food Exchange','Covered markets and refrigerated distribution'),
    (cemetery,'Vertical Cemetery','Columbarium towers and memorial gardens'),
    (firestation,'Fire and Rescue Complex','Emergency services and training campus'),
]


def write_dae(mesh,path):
    ns='http://www.collada.org/2005/11/COLLADASchema'
    ET.register_namespace('',ns)
    def el(parent,tag,attrs=None,text=None):
        e=ET.SubElement(parent,'{'+ns+'}'+tag,attrs or {})
        if text is not None: e.text=str(text)
        return e
    doc=ET.Element('{'+ns+'}COLLADA',{'version':'1.4.1'})
    asset=el(doc,'asset');con=el(asset,'contributor');el(con,'authoring_tool',text='MOSAIC civic_objectives/generate.py')
    for k in ('created','modified'): el(asset,k,text='2026-10-01T00:00:00Z')
    el(asset,'unit',{'name':'meter','meter':'1'});el(asset,'up_axis',text='Y_UP')
    imgs=el(doc,'library_images');im=el(imgs,'image',{'id':'asian_atlas'});el(im,'init_from',text='../unittextures/house_asian_diffuse.dds')
    effects=el(doc,'library_effects');ef=el(effects,'effect',{'id':'atlas_effect'});prof=el(ef,'profile_COMMON')
    par=el(prof,'newparam',{'sid':'atlas_surface'});sur=el(par,'surface',{'type':'2D'});el(sur,'init_from',text='asian_atlas')
    par=el(prof,'newparam',{'sid':'atlas_sampler'});sam=el(par,'sampler2D');el(sam,'source',text='atlas_surface')
    tech=el(prof,'technique',{'sid':'common'});lam=el(tech,'lambert');di=el(lam,'diffuse');el(di,'texture',{'texture':'atlas_sampler','texcoord':'UVMap'})
    mats=el(doc,'library_materials');ma=el(mats,'material',{'id':'atlas_material','name':'AsianAtlas'});el(ma,'instance_effect',{'url':'#atlas_effect'})
    geos=el(doc,'library_geometries')
    for part,verts in mesh.parts.items():
        geo=el(geos,'geometry',{'id':part+'_mesh','name':part});me=el(geo,'mesh')
        for label,start,size,names in [('pos',0,3,'XYZ'),('norm',3,3,'XYZ'),('uv',6,2,'ST')]:
            sid=part+'_'+label;src=el(me,'source',{'id':sid})
            arr=el(src,'float_array',{'id':sid+'_array','count':str(len(verts)*size)},' '.join(f'{v[k]:.6f}' for v in verts for k in range(start,start+size)))
            acc=el(el(src,'technique_common'),'accessor',{'source':'#'+arr.attrib['id'],'count':str(len(verts)),'stride':str(size)})
            for name in names: el(acc,'param',{'name':name,'type':'float'})
        vs=el(me,'vertices',{'id':part+'_vertices'});el(vs,'input',{'semantic':'POSITION','source':'#'+part+'_pos'})
        tris=el(me,'triangles',{'count':str(len(verts)//3),'material':'atlas'})
        for semantic,source,off in [('VERTEX',part+'_vertices',0),('NORMAL',part+'_norm',1),('TEXCOORD',part+'_uv',2)]:
            a={'semantic':semantic,'source':'#'+source,'offset':str(off)}
            if semantic=='TEXCOORD': a['set']='0'
            el(tris,'input',a)
        el(tris,'p',text=' '.join(f'{i} {i} {i}' for i in range(len(verts))))
    scenes=el(doc,'library_visual_scenes');scene=el(scenes,'visual_scene',{'id':'Scene','name':'Scene'})
    root=el(scene,'node',{'id':'base','name':'base','type':'NODE'})
    for part in mesh.parts:
        node=root if part=='base' else el(root,'node',{'id':part,'name':part,'type':'NODE'})
        inst=el(node,'instance_geometry',{'url':'#'+part+'_mesh'})
        bind=el(el(inst,'bind_material'),'technique_common');mat=el(bind,'instance_material',{'symbol':'atlas','target':'#atlas_material'})
        el(mat,'bind_vertex_input',{'semantic':'UVMap','input_semantic':'TEXCOORD','input_set':'0'})
    el(el(doc,'scene'),'instance_visual_scene',{'url':'#Scene'})
    ET.indent(doc,space='  ');ET.ElementTree(doc).write(path,encoding='utf-8',xml_declaration=True)


def main():
    manifest=[]
    (ROOT/'objects3d').mkdir(exist_ok=True)
    for build,title,description in BUILDERS:
        m=build();name='objective_'+m.name
        verts=[v for part in m.parts.values() for v in part]
        low=[min(v[k] for v in verts) for k in range(3)]
        high=[max(v[k] for v in verts) for k in range(3)]
        height=math.ceil(high[1]);radius=math.ceil(max(length(sub(v[:3],(0,height/2,0))) for v in verts))
        write_dae(m,ROOT/'objects3d'/f'{name}.dae')
        (ROOT/'objects3d'/f'{name}.dae.lua').write_text(f'''-- Generated by tools/civic_objectives/generate.py; Y-up, origin at ground.
return {{
    radius = {radius}, height = {height}, midpos = {{0, {height/2:g}, 0}},
    tex1 = "house_asian_diffuse.dds",
    tex2 = "house_asian_selfilu_reflection.png",
}}
''')
        manifest.append(dict(name=name,title=title,description=description,triangles=len(verts)//3,height=height,radius=radius,bounds=[low,high],pieces=list(m.parts)))
    (ROOT/'tools/civic_objectives/manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    config=['-- Generated by tools/civic_objectives/generate.py.\nreturn {']
    for m in manifest:
        config.append('    {name="%s", title="%s", description="%s", height=%d},' % (m['name'],m['title'],m['description'],m['height']))
    config.append('}\n')
    (ROOT/'luarules/configs/civic_objectives.lua').write_text('\n'.join(config))
    print('\n'.join(f"{m['name']}: {m['triangles']} triangles, height {m['height']}" for m in manifest))


if __name__=='__main__': main()
