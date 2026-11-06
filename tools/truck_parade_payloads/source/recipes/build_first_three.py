"""Three lantern-float recipes.  Native geometry is emitted as spline cages.

The recipe coordinates are X-longitudinal, front -X, Y lateral, Z up.
All decorative parts are real volumes or live-Shell surfaces, never image cards.
"""
from __future__ import annotations

import math
import sys
from pathlib import Path
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from authoring import Recipe


def ellipse_x(x, y, z, ry, rz, count=16):
    return [(x, y + ry * math.cos(i * 2 * math.pi / count),
             z + rz * math.sin(i * 2 * math.pi / count)) for i in range(count)]


def ellipse_z(x, y, z, rx, ry, count=12):
    return [(x + rx * math.cos(i * 2 * math.pi / count),
             y + ry * math.sin(i * 2 * math.pi / count), z) for i in range(count)]


def copy_curve_handles(target,source,indices):
    """Carry source tangents across an open subset of a closed parent spline.

    Absolute handles include the target knot displacement. This prevents the
    default one-sided endpoint tangent from cutting a curved overlay into its
    underlying body when Surface's interpolation steps are raised in Max.
    """
    pts=np.array(source['points'],dtype=float)
    n=len(pts)
    ins=[];outs=[]
    for p,i in zip(target['points'],indices):
        if 'in_handles' in source:
            incoming=np.array(source['in_handles'][i])-pts[i]
            outgoing=np.array(source['out_handles'][i])-pts[i]
        else:
            if source['closed']:
                tangent=(pts[(i+1)%n]-pts[(i-1)%n])/6
            elif i==0:
                tangent=(pts[1]-pts[0])/3
            elif i==n-1:
                tangent=(pts[-1]-pts[-2])/3
            else:
                tangent=(pts[i+1]-pts[i-1])/6
            incoming=-tangent;outgoing=tangent
        ins.append((np.array(p)+incoming).round(6).tolist())
        outs.append((np.array(p)+outgoing).round(6).tolist())
    target['in_handles']=ins
    target['out_handles']=outs


def mantle(r, name, sections, material, sides=12, source_part=None):
    """A genuine curved upper-body panel sharing the body's section shape."""
    grid = []
    for x, y, z, ry, rz in sections:
        grid.append([(x, y + (ry + 1.4) * math.cos(a),
                      z + (rz + 1.4) * math.sin(a))
                     for a in [j*2*math.pi/sides for j in range(sides//2+1)]])
    part=r.patch(name, grid, material, thickness=0.65)
    if source_part is not None:
        rings=[c for c in source_part['curves'] if c['closed']]
        rails=[c for c in source_part['curves'] if not c['closed']]
        assert len(rings)==len(grid)
        width=len(grid[0])
        for i in range(len(grid)):
            copy_curve_handles(part['curves'][i],rings[i],range(width))
        for j in range(width):
            copy_curve_handles(part['curves'][len(grid)+j],rails[j],
                               range(1,len(grid)+1))
    return part


def leaf_ink(r, name, source_part, material, group=None, normal_hint=(0,0,1)):
    """Use the same lattice as the luminous leaf, preventing crossing overlays."""
    grid=np.array(source_part['vertices']).reshape(5,5,3)
    along=grid[3,2]-grid[1,2]
    across=grid[2,3]-grid[2,1]
    normal=np.cross(along,across)
    normal/=np.linalg.norm(normal)
    if np.dot(normal,normal_hint)<0: normal=-normal
    offset=source_part['thickness']/2+.65/2+.4
    part=r.patch(name,(grid[:,1:4]+normal*offset).tolist(),material,thickness=.65,group=group)
    for i in range(5):
        copy_curve_handles(part['curves'][i],source_part['curves'][i],(1,2,3))
    for j in range(3):
        copy_curve_handles(part['curves'][5+j],source_part['curves'][6+j],range(5))


def gable(r,name,x,half_width,wall_top,ridge_z,eave_z,roof_half_width,material='wood'):
    grid=[]
    for t in (0,.5,1):
        row=[]
        for y in (-half_width,-half_width*.5,0,half_width*.5,half_width):
            f=abs(y)/roof_half_width
            roof_z=ridge_z+(eave_z-ridge_z)*math.sin(f*math.pi/2)
            row.append((x,y,wall_top+t*(roof_z-wall_top)))
        grid.append(row)
    r.patch(name,grid,material,thickness=2.2,smooth=False)


def roof(r, name, center_x, length, half_width, ridge_z, eave_z,
         material="teal", group=None):
    """Two curved roof slopes; upturned eaves and gable ends are modeled."""
    xs = [center_x + length * f for f in (-.5, -.25, 0, .25, .5)]
    for sign, suffix in ((-1, "Left"), (1, "Right")):
        grid = []
        for i, x in enumerate(xs):
            end_lift = 5.0 * (abs(i - 2) / 2.0) ** 2
            row = []
            for t in (0, .24, .5, .78, 1):
                z = ridge_z + (eave_z - ridge_z) * math.sin(t * math.pi / 2)
                z += 8 * max(0, (t - .78) / .22) ** 2 + end_lift
                row.append((x, sign * half_width * t, z))
            grid.append(row)
        r.patch(name + "_" + suffix, grid, material, thickness=2.1, group=group)
        r.tube(name + "_Eave_" + suffix,
               [(x, sign * half_width, eave_z + 8 + 5 * (abs(i - 2) / 2) ** 2)
                for i, x in enumerate(xs)], 2.4, "brass", group=group)
    r.tube(name + "_Ridge", [(xs[0] - 3, 0, ridge_z + 7),
                             (center_x, 0, ridge_z + 1),
                             (xs[-1] + 3, 0, ridge_z + 7)],
           3.0, "wood", group=group)


def side_window(r, name, x, y, z, width, height, glow="gold_glow"):
    outside = -1 if y < 0 else 1
    r.box(name + "_Glass", (x, y, z), (width, 2.0, height), glow)
    yy = y + outside * 1.6
    points = [(x - width/2, yy, z - height/2),
              (x + width/2, yy, z - height/2),
              (x + width/2, yy, z + height/2),
              (x - width/2, yy, z + height/2)]
    r.tube(name + "_Frame", points, 1.8, "wood", closed=True, smooth=False)
    r.tube(name + "_Mullion", [(x, yy, z-height/2), (x, yy, z+height/2)],
           1.1, "wood", smooth=False)


def arch_door(r, name, x, zbase, width, height):
    # A softly rounded glowing inset behind a separate structural arched frame.
    r.ellipsoid(name + "_Panel", (x + 1, 0, zbase + height/2),
                (2.7, width/2, height/2), "gold_glow", rings=5, sides=12)
    spring = zbase + height - width/2
    pts = [(x - 2, -width/2, zbase), (x - 2, -width/2, spring)]
    pts += [(x-2, -(width/2)*math.cos(a), spring+(width/2)*math.sin(a))
            for a in (math.pi/6, math.pi/3, math.pi/2,
                      2*math.pi/3, 5*math.pi/6, math.pi)]
    pts.append((x-2, width/2, zbase))
    r.tube(name + "_Arch", pts, 3.2, "wood", smooth=True)
    r.tube(name + "_Sill", [(x-2, -width/2, zbase), (x-2, width/2, zbase)],
           2.6, "wood", smooth=False)
    for j, y in enumerate((-width*.23, 0, width*.23)):
        r.tube(name + "_Slat" + str(j+1), [(x-3, y, zbase+4),
                                          (x-3, y, spring+width*.18)],
               1.3, "wood", smooth=False)


def lantern(r, name, center, radius=10, material="gold_glow", anchor=None):
    x, y, z = center
    r.ellipsoid(name + "_Lantern", center, (radius, radius, radius*1.45),
                material, rings=5, sides=8)
    r.cylinder(name + "_Top", (x,y,z+radius*1.25), (x,y,z+radius*1.5),
               radius*.45, "brass")
    r.cylinder(name + "_Bottom", (x,y,z-radius*1.5), (x,y,z-radius*1.25),
               radius*.4, "brass")
    if anchor is not None:
        r.tube(name + "_Cord", [anchor, (x,y,z+radius*1.5)], 1, "wood", smooth=False)


def forest_dreamer():
    r = Recipe(1, "forest_dreamer", "The Forest Dreamer")
    r.mount(pillar_top=190, pillar_x=155, pillar_y=76,
            pillar_radius=12, material="wood", trim="brass")
    body = [(-236,0,282,0,0), (-215,0,286,57,63),
            (-160,0,290,96,103), (-80,0,298,108,107),
            (40,0,294,111,102), (150,0,280,94,91),
            (215,0,270,50,62), (238,0,270,0,0)]
    body_part=r.loft("Body_Lantern_Cage", body, "ivory_glow", sides=12)
    mantle(r, "Moss_Upper_Mantle", body[1:-1], "moss",source_part=body_part)
    head_part=r.ellipsoid("Head_Lantern_Cage", (-215,0,290), (70,83,78),
                         "ivory_glow", rings=7, sides=12)
    head_sections=[]
    for i in range(1,6):
        a=-math.pi/2+i*math.pi/6
        head_sections.append((-215+70*math.sin(a),0,290,
                              83*math.cos(a),78*math.cos(a)))
    mantle(r,"Head_Moss_Mask",head_sections,"moss",source_part=head_part)
    r.sweep("Trunk_Curled_Cage", [(-263,0,274),(-286,0,242),(-300,0,207),
                                 (-299,0,174),(-283,0,163),(-270,0,179)],
            [28,26,23,20,16,10], "ivory_glow", sides=10)
    r.ellipsoid("Trunk_Nostril", (-268,0,181), (4,8,5), "dark", rings=5, sides=8)
    for s, side in ((-1,"Left"),(1,"Right")):
        r.ellipsoid("Eye_"+side, (-264,s*58,306), (8,4,7), "dark", rings=5, sides=8)
        r.tube("Eyelid_"+side, [(-272,s*59,309),(-265,s*62,313),(-255,s*66,309)],
               2.2,"gold_glow")
        ear=r.leaf("Ear_"+side, (-188,s*48,347), (-168,s*96,422), 53,"moss",
                   width_axis=(1,s*.85,0),bend=(-10,0,10),thickness=2.5)
        leaf_ink(r,"Ear_Lit_Vein_"+side,ear,"green_glow",normal_hint=(-1,0,0))
        r.ellipsoid("Foreleg_"+side,(-154,s*87,212),(76,37,27),"moss",rings=6,sides=10)
        r.ellipsoid("Forefoot_"+side,(-211,s*86,203),(34,36,22),"ivory_glow",rings=5,sides=8)
        r.ellipsoid("Haunch_"+side,(162,s*71,231),(59,43,47),"moss",rings=6,sides=10)
        r.ellipsoid("Hindfoot_"+side,(166,s*84,196),(36,31,20),"ivory_glow",rings=5,sides=8)
        for j, yy in enumerate((68,86,104)):
            r.ellipsoid("ForeToe_"+side+str(j),(-236,s*yy,201),(7,6,8),"dark",rings=4,sides=8)
        for j, xx in enumerate((-45,35,106)):
            r.leaf("Side_Light_Leaf_"+side+str(j),(xx,s*106,264),(xx+26,s*110,322),
                   17,"green_glow",width_axis=(1,0,0),bend=(0,s*1,0),thickness=.7)
    r.sweep("Leaf_Tail_Stem",[(209,0,277),(238,0,292),(255,0,280)],[10,7,2],"wood",sides=8)
    for j,yy in enumerate((-16,0,16)):
        r.leaf("Tail_Leaf"+str(j),(232,yy*.25,290),(275,yy,264-j*4),19,"moss",
               width_axis=(0,1,0),bend=(0,0,8),thickness=1)
    # Shrine is supported by the body's back and built with an actual interior volume.
    r.box("Shrine_Saddle",(-18,0,405),(94,88,10),"wood")
    r.box("Shrine_Walls",(-18,0,440),(68,62,60),"wood")
    arch_door(r,"Shrine_Door",-53,413,27,43)
    for s,side in ((-1,"Left"),(1,"Right")):
        side_window(r,"Shrine_Window_"+side,-15,s*32,443,27,30)
        r.box("Shrine_Header_"+side,(-18,s*30,475),(70,7,13),"wood")
    gable(r,"Shrine_Front_Gable",-53,31,470,505,473,57)
    gable(r,"Shrine_Rear_Gable",17,31,470,505,473,57)
    roof(r,"Shrine_Roof",-18,104,57,505,473,"moss")
    r.tube("Shrine_Finial_A",[(-29,0,506),(-7,0,530)],3,"wood",smooth=False)
    r.tube("Shrine_Finial_B",[(-29,0,530),(-7,0,506)],3,"wood",smooth=False)
    r.tube("Seedpod_Branch",[(-35,0,491),(-65,0,510),(-100,0,503),(-119,0,497)],
           4,"wood")
    lantern(r,"Seedpod",(-111,0,459),16,"gold_glow",anchor=(-111,0,503))
    # Three broad fronds, each with a real stem and sparse paired leaves.
    for f,(x,y,z,h) in enumerate(((70,-22,392,101),(94,23,382,102),(127,0,369,91))):
        r.tube("Fern_Stem"+str(f),[(x,y,z),(x+12,y,z+h*.52),(x+26,y,z+h)],
               2.2,"moss")
        for j in range(4):
            t=.25+j*.18
            for side in (-1,1):
                base=(x+26*t,y,z+h*t)
                tip=(base[0]+side*(26-13*t),y+side*9,base[2]+15)
                r.leaf(f"Fern_{f}_{j}_{'L' if side<0 else 'R'}",base,tip,11,
                       "green_glow" if j==3 else "moss",width_axis=(0,1,0),
                       bend=(0,0,3),thickness=.65)
    for i,x in enumerate((-155,155)):
        for j,y in enumerate((-76,76)):
            r.cylinder(f"MushroomStem_{i}_{j}",(x+15,y,16),(x+15,y,30),2.7,"ivory_glow")
            r.ellipsoid(f"MushroomCap_{i}_{j}",(x+15,y,32),(9,9,5),"gold_glow",rings=5,sides=8)
    r.notes.append("Forest tapir's trunk, leaf ears, four folded feet, shrine and three fern fronds are volumetric spline source. Trunk is a tapered sweep cage.")
    return r


def wandering_bathhouse():
    r = Recipe(2,"wandering_bathhouse","The Wandering Bathhouse")
    r.mount(pillar_top=170,pillar_x=180,pillar_y=77,pillar_radius=12,
            material="red_trim",trim="dark")
    hull=[(-257,0,234,0,0),(-229,0,229,64,48),(-180,0,221,101,57),
          (-90,0,218,108,63),(40,0,218,108,63),(150,0,221,102,57),
          (224,0,230,65,49),(254,0,235,0,0)]
    r.loft("Boiler_Hull_Cage",hull,"orange_glow",sides=12)
    for i,(x,ry,rz,zc) in enumerate(((-180,102,58,221),(-90,109,64,218),
                                    (40,109,64,218),(150,103,58,221))):
        r.tube("Hull_Copper_Band"+str(i),ellipse_x(x,0,zc,ry,rz),4,"brass",closed=True)
    r.box("Hull_Rim_Deck",(-7,0,273),(482,224,10),"dark")
    r.box("Main_Timber_House",(-15,0,315),(410,182,80),"wood")
    for s,side in ((-1,"Left"),(1,"Right")):
        for i,x in enumerate((-177,-96,-15,66,147)):
            side_window(r,f"Ground_Window_{side}{i}",x,s*92.5,316,48,43)
        r.tube("Lower_Rail_"+side,[(-222,s*111,283),(197,s*111,283)],2.3,"brass",smooth=False)
        for i,x in enumerate((-222,-117,-12,93,197)):
            r.tube(f"Rail_Post_{side}{i}",[(x,s*111,278),(x,s*111,292)],1.4,"brass",smooth=False)
    arch_door(r,"Front_Entry",-222,279,53,65)
    r.box("Entry_Threshold",(-234,0,280),(28,70,8),"brass")
    roof(r,"Main_Curved_Roof",-15,466,115,410,354,"teal")
    r.box("Upper_House",(-62,0,427),(206,128,68),"wood")
    for s,side in ((-1,"Left"),(1,"Right")):
        for i,x in enumerate((-130,-62,6)):
            side_window(r,f"Upper_Window_{side}{i}",x,s*65.5,429,39,39)
    r.box("Upper_Front_Glow",(-166,0,431),(2.5,88,39),"gold_glow")
    r.tube("Upper_Front_Mullion",[(-168,0,411),(-168,0,451)],1.8,"wood",smooth=False)
    roof(r,"Upper_Curved_Roof",-62,246,83,504,460,"teal")
    # An arching copper exhaust, including a capped top with visible support struts.
    r.sweep("Rear_Copper_Chimney",[(209,0,281),(223,0,323),(231,0,371),
                                  (225,0,424),(207,0,466),(204,0,482)],
            [29,30,27,23,21,21],"brass",sides=10)
    r.tube("Chimney_Rim",ellipse_z(204,0,482,25,25),3.1,"dark",closed=True)
    r.ellipsoid("Chimney_Ember_Opening",(204,0,482),(21,21,2.1),"orange_glow",rings=5,sides=10)
    for i,(xx,yy) in enumerate(((186,0),(222,0),(204,-18),(204,18))):
        r.cylinder("Chimney_Cap_Strut"+str(i),(xx,yy,482),(xx,yy,495),1.8,"brass")
    r.ellipsoid("Chimney_Cap",(204,0,498),(30,30,8),"brass",rings=5,sides=10)
    r.sweep("Small_Exhaust",[(166,65,280),(173,65,344),(170,65,397)],
            [11,10,8],"brass",sides=8)
    r.ellipsoid("Small_Exhaust_Cap",(170,65,401),(14,14,5),"brass",rings=5,sides=8)
    for s,side in ((-1,"Left"),(1,"Right")):
        for i,x in enumerate((-213,-14,185)):
            lantern(r,f"Red_Lantern_{side}{i}",(x,s*105,341),9,"red_glow",
                    anchor=(x,s*105,364))
        lantern(r,"Upper_Lantern_"+side,(-164,s*73,454),8,"red_glow",
                anchor=(-164,s*73,474))
    r.cylinder("Festival_Flagpole",(-201,0,398),(-201,0,553),2.5,"wood")
    flag_grid=[ [(-201+dx,y,z) for dx,y in ((0,0),(20,4),(41,0))]
               for z in (547,526,505)]
    r.patch("Festival_Flag",flag_grid,"red_trim",thickness=.7)
    r.leaf("Flag_Gold_Emblem",(-188,0,516),(-188,0,539),11,"gold_glow",
           width_axis=(1,0,0),bend=(0,-1,0),thickness=.7)
    r.notes.append("Bathhouse has a continuous boiler hull, two roof storeys, ten lower and six upper side windows, a front arched entrance and a copper exhaust. No smoke geometry is baked into the model.")
    return r


def star_lantern(r,name,center,size,anchor):
    x,y,z=center
    r.ellipsoid(name+"_Core",center,(size*.32,)*3,"gold_glow",rings=4,sides=8)
    for i,d in enumerate(((1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(0,0,1),(0,0,-1))):
        pts=[center,tuple(center[k]+d[k]*size*.55 for k in range(3)),
             tuple(center[k]+d[k]*size for k in range(3))]
        r.sweep(name+"_Point"+str(i),pts,[size*.27,size*.2,0],"gold_glow",sides=6)
    r.tube(name+"_Cord",[anchor,(x,y,z+size)],1,"wood",smooth=False)


def moonwhale():
    r=Recipe(3,"moonwhale","The Moonwhale")
    r.mount(pillar_top=180,pillar_x=150,pillar_y=76,pillar_radius=11,
            material="ivory_glow",trim="brass")
    body=[(-269,0,282,0,0),(-248,0,282,57,60),(-193,0,278,104,95),
          (-104,0,272,113,98),(-12,0,264,108,89),(95,0,257,83,65),
          (166,0,270,49,43),(207,0,297,26,25),(226,0,315,0,0)]
    body_part=r.loft("Whale_Body_Lantern_Cage",body,"ivory_glow",sides=14)
    mantle(r,"Whale_Blue_Mantle",body[1:-1],"teal",sides=14,source_part=body_part)
    # Raised rear cradle bridges the narrower tailward belly to the support beam.
    r.box("Rear_Cradle_Riser",(150,0,196),(28,182,32),"wood")
    for x,z,ry in ((-150,191,91),(150,217,48)):
        r.tube("Cradle_Bow_"+("Front" if x<0 else "Rear"),
               [(x,-ry,z+25),(x,-ry*.7,z+7),(x,0,z),(x,ry*.7,z+7),(x,ry,z+25)],
               5,"wood")
    for s,side in ((-1,"Left"),(1,"Right")):
        r.ellipsoid("Eye_"+side,(-222,s*74,302),(9,4.5,10),"dark",rings=5,sides=8)
        r.ellipsoid("Eye_Highlight_"+side,(-224,s*78,305),(2,1.3,2.2),"ivory_glow",rings=4,sides=6)
        group=r.group("ActFin"+side,(-83,s*89,248),axis=(1,0,0),kind="hinge",
                      notes="Optional slow flipper pitch; not a vertical generic truck spinner.")
        fin=r.leaf("Flipper_"+side,(-84,s*88,250),(23,s*204,201),88,"ivory_glow",
                   width_axis=(1,0,.55),bend=(-17,0,10),thickness=2.2,group=group)
        leaf_ink(r,"Flipper_Ink_"+side,fin,"teal",group=group)
        # Broad decorative wave stems use the upper-body surface, with sparse crests.
        for i,(x,yy,zz) in enumerate(((-121,104,301),(-34,104,290),(51,91,280))):
            r.tube(f"Glow_Wave_{side}{i}",[(x-24,s*yy,zz-5),(x-12,s*(yy+2),zz+11),
                                           (x+5,s*(yy+1),zz+17),(x+16,s*yy,zz+8),
                                           (x+7,s*(yy+1),zz+3)],
                   2.3,"cyan_glow")
    r.tube("Mouth_Seam",[(-241,-64,258),(-263,-36,254),(-268,0,252),
                          (-263,36,254),(-241,64,258)],1.8,"brass")
    for i,(x,yc,zc,ry,rz) in enumerate(body[1:7]):
        pts=[(x,yc+(ry+.6)*math.cos(a),zc+(rz+.6)*math.sin(a))
             for a in [math.pi+j*math.pi/8 for j in range(9)]]
        r.tube("Belly_Pleat"+str(i),pts,1.1,"brass")
    tail=r.group("ActTail",(178,0,284),axis=(0,1,0),kind="hinge",
                 notes="Optional slow tail pitch about transverse axis; keep clear of tea pavilion.")
    r.sweep("Tail_Upturned_Peduncle",[(177,0,278),(213,0,312),(239,0,357),(246,0,390)],
            [35,28,18,10],"teal",sides=10,group=tail)
    for s,side in ((-1,"Left"),(1,"Right")):
        fluke=r.leaf("Tail_Fluke_"+side,(240,0,373),(283,s*89,430),79,"ivory_glow",
                    width_axis=(1,0,0),bend=(10,0,-9),thickness=2.1,group=tail)
        leaf_ink(r,"Tail_Fluke_Ink_"+side,fluke,"teal",group=tail)
    for i,(x,yc,zc,ry,rz) in enumerate(((-98,0,272,114,99),(24,0,261,100,82))):
        r.tube("Pavilion_SaddleBand"+str(i),ellipse_x(x,yc,zc,ry,rz,18),5,"red_trim",closed=True)
    for i,x in enumerate((-98,-5)):
        for j,y in enumerate((-33,33)):
            r.cylinder(f"Pavilion_SaddleFoot_{i}_{j}",(x,y,349 if x>-50 else 363),
                       (x,y,376),4,"wood")
    r.box("Tea_Pavilion_Floor",(-51,0,381),(128,101,10),"wood")
    r.box("Tea_Pavilion_Glow_Core",(-51,0,419),(79,68,56),"gold_glow")
    for i,x in enumerate((-94,-8)):
        for j,y in enumerate((-37,37)):
            r.cylinder(f"Pavilion_Column_{i}_{j}",(x,y,386),(x,y,450),3.7,"red_trim")
    for s,side in ((-1,"Left"),(1,"Right")):
        r.box("Pavilion_Roof_Header_"+side,(-51,s*37,453),(96,7,10),"red_trim")
        r.tube("Pavilion_Balustrade_"+side,[(-111,s*47,401),(10,s*47,401)],2,"red_trim",smooth=False)
        for i,x in enumerate((-104,-74,-44,-14,6)):
            r.tube(f"Pavilion_RailPost_{side}{i}",[(x,s*47,386),(x,s*47,404)],1.1,"red_trim",smooth=False)
    r.box("Pavilion_Front_Crossbar",(-95,0,433),(3,80,4),"wood")
    r.tube("Pavilion_Door_Mullion",[(-96,0,388),(-96,0,447)],1.6,"wood",smooth=False)
    roof(r,"Tea_Pavilion_Roof",-51,150,65,491,448,"red_trim")
    r.sweep("Pavilion_Finial",[(-51,0,492),(-51,0,507),(-51,0,516)],[6,3,0],"brass",sides=8)
    for s,side in ((-1,"Left"),(1,"Right")):
        lantern(r,"Pavilion_Lantern_"+side,(-105,s*55,437),7,"gold_glow",
                anchor=(-105,s*55,460))
        for i,(x,yy,zz) in enumerate(((-39,152,156),(29,178,145))):
            star_lantern(r,f"Star_{side}{i}",(x,s*yy,zz),13,
                         anchor=(x,s*yy,213))
    r.notes.append("Whale fins and tail have separate Act helpers for transverse-axis motion; they are not height-axis Spin groups. Four Moravian-style volumetric star lanterns remain fixed under the flippers.")
    return r


def build():
    return [forest_dreamer(),wandering_bathhouse(),moonwhale()]


if __name__ == "__main__":
    out=Path(__file__).resolve().parent
    for recipe in build():
        dest=recipe.save(out/f"{recipe.index:02d}_{recipe.slug}.json")
        print(f"{recipe.title}: {len(recipe.parts)} spline parts -> {dest}")
