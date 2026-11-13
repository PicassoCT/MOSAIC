"""Editable spline cages for the parade's small ceremonial projections.

Source coordinates are X right, Y depth, Z up, with front toward -Y.
All dimensions are game-world units; the exporter performs a proper rotation.
"""
from __future__ import annotations

import math
import numpy as np
from authoring import Recipe


def vertical(r, name, sections, material, sides=12):
    rings, centers = [], []
    for z, rx, ry in sections:
        centers.append((0, 0, z))
        rings.append([(0, 0, z)] if rx == ry == 0 else
                     [(rx * math.cos(t), ry * math.sin(t), z)
                      for t in np.arange(sides) * 2 * math.pi / sides])
    return r._section_cage(name, rings, centers, material)


def finish(r, cell=.16):
    result = r.to_dict()
    result.update(category="prop", variant=1, cell_size=cell,
                  coordinate_system="X right, Y depth, Z up; front -Y",
                  prop_key=r.slug.removeprefix("parade"))
    return result


def build():
    result = []
    r = Recipe(1, "paradecandle", "Ground candle")
    r.cylinder("Holder", (0, 0, .05), (0, 0, .23), .53, "gold_glow", sides=12)
    r.cylinder("Wax", (0, 0, .23), (0, 0, 1.45), .31, "ivory_glow", sides=12)
    r.cylinder("Wick", (0, 0, 1.42), (0, 0, 1.62), .055, "dark")
    vertical(r, "Flame", [(1.48, 0, 0), (1.64, .22, .18),
                          (1.93, .15, .12), (2.24, 0, 0)], "gold_glow")
    r.ellipsoid("FlameHeart", (0, -.14, 1.7), (.10, .09, .18), "ivory_glow")
    result.append(finish(r, .13))

    r = Recipe(2, "paradelantern", "Floating paper lantern")
    r.ellipsoid("PaperShell", (0, 0, 2.0), (1.02, .77, 1.05), "gold_glow")
    r.cylinder("BottomRim", (0, 0, .90), (0, 0, 1.07), .62, "dark", sides=12)
    r.cylinder("TopRim", (0, 0, 2.92), (0, 0, 3.08), .64, "dark", sides=12)
    for i in range(6):
        a = i * math.pi / 3
        p = [(math.cos(a)*1.03*math.sin(t), math.sin(a)*.78*math.sin(t),
              2.0 + 1.05*math.cos(t)) for t in np.linspace(.40, math.pi-.40, 7)]
        r.tube("PaperRib%d" % i, p, .045, "ivory_glow", sides=4)
    r.tube("Tassel", [(0, 0, .98), (.07, 0, .65), (-.07, 0, .34), (0, 0, .02)],
           .08, "gold_glow", sides=5)
    result.append(finish(r, .17))

    r = Recipe(3, "parademoon", "Flying crescent moon")
    angles = np.linspace(math.pi/3, 5*math.pi/3, 13)
    points = [(1.9*math.cos(a), 0, 2.5+2.0*math.sin(a)) for a in angles]
    radii = [.68*math.sin(i*math.pi/12)**.75 for i in range(13)]
    radii[0] = radii[-1] = 0
    r.sweep("Crescent", points, radii, "ivory_glow", sides=10)
    result.append(finish(r, .19))

    r = Recipe(4, "paradeenvelope", "Flying folded envelope")
    r.box("Paper", (0, 0, 1.15), (3.6, .24, 2.25), "ivory_glow")
    r.tube("Fold", [(-1.72,-.19,2.20),(0,-.21,1.12),(1.72,-.19,2.20)],
           .075, "dark", smooth=False, sides=4)
    r.tube("LowerFold", [(-1.72,-.19,.10),(0,-.21,1.12),(1.72,-.19,.10)],
           .06, "gold_glow", smooth=False, sides=4)
    r.ellipsoid("Seal", (0,-.24,1.12), (.24,.11,.24), "red_glow")
    result.append(finish(r, .15))

    r = Recipe(5, "parademoney", "Flying hyperinflation banknote")
    grid = [[(x, .12*math.sin(x*math.pi/2.2), z) for x in np.linspace(-2.2,2.2,9)]
            for z in np.linspace(.05,2.25,5)]
    r.patch("Banknote", grid, "green_glow", thickness=.18)
    r.tube("Border", [(-2.03,-.21,.23),(2.03,-.21,.23),(2.03,-.21,2.06),
                      (-2.03,-.21,2.06)], .065, "gold_glow", closed=True,
           smooth=False, sides=4)
    r.box("LeadingOne", (-1.62,-.27,1.17), (.12,.14,.75), "dark")
    for i in range(6):
        x = -1.18+i*.51
        p = [(x+.17*math.cos(a),-.28,1.17+.34*math.sin(a))
             for a in np.arange(8)*math.pi/4]
        r.tube("Zero%d" % i, p, .065, "dark", closed=True, smooth=False, sides=4)
    result.append(finish(r, .13))

    r = Recipe(6, "paradekoi", "Flying lantern koi")
    r.ellipsoid("Body", (0,0,1.1), (1.62,.48,.61), "ivory_glow")
    r.ellipsoid("HeadPatch", (.97,0,1.27), (.46,.51,.46), "orange_glow")
    r.ellipsoid("BackPatch", (-.55,0,1.46), (.50,.40,.28), "orange_glow")
    for i, dz in enumerate((-.75,.75)):
        r.leaf("Tail%d" % i, (-1.3,0,1.1), (-2.55,0,1.1+dz), .83,
               "orange_glow", width_axis=(0,0,1), bend=(0,.07,0), thickness=.18)
    for i, side in enumerate((-1,1)):
        r.leaf("Fin%d" % i, (.3,side*.31,1.0), (-.60,side*1.03,.62), .65,
               "ivory_glow", width_axis=(1,0,0), thickness=.18)
        r.ellipsoid("Eye%d" % i, (1.30,side*.39,1.23), (.105,.09,.105), "dark")
    result.append(finish(r, .15))

    r = Recipe(7, "paradelotus", "Flying lotus blossom")
    for tier in range(2):
        for i in range(6):
            a = i*math.pi/3+tier*math.pi/6
            radius = 1.65-tier*.6
            r.leaf("Petal%d_%d" % (tier,i), (0,0,.20+tier*.20),
                   (radius*math.cos(a),radius*math.sin(a),.77+tier*.84),
                   1.07-tier*.24, "pink_glow" if not tier else "ivory_glow",
                   width_axis=(-math.sin(a),math.cos(a),0), bend=(0,0,.60), thickness=.18)
    r.ellipsoid("Heart", (0,0,.77), (.45,.45,.30), "gold_glow")
    result.append(finish(r, .15))

    r = Recipe(8, "paradeleaf", "Flying leaf")
    r.leaf("Blade", (0,0,.16), (.55,0,3.0), 1.55, "green_glow",
           width_axis=(1,0,0), bend=(0,.18,0), thickness=.16)
    r.tube("Vein", [(0,-.13,.03),(.08,-.13,.73),(.27,-.13,1.53),(.55,-.13,2.94)],
           .06, "gold_glow", sides=4)
    for i in range(3):
        z=.65+i*.52
        for side in (-1,1):
            r.tube("Branch%d_%s" % (i,"L" if side<0 else "R"),[(z*.13,-.13,z),
                   (z*.13+side*.45,-.11,z+.28)],.035,"gold_glow",sides=4)
    result.append(finish(r, .13))

    r = Recipe(9, "paradestar", "Flying five-pointed star")
    rings=[]
    for depth in (-.22,.22):
        rings.append([(math.sin(i*math.pi/5)*(1.65 if i%2==0 else .72),depth,
                       1.72+math.cos(i*math.pi/5)*(1.65 if i%2==0 else .72)) for i in range(10)])
    r._section_cage("Star",rings,[(0,-.22,1.72),(0,.22,1.72)],"gold_glow",smooth=False)
    result.append(finish(r, .16))

    # These three retain the earlier catalog's motifs in the native scene too.
    r = Recipe(10, "paradecloud", "Floating cloud")
    for i,(x,z,rx,rz) in enumerate(((-1.0,.8,.85,.65),(0,1.2,1.0,1.05),(1.1,.78,.85,.68))):
        r.ellipsoid("Lobe%d" % i,(x,0,z),(rx,.55,rz),"ivory_glow")
    result.append(finish(r,.18))

    r = Recipe(11, "paradepinwheel", "Flying pinwheel")
    r.cylinder("Stem",(0,0,.06),(0,0,2.4),.09,"gold_glow")
    for i,mat in enumerate(("cyan_glow","pink_glow","gold_glow","green_glow")):
        a=i*math.pi/2
        r.leaf("Blade%d" % i,(0,0,2.4),(1.15*math.cos(a),0,2.4+1.15*math.sin(a)),
               .77,mat,width_axis=(-math.sin(a),0,math.cos(a)),bend=(0,-.17,0),thickness=.17)
    r.ellipsoid("Hub",(0,-.15,2.4),(.19,.18,.19),"ivory_glow")
    result.append(finish(r,.14))

    r = Recipe(12, "parademoth", "Flying night-post moth")
    r.ellipsoid("Body",(0,0,1.35),(.22,.25,.83),"gold_glow")
    for side in (-1,1):
        label="L" if side<0 else "R"
        r.leaf("Forewing"+label,(0,0,1.52),(side*1.80,0,2.67),1.15,
               "ivory_glow",width_axis=(0,0,1),bend=(0,.14,0),thickness=.17)
        r.leaf("Hindwing"+label,(0,0,1.15),(side*1.15,0,.25),.90,
               "pink_glow",width_axis=(1,0,0),bend=(0,.10,0),thickness=.17)
        r.tube("Antenna"+label,[(side*.10,0,2.08),(side*.28,0,2.42),
               (side*.40,0,2.57)],.045,"gold_glow",sides=4)
    result.append(finish(r,.16))
    return result
