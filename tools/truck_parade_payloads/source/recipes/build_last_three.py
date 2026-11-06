"""Lantern Koi, Cloud Mill and Night Post editable spline-cage recipes.

All visible solids are connected spline networks.  Thin fins, sails and wings
are open quad networks closed by the shared live Shell modifier.  The recipes
remain in a single coordinate system: front -X, width Y, up Z.
"""
from __future__ import annotations

import math
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from authoring import Recipe

TAU = 2.0 * math.pi


def v(p):
    return np.asarray(p, dtype=float)


def ellipse(center, a, b, count=12):
    c, a, b = v(center), v(a), v(b)
    return [c + a * math.cos(t) + b * math.sin(t)
            for t in np.arange(count) * TAU / count]


def leaf_point(base, tip, width, axis, bend, t, lateral):
    a, b = v(base), v(tip)
    d = b - a
    d /= np.linalg.norm(d)
    w = v(axis) - d * np.dot(v(axis), d)
    w /= np.linalg.norm(w)
    extent = width * (0.035 + 0.965 * math.sin(math.pi * t)) / 2.0
    return a + (b-a)*t + v(bend)*math.sin(math.pi*t) + w*extent*lateral


def leaf_with_ribs(r, name, base, tip, width, material, axis=(0,1,0),
                   bend=(0,0,0), border="brass", ribs=3, group=None):
    r.leaf(name, base, tip, width, material, width_axis=axis, bend=bend,
           thickness=0.9, group=group)
    ts = np.linspace(0.0, 1.0, 7)
    perimeter = [leaf_point(base,tip,width,axis,bend,t,-1) for t in ts]
    perimeter += [leaf_point(base,tip,width,axis,bend,t,1) for t in ts[::-1]]
    r.tube(name+"_Edge",perimeter,0.9,border,closed=True,sides=4,group=group)
    for i,s in enumerate(np.linspace(-0.65,0.65,ribs)):
        pts=[leaf_point(base,tip,width,axis,bend,t,s)*1.0 for t in ts]
        r.tube(name+f"_Rib{i+1}",pts,0.65,"brass",sides=4,group=group)


def loft_colour_patch(r,name,sections,xrange,trange,material,wave=0.0):
    """A coloured panel follows the body's actual elliptical sections."""
    arr=np.asarray(sections,float)
    rows=[]
    for t in np.linspace(0,1,5):
        x=xrange[0]+t*(xrange[1]-xrange[0])
        yc,zc,ry,rz=[np.interp(x,arr[:,0],arr[:,i]) for i in (1,2,3,4)]
        offset=wave*math.sin(t*math.pi*2)
        rows.append([[x,yc+(ry+3.7)*math.cos(a+offset),zc+(rz+3.7)*math.sin(a+offset)]
                     for a in np.linspace(trange[0],trange[1],5)])
    r.patch(name,rows,material,thickness=0.45)


def matching_loft_panel(r,name,sections,body_part,xrange,angle_indices,material,sides=24):
    """Copy a rectangular subset of the underlying cage's exact knot lattice.

    Independent angle samples cut through a faceted source loft.  Here every
    panel row and column matches a body row/column.  Absolute Bezier handles
    come from those exact source curves, including their off-panel neighbours.
    The open strip therefore retains the source's boundary tangents when the
    user raises Surface steps. A 1.8-unit offset clears the 0.45-unit shell.
    """
    def copy_curve_handles(target,source,indices):
        points=np.asarray(source['points'],float)
        incoming=[];outgoing=[]
        for point,j in zip(target['points'],indices):
            if source['closed']:
                tangent=(points[(j+1)%len(points)]-points[(j-1)%len(points)])/6
            elif j==0:
                tangent=(points[1]-points[0])/3
            elif j==len(points)-1:
                tangent=(points[-1]-points[-2])/3
            else:
                tangent=(points[j+1]-points[j-1])/6
            incoming.append((np.asarray(point)-tangent).round(6).tolist())
            outgoing.append((np.asarray(point)+tangent).round(6).tolist())
        target['in_handles']=incoming
        target['out_handles']=outgoing
    rows=[]
    selected_rows=[]
    angles=list(angle_indices)
    for source_i,(x,yc,zc,ry,rz) in enumerate(sections):
        if xrange[0]-1e-6<=x<=xrange[1]+1e-6:
            selected_rows.append(source_i)
            rows.append([[x,yc+(ry+1.8)*math.cos(j*TAU/sides),
                          zc+(rz+1.8)*math.sin(j*TAU/sides)] for j in angles])
    if len(rows)<3:
        raise ValueError("Colour panel needs at least three matching loft rows")
    part=r.patch(name,rows,material,thickness=0.45)
    # Source cages have one ring per non-pole row, followed by all rails.
    ring_count=len(sections)-2
    for i,source_i in enumerate(selected_rows):
        copy_curve_handles(part['curves'][i],body_part['curves'][source_i-1],
                           [j%sides for j in angles])
    for j,angle_j in enumerate(angles):
        copy_curve_handles(part['curves'][len(rows)+j],
                           body_part['curves'][ring_count+angle_j%sides],selected_rows)


def side_window(r,name,x,y,z,width=25,height=30,frame="wood",group=None):
    r.box(name+"_Frame",(x,y,z),(width+6,3.2,height+6),frame,group=group)
    r.box(name+"_Pane",(x,y+(1.9 if y>0 else -1.9),z),(width,1.4,height),"gold_glow",group=group)
    r.box(name+"_Mullion",(x,y+(2.8 if y>0 else -2.8),z),(2.3,1.3,height),frame,group=group)


def lantern_koi():
    r=Recipe(4,"lantern_koi","The Lantern Koi")
    r.notes += ["Cream lantern body and vermilion overlays use real emissive Asian-atlas patches.",
                "Tail, fins, lips, whiskers, lotus petals and saddle supports remain separate spline objects."]
    r.mount(pillar_top=220,pillar_x=170,pillar_y=79,pillar_radius=13,
            material="teal",trim="brass")
    base_sections=[[-262,0,295,0,0],[-244,0,297,40,36],[-220,0,305,72,64],
              [-170,0,310,99,90],[-90,0,316,109,99],[10,0,315,103,96],
              [100,0,312,90,92],[170,0,310,67,90],[218,0,318,31,40],
              [249,0,329,18,23],[260,0,332,0,0]]
    source=np.asarray(base_sections,float)
    # Insert the material-panel boundary rows BEFORE building the body.  The
    # body and its decorative panels therefore use identical physical knots.
    xs=sorted(set(source[:,0])|{-230,-200,-150,-105,-70,-30,65,120,145,-40,20,90})
    sections=[[x]+[float(np.interp(x,source[:,0],source[:,k])) for k in (1,2,3,4)] for x in xs]
    body_part=r.loft("Koi_LanternBody",sections,"ivory_glow",sides=24)
    matching_loft_panel(r,"Koi_RedCrown",sections,body_part,(-230,-150),range(2,11),"red_glow")
    matching_loft_panel(r,"Koi_RedBack",sections,body_part,(-105,-30),range(1,12),"orange_glow")
    matching_loft_panel(r,"Koi_RedHaunch",sections,body_part,(65,145),range(2,11),"red_glow")
    for sign in (-1,1):
        angles=range(-1,2) if sign==1 else range(11,14)
        matching_loft_panel(r,f"Koi_SideMark_{sign+2}",sections,body_part,(-40,90),angles,"blue_glow")
    # An open forward mouth with an actual surrounding lip, never a drawn decal.
    r.ellipsoid("Mouth_Interior",(-262.5,0,295),(3,26,18),"dark",rings=5,sides=10)
    r.tube("Mouth_RoundedLip",ellipse((-266,0,295),(0,28,0),(0,0,20)),4.2,"gold_glow",closed=True,sides=6)
    for sign in (-1,1):
        s=str(sign+2)
        r.ellipsoid("Eye_Rim_"+s,(-216,sign*64,330),(14,7,14),"brass",rings=5,sides=10)
        r.ellipsoid("Eye_Black_"+s,(-217,sign*70,331),(10,4,10),"dark",rings=5,sides=10)
        r.ellipsoid("Eye_Glint_"+s,(-222,sign*73,335),(2.5,1.4,2.5),"ivory_glow",rings=4,sides=8)
        whisk=[(-264,sign*21,288),(-279,sign*35,275),(-288,sign*50,251),(-307,sign*61,245),(-316,sign*59,252)]
        r.sweep("Whisker_"+s,whisk,[3.7,3.1,2.2,1.2,0],"gold_glow",sides=6)
        gill=[(-179,sign*82,353),(-171,sign*96,326),(-170,sign*94,296),(-178,sign*83,275)]
        r.tube("GillFold_"+s,gill,1.4,"brass",sides=4)
        leaf_with_ribs(r,"PectoralFin_"+s,(-137,sign*77,270),(1,sign*168,244),95,
                       "gold_glow",axis=(1,0,0),bend=(-14,sign*12,-17),ribs=3)
    leaf_with_ribs(r,"DorsalFan",(-43,0,411),(70,0,480),97,"gold_glow",
                   axis=(-0.52,0,0.85),bend=(14,0,8),ribs=3)
    leaf_with_ribs(r,"TailUpper",(242,0,333),(348,0,450),106,"gold_glow",
                   axis=(-0.75,0,0.66),bend=(10,0,17),ribs=3)
    leaf_with_ribs(r,"TailLower",(245,0,329),(344,0,238),99,"orange_glow",
                   axis=(0.68,0,0.73),bend=(11,0,-10),ribs=3)
    # Saddle contacts follow the body section, while pedestal rails meet beams.
    for i,x in enumerate((-170,170)):
        ry=99 if x<0 else 67
        arc=[(x,y,310-90*math.sqrt(max(0,1-(y/ry)**2))-1.4)
             for y in np.linspace(-ry*0.92,ry*0.92,9)]
        r.tube(f"BodyCradle_{i+1}",arc,4.5,"brass",sides=6)
    # Three large lotus blooms share one shallow physical tray.
    r.box("LotusTray",(-77,0,418),(136,104,8),"teal")
    r.box("LotusTray_Rim",(-77,0,424),(141,109,5),"brass")
    r.box("LotusTray_Inset",(-77,0,427),(129,97,4),"moss")
    for i,(cx,cy,cz) in enumerate(((-109,-24,444),(-68,19,453),(-39,-28,440))):
        r.cylinder(f"Lotus_{i+1}_Stem",(cx,cy,428),(cx,cy,cz),2,"moss",sides=6)
        r.ellipsoid(f"Lotus_{i+1}_Heart",(cx,cy,cz+6),(11,11,7),"gold_glow",rings=5,sides=8)
        for j,t in enumerate(np.arange(6)*TAU/6):
            base=(cx+3*math.cos(t),cy+3*math.sin(t),cz)
            tip=(cx+23*math.cos(t),cy+23*math.sin(t),cz+28)
            axis=(-math.sin(t),math.cos(t),0)
            r.leaf(f"Lotus_{i+1}_Petal{j+1}",base,tip,20,"pink_glow",width_axis=axis,
                   bend=(4*math.cos(t),4*math.sin(t),-3),thickness=0.7)
    for i,(cx,cy) in enumerate(((-120,26),(-54,40),(-27,12))):
        r.leaf(f"LilyPad_{i+1}",(cx-12,cy,429),(cx+14,cy+2,432),36,"moss",
               width_axis=(0,1,0),bend=(0,0,3))
    # Narrow visible panel seams provide a readable cage-like lantern surface.
    for i,x in enumerate((-190,-130,20,88,180)):
        yc,zc,ry,rz=[np.interp(x,np.array(sections)[:,0],np.array(sections)[:,k]) for k in (1,2,3,4)]
        r.tube(f"LanternPanelSeam_{i+1}",ellipse((x,yc,zc),(0,ry+0.9,0),(0,0,rz+0.9),16),
               0.7,"brass",closed=True,sides=4)
    return r


def cloud_mill():
    r=Recipe(5,"cloud_mill","The Cloud Mill")
    r.notes += ["Fleece is formed from broad editable lantern lobes; horns are tapered swept spline cages.",
                "WindmillRotor uses a horizontal -X axis and an Act helper, never the vertical runtime Spin convention."]
    r.mount(pillar_top=214,pillar_x=180,pillar_y=77,pillar_radius=13,
            material="dark",trim="brass")
    body=[[-238,0,285,0,0],[-210,0,287,62,72],[-180,0,300,95,86],[-85,0,310,109,100],
          [30,0,310,113,100],[125,0,305,104,92],[180,0,300,92,86],[225,0,284,57,69],[247,0,280,0,0]]
    r.loft("Ram_CoreLantern",body,"ivory_glow",sides=12)
    lobes=[(-154,0,360,71,75,70),(-93,-66,345,70,57,65),(-93,66,345,70,57,65),
           (-6,-82,331,76,49,76),(-6,82,331,76,49,76),(83,-70,344,72,59,66),
           (83,70,344,72,59,66),(157,0,346,76,78,67),(194,-53,281,62,50,67),
           (194,53,281,62,50,67),(-174,-63,276,63,51,62),(-174,63,276,63,51,62)]
    for i,(x,y,z,rx,ry,rz) in enumerate(lobes):
        r.ellipsoid(f"FleeceCloud_{i+1:02d}",(x,y,z),(rx,ry,rz),"ivory_glow",rings=6,sides=10)
        if abs(y)>45 and i%2==0:
            sign=1 if y>0 else -1
            pts=[]
            for t in np.linspace(0,math.pi*1.5,9):
                rr=20*(1-t/(math.pi*2.1))
                pts.append((x+rr*math.cos(t),y+sign*(ry-1),z+rr*math.sin(t)))
            r.tube(f"FleeceScroll_{i+1:02d}",pts,1.8,"violet_glow",sides=4)
    r.ellipsoid("Ram_Head",(-220,0,321),(64,56,51),"ivory_glow",rings=7,sides=12)
    r.ellipsoid("Ram_Muzzle",(-268,0,300),(32,41,30),"ivory_glow",rings=6,sides=10)
    r.ellipsoid("Ram_Nose",(-296,0,308),(5,12,7),"dark",rings=5,sides=8)
    for sign in (-1,1):
        s=str(sign+2)
        r.leaf("Ear_"+s,(-218,sign*45,350),(-200,sign*91,347),31,"pink_glow",
               width_axis=(1,0,0),bend=(-4,sign*2,6),thickness=1.5)
        r.tube("ClosedEye_"+s,[(-284,sign*12,332),(-277,sign*25,329),(-265,sign*39,332)],
               1.8,"dark",sides=5)
        r.tube("Smile_"+s,[(-301,0,299),(-299,sign*12,293),(-294,sign*21,297)],1.2,"dark",sides=4)
        pts=[]
        radii=[]
        for t in np.linspace(0,1,20):
            angle=t*TAU*1.05
            rr=64*(1-0.77*t)
            # Tilt each spiral outward: it stays recognisable from both the
            # side and front rather than presenting an edge-on disc in front.
            pts.append((-211+0.70*rr*math.cos(angle),
                        sign*(78-0.72*rr*math.cos(angle)+10*t),362+rr*math.sin(angle)))
            radii.append(24*(1-t)**0.65+1.2)
        radii[-1]=0
        r.sweep("SpiralHorn_"+s,pts,radii,"gold_glow",sides=8)
        for j,x in enumerate((-161,176)):
            r.ellipsoid(f"TuckedHoof_{s}_{j+1}",(x,sign*62,225),(43,25,12),"ivory_glow",rings=5,sides=10)
    # Visible curled tail made as a tapered continuous cage.
    tailpts=[]
    for t in np.linspace(0,math.pi*1.5,9):
        rr=22*(1-0.65*t/(math.pi*1.5))
        tailpts.append((236+rr*math.cos(t),0,320+rr*math.sin(t)))
    r.sweep("CloudTail",tailpts,[9,9,8,7,6,5,4,2,0],"ivory_glow",sides=6)
    # Carpet slopes down either flank, rather than floating above the body.
    carpet=[]
    for x in (-66,-31,4,39,74):
        carpet.append([(x,y,423-0.0055*y*y) for y in (-88,-44,0,44,88)])
    r.patch("Windmill_Carpet",carpet,"red_trim",thickness=2.4)
    for sign in (-1,1):
        r.tube(f"CarpetBorder_{sign+2}",[(x,sign*89,380.5) for x in (-66,-31,4,39,74)],
               2.0,"brass",smooth=False,sides=5)
        for i,x in enumerate((-58,-18,22,62)):
            r.tube(f"CarpetTassel_{sign+2}_{i+1}",[(x,sign*89,380),(x,sign*93,365)],
                   2,"gold_glow",smooth=False,sides=5)
    # A short solid saddle reaches the ram's back beneath the hanging carpet.
    r.box("Windmill_SaddleBlock",(7,0,414),(108,79,22),"wood")
    r.box("Windmill_Deck",(7,0,427),(129,107,9),"wood")
    r.box("Windmill_Tower",(10,0,485),(68,65,112),"wood")
    for sign in (-1,1):
        side_window(r,f"WindmillWindow_{sign+2}",10,sign*34,487,27,39)
        r.box(f"TowerCornerA_{sign+2}",(-24,sign*33,484),(5,5,116),"brass")
        r.box(f"TowerCornerB_{sign+2}",(44,sign*33,484),(5,5,116),"brass")
    r.sweep("Windmill_Roof",[(10,0,539),(10,0,551),(10,0,581),(10,0,591)],
            [54,47,9,0],"red_trim",sides=8)
    r.tube("Windmill_RoofEave",ellipse((10,0,539),(54,0,0),(0,54,0),8),2.2,"brass",closed=True,sides=4)
    pivot=(-34,0,535)
    rotor=r.group("WindmillRotor",pivot,axis=(-1,0,0),kind="hinge",
                  notes="Four face-on sails; rotate around local rotor axis. Keep separate from vertical spinners.")
    r.cylinder("Rotor_Hub",(-28,0,535),(-48,0,535),12,"brass",sides=8,group=rotor)
    for i,a in enumerate(np.arange(4)*math.pi/2+math.pi/4):
        radial=v((0,math.cos(a),math.sin(a)))
        tangent=v((0,-math.sin(a),math.cos(a)))
        def sail(rad,frac):
            return v(pivot)+radial*rad+tangent*(7+0.17*rad)*frac+v((-9-2*frac,0,0))
        grid=[[sail(rad,f) for f in (-1,0,1)] for rad in (22,62,105)]
        r.patch(f"Rotor_Sail{i+1}",grid,"ivory_glow",thickness=1.2,smooth=False,group=rotor)
        r.tube(f"Rotor_Spar{i+1}",[v(pivot)+v((-12,0,0)),sail(107,0)],2.4,"wood",sides=5,group=rotor)
        border=[sail(22,-1),sail(105,-1),sail(105,1),sail(22,1)]
        r.tube(f"Rotor_Frame{i+1}",border,1.7,"wood",closed=True,smooth=False,sides=4,group=rotor)
    r.cylinder("Pennant_Mast",(10,0,584),(10,0,625),1.9,"wood",sides=6)
    r.patch("Pennant",[[[10+u,0.7*math.sin(u/10+t),621-10*t]
                        for u in (0,22,46)] for t in (0,0.5,1)],"red_trim",thickness=0.65)
    return r


def night_post():
    r=Recipe(6,"night_post","The Night Post")
    r.notes += ["Four independently editable wing membranes retain connected quad spline cages and live thickness.",
                "Forewing and hindwing helpers carry explicit lengthwise hinge axes; no animation is baked."]
    r.mount(pillar_top=215,pillar_x=160,pillar_y=70,pillar_radius=12,
            material="wood",trim="brass")
    body=[[-215,0,291,0,0],[-184,0,300,66,80],[-160,0,302,76,87],[-100,0,301,79,86],
          [-15,0,296,86,82],[65,0,294,85,80],[160,0,292,67,77],[235,0,293,37,47],[275,0,297,0,0]]
    r.loft("Moth_LanternAbdomen",body,"ivory_glow",sides=12)
    for i,x in enumerate((-5,85,176)):
        yc,zc,ry,rz=[np.interp(x,np.array(body)[:,0],np.array(body)[:,k]) for k in (1,2,3,4)]
        # Narrow bands lie on the existing shell and preserve its form.
        loft_colour_patch(r,f"AbdomenBand_{i+1}",body,(x-7,x+7),(0.02,TAU-0.02),"wood")
        r.tube(f"AbdomenBandEdge_{i+1}",ellipse((x-8,0,zc),(0,ry+1.6,0),(0,0,rz+1.6),12),
               0.75,"brass",closed=True,sides=4)
    r.ellipsoid("Moth_FurRuff",(-181,0,309),(48,85,85),"gold_glow",rings=6,sides=12)
    r.ellipsoid("Moth_Head",(-228,0,310),(61,63,61),"ivory_glow",rings=7,sides=12)
    for sign in (-1,1):
        s=str(sign+2)
        r.ellipsoid("Eye_Rim_"+s,(-268,sign*31,323),(11,20,24),"brass",rings=6,sides=10)
        r.ellipsoid("Eye_Lens_"+s,(-276,sign*31,324),(7,16,20),"dark",rings=6,sides=10)
        r.ellipsoid("Eye_Glint_"+s,(-282,sign*27,333),(1.9,4,4),"ivory_glow",rings=4,sides=8)
        r.tube("Smile_"+s,[(-290,0,289),(-289,sign*11,291),(-287,sign*20,296)],1.2,"dark",sides=4)
        ant=[(-235,sign*30,355),(-231,sign*42,392),(-222,sign*64,431),(-213,sign*95,468)]
        r.sweep("AntennaStem_"+s,ant,[3.3,2.8,1.9,0],"gold_glow",sides=6)
        for j,t in enumerate(np.linspace(0.2,0.89,7)):
            pos=v(ant[0])*(1-t)+v(ant[-1])*t+v((-4*math.sin(math.pi*t),0,0))
            reach=21*(math.sin(t*math.pi)**0.5)
            pts=[pos+v((12,sign*(-6),-3)),pos,pos+v((-12,sign*reach,12))]
            r.tube(f"AntennaFeather_{s}_{j+1}",pts,0.8,"gold_glow",sides=4)
    # Separate wing assemblies permit future flapping without affecting the cage.
    for sign in (-1,1):
        s=str(sign+2)
        wing_specs=[("Forewing",(-105,sign*65,332),(-12,sign*239,513),181,(1,sign*0.55,-1.08),(29,sign*9,-5)),
                    ("Hindwing",(-34,sign*67,306),(160,sign*195,382),130,(0,0,1),(10,sign*14,9))]
        for label,base,tip,width,axis,bend in wing_specs:
            group=r.group(label+s,base,axis=(1,0,0),kind="hinge",notes="Keep this complete wing assembly together for a future gentle flap.")
            leaf_with_ribs(r,label+"_"+s,base,tip,width,"gold_glow",axis=axis,bend=bend,
                           border="violet_glow",ribs=3,group=group)
            # Oval eye-spot follows the same curved wing parameterisation.
            center_u=0.66 if label=="Forewing" else 0.61
            ring=[]
            span=v(tip)-v(base)
            span=span/np.linalg.norm(span)
            lateral=v(axis)-span*np.dot(v(axis),span)
            lateral=lateral/np.linalg.norm(lateral)
            normal=np.cross(span,lateral)
            for a in np.arange(14)*TAU/14:
                pt=leaf_point(base,tip,width,axis,bend,center_u+0.11*math.cos(a),0.33*math.sin(a))
                ring.append(pt)
            for face_sign in (-1,1):
                r.tube(label+"_Eyespot_"+s+"_"+str(face_sign+2),
                       [pt+normal*face_sign*2.6 for pt in ring],3.8,"blue_glow",closed=True,sides=5,group=group)
            spot=leaf_point(base,tip,width,axis,bend,center_u,0)+v((-1.2,0,0))
            r.ellipsoid(label+"_EyeDot_"+s,spot,(3.6,5.0,5.0),"ivory_glow",rings=4,sides=8,group=group)
    # The mail cabin is a compact wooden compartment between the forewings.
    r.box("MailCabin",(-101,0,381),(90,93,112),"wood")
    r.box("Cabin_Floor",(-101,0,329),(103,103,9),"brass")
    for sign in (-1,1):
        s=str(sign+2)
        for j,x in enumerate((-125,-78)):
            side_window(r,f"CabinWindow_{s}_{j+1}",x,sign*48,400,28,34)
        for j,x in enumerate((-147,-55)):
            r.box(f"CabinCorner_{s}_{j+1}",(x,sign*47,381),(5,5,116),"brass")
        r.box("EnvelopePlate_"+s,(-102,sign*50,356),(41,3.5,25),"brass")
        r.box("EnvelopeInset_"+s,(-102,sign*52.2,356),(36,1.6,20),"wood")
        y=sign*53.5
        r.tube("EnvelopeFold_"+s,[(-119,y,364),(-102,y,353),(-85,y,364)],1.2,"gold_glow",smooth=False,sides=4)
    for sign in (-1,1):
        grid=[]
        for x in (-159,-130,-100,-70,-43):
            grid.append([(x,sign*y,z+(3 if abs(x+101)>52 else 0))
                         for y,z in ((0,461),(22,451),(43,440),(63,443))])
        r.patch(f"MailCabin_Roof_{sign+2}",grid,"red_trim",thickness=2.1)
        r.tube(f"RoofEave_{sign+2}",[(-159,sign*63,446),(-100,sign*63,443),(-43,sign*63,446)],
               2,"brass",sides=5)
    r.tube("RoofRidge",[(-159,0,464),(-101,0,461),(-43,0,464)],2.5,"brass",sides=5)
    r.cylinder("RoofFinial",(-101,0,461),(-101,0,480),2.2,"brass",sides=6)
    r.ellipsoid("RoofFinialBead",(-101,0,478),(5,5,7),"gold_glow",rings=5,sides=8)
    # Mail sacks are fixed below the cabin, clear of the pillar saddles.
    for i,(x,y) in enumerate(((-129,-68),(-91,-70),(-111,69))):
        r.ellipsoid(f"Mailbag_{i+1}",(x,y,274),(16,12,22),"red_trim" if i!=1 else "teal",rings=6,sides=8)
        r.box(f"MailbagFlap_{i+1}",(x,y+(9 if y>0 else -9),282),(25,5,16),"wood")
        r.ellipsoid(f"MailbagClasp_{i+1}",(x,y+(13 if y>0 else -13),278),(3,1.4,3),"brass",rings=4,sides=8)
        r.tube(f"MailbagStrap_{i+1}",[(x-8,y,290),(x-8,y,320),(x+8,y,320),(x+8,y,290)],1.6,"wood",sides=4)
    # Saddle shims connect the central underside at both support stations.
    for i,x in enumerate((-160,160)):
        zc=np.interp(x,np.array(body)[:,0],np.array(body)[:,2])
        rz=np.interp(x,np.array(body)[:,0],np.array(body)[:,4])
        low=zc-rz
        if low>215.1:
            r.box(f"SaddleShim_{i+1}",(x,0,(215+low)/2),(29,48,low-215+1),"wood")
    return r


def build():
    return [lantern_koi(),cloud_mill(),night_post()]


if __name__=="__main__":
    out=Path(__file__).resolve().parent
    for recipe in build():
        target=out/f"{recipe.index:02d}_{recipe.slug}.json"
        recipe.save(target)
        print(f"{target.name}: {len(recipe.parts)} editable parts; {len(recipe.groups)} motion groups")
