"""Editable spline-cage sources for the sixteen parade visitors.

Recipe coordinates here are X right, Y depth, Z up, with faces toward -Y.
The caller supplies the existing ``authoring`` module on sys.path and converts
the evaluated source into game coordinates.  No voxel geometry is authored
here: every visible component is a connected cage or a renderable spline.
Body, head and mask are semantic groups; their runtime pivots belong to the
exporter, not to a second set of transforms baked into these recipes.
"""
from __future__ import annotations

import math

from authoring import Recipe


def _vertical(r, name, sections, material="dark", group="body", sides=8,
              smooth=True):
    """Closed upright ring-and-rail cage; sections are (z, rx, ry[, x, y])."""
    rings, centers = [], []
    for section in sections:
        z, rx, ry = section[:3]
        x, y = section[3:] if len(section) == 5 else (0.0, 0.0)
        centers.append((x, y, z))
        rings.append([(x + rx * math.cos(a * math.tau / sides),
                       y + ry * math.sin(a * math.tau / sides), z)
                      for a in range(sides)])
    return r._section_cage(name, rings, centers, material, group, smooth)


def _oval(r, name, center, radii, material="dark", group="body", rotation=(0, 0, 0)):
    return r.ellipsoid(name, center, radii, material, rings=5, sides=8,
                       rotation=rotation, group=group)


def _limb(r, name, points, radii, material="dark", group="body"):
    return r.sweep(name, points, radii, material, sides=8, group=group)


def _rim(r, name, points, material="cyan_glow", radius=.105,
         closed=False, group="body"):
    return r.tube(name, points, radius, material, closed=closed, smooth=True,
                  sides=5, group=group)


def _shoe(r, name, x, y=-.16, z=0.0, width=.32, length=.52,
          height=.21, material="dark"):
    return _oval(r, name, (x, y, z + height), (width, length, height), material)


def _head(r, center, radii=(.63, .48, .80), material="dark"):
    return _oval(r, "Head", center, radii, material, "head")


def _mask(r, center, width=1.0, height=1.32, style="quiet", split=False):
    """Raised pale plate and dark inset-like patches that survive pixel export."""
    x, y, z = center
    depth = .18 if width >= 1 else .13
    if split:
        # Two complete source cages retain a genuine dark split between them.
        _oval(r, "MaskLeft", (x-width*.30, y, z),
              (width*.16, depth, height*.50), "ivory_glow", "mask")
        _oval(r, "MaskRight", (x+width*.30, y, z),
              (width*.16, depth, height*.50), "ivory_glow", "mask")
    else:
        _oval(r, "FacePlate", center, (width*.50, depth, height*.50),
              "ivory_glow", "mask")
    eye_x = width * (.27 if split else .22)
    eye_w = max(.095, width*.12)
    eye_h = max(.12, height*(.075 if style == "slit" else .105))
    for side, sign in (("Left", -1), ("Right", 1)):
        # Thick dark patches overlap the plate and reach its visible front.
        # They are material details, not unconnected marks painted in a preview.
        _oval(r, "Eye"+side, (x+sign*eye_x, y-depth*.92, z+height*.09),
              (eye_w, depth*.88, eye_h), "dark", "mask")
    if style == "three":
        _oval(r, "ThirdEye", (x, y-depth*.96, z+height*.29),
              (eye_w*.8, depth*.85, eye_h), "dark", "mask")
    elif style == "helper":
        _oval(r, "SmallMouth", (x+width*.07, y-depth*.98, z-height*.19),
              (max(.065, width*.065), depth*.72, max(.07, height*.065)),
              "dark", "mask")
    elif style == "long":
        r.box("QuietMouth", (x, y-depth, z-height*.23),
              (width*.27, depth*1.4, max(.12, height*.05)), "dark", group="mask")


def _tilt_head(r, pivot, degrees):
    """Bake a characteristic sideways head tilt into both semantic groups."""
    angle = math.radians(degrees)
    c, s = math.cos(angle), math.sin(angle)

    def point(p):
        x, y, z = (p[i]-pivot[i] for i in range(3))
        return [round(pivot[0]+c*x+s*z, 6), round(pivot[1]+y, 6),
                round(pivot[2]-s*x+c*z, 6)]

    for part in r.parts:
        if part["group"] not in ("head", "mask"):
            continue
        if part["kind"] == "cage":
            part["vertices"] = [point(p) for p in part["vertices"]]
            for curve in part["curves"]:
                for key in ("points", "in_handles", "out_handles"):
                    if key in curve:
                        curve[key] = [point(p) for p in curve[key]]
        else:
            part["points"] = [point(p) for p in part["points"]]


def _finish(r, category, variant, head_pivot, description, cell_size=None):
    result = r.to_dict()
    result.update(category=category, variant=variant,
                  cell_size=cell_size or {"civilian": .23, "dead": .23,
                                          "ai": .30, "helper": .13}[category],
                  head_pivot=list(head_pivot), description=description,
                  coordinate_system="X right, Y depth, Z up; front -Y; feet Z0")
    return result


def _civilian1():
    r = Recipe(1, "paradecivilian1", "The coat commuter")
    _shoe(r, "LeftShoe", -.45)
    _shoe(r, "RightShoe", .45, -.02)
    for side, x in (("Left", -.45), ("Right", .45)):
        _limb(r, side+"Trouser", [(x, 0, .28), (x, .02, 1.5), (x*.7, 0, 3.05)], [.27,.30,.34])
    _vertical(r, "LongRaincoat", [(.9,1.05,.58), (2.5,1.03,.60),
                                      (4.4,.82,.55), (5.7,.97,.53), (6.0,.52,.40)])
    for side, sign in (("Left", -1), ("Right", 1)):
        _limb(r, side+"Sleeve", [(sign*.82,0,5.65), (sign*1.05,-.25,4.5),
                                  (sign*.25,-.70,3.85)], [.36,.30,.23])
        _oval(r, side+"Hand", (sign*.22,-.72,3.83), (.23,.19,.29), "teal")
    _vertical(r, "HighCollar", [(5.65,.48,.47), (6.15,.56,.49)], "teal")
    _limb(r, "Neck", [(0,0,5.95),(0,0,6.5)], [.25,.25])
    _head(r, (0,0,7.05))
    _mask(r, (0,-.43,7.02), 1.02, 1.30)
    _rim(r, "SingleLapel", [(-.38,-.53,5.88),(-.54,-.60,5.25),(-.18,-.63,4.25)])
    _rim(r, "RaincoatHem", [(-.85,-.30,1.02),(0,-.59,1.0),(.85,-.30,1.02)], radius=.095)
    return _finish(r,"civilian",1,(0,0,6.18),
                   "Narrow modern raincoat, visible shoes and quietly clasped hands.")


def _civilian2():
    r = Recipe(2, "paradecivilian2", "The jacket watcher")
    _shoe(r,"LeftBoot",-.69,-.14,width=.39,length=.58)
    _shoe(r,"RightBoot",.66,.10,width=.39,length=.58)
    _limb(r,"LeftTrouser",[(-.69,0,.3),(-.75,0,1.9),(-.55,.12,3.55)],[.35,.42,.47])
    _limb(r,"RightTrouser",[(.66,.15,.3),(.75,.20,2.1),(.50,.10,3.55)],[.35,.41,.47])
    _vertical(r,"ShortJacket",[(3.0,1.05,.65),(3.6,1.34,.75),
                                  (5.2,1.30,.72),(5.65,1.05,.59)],"teal")
    _limb(r,"PocketArm",[(-1.10,0,5.25),(-1.42,-.05,4.45),(-.92,-.62,3.55)],[.40,.36,.25])
    _limb(r,"WavingSleeve",[(1.11,0,5.25),(1.69,-.05,5.15),(1.93,-.13,6.03)],[.40,.32,.25])
    _oval(r,"WavingHand",(1.94,-.14,6.33),(.24,.22,.42),"teal")
    _vertical(r,"RolledCollar",[(5.40,.60,.57),(5.87,.64,.56)],"dark")
    _head(r,(0,0,6.65),(.68,.52,.75))
    _mask(r,(0,-.47,6.62),1.04,1.13,"slit")
    _rim(r,"JacketSeam",[(.28,-.70,3.35),(.27,-.74,4.45),(.17,-.59,5.38)],radius=.105)
    _rim(r,"RaisedCuff",[(1.68,-.32,5.94),(1.98,-.34,6.02),(2.16,-.10,6.00)],radius=.09)
    return _finish(r,"civilian",2,(0,0,5.83),
                   "Broad short jacket, loose trousers and one restrained greeting hand.")


def _civilian3():
    r=Recipe(3,"paradecivilian3","The poncho courier")
    _shoe(r,"ForwardShoe",-.52,-.48,width=.30,length=.60)
    _shoe(r,"BackShoe",.48,.30,width=.30,length=.57)
    _limb(r,"LeftLeg",[(-.52,-.24,.35),(-.62,-.04,1.85),(-.44,.12,3.5)],[.26,.31,.36])
    _limb(r,"RightLeg",[(.48,.42,.35),(.67,.37,1.9),(.46,.16,3.5)],[.26,.31,.36])
    _vertical(r,"AsymmetricPoncho",[(2.85,1.50,.76,.15,.16),
                                        (3.7,1.40,.80,.05,.10),
                                        (5.45,1.17,.66,0,0),
                                        (5.86,.54,.44,0,-.04)],"dark")
    _limb(r,"LeftArm",[(-1.04,-.04,5.1),(-1.35,-.28,4.15),(-1.12,-.55,3.08)],[.29,.25,.20])
    _oval(r,"LeftHand",(-1.10,-.56,2.92),(.21,.19,.29),"teal")
    _limb(r,"RightArm",[(1.03,0,5.10),(1.30,-.34,4.4),(.49,-.83,4.27)],[.29,.25,.20])
    _oval(r,"StrapHand",(.48,-.84,4.27),(.25,.18,.23),"teal")
    r.box("MessengerBag",(.99,.33,3.03),(.68,.84,1.18),"teal",rotation=(0,8,-8),group="body")
    _rim(r,"DiagonalStrap",[(-.66,-.50,5.55),(.02,-.79,4.5),(.85,-.73,3.32)],"teal",.16)
    _head(r,(0,-.07,6.74),(.61,.49,.78))
    _mask(r,(0,-.51,6.68),.98,1.30,"long")
    _oval(r,"ModernCap",(0,-.02,7.35),(.72,.56,.24),"teal","head")
    _oval(r,"CapPeak",(0,-.63,7.25),(.76,.42,.12),"dark","head")
    _rim(r,"PonchoCorner",[(-1.10,-.39,3.12),(.03,-.66,2.92),(1.41,-.35,2.88)],radius=.105)
    return _finish(r,"civilian",3,(0,-.04,5.93),
                   "Offset poncho, messenger bag, peaked rain cap and staggered feet.")


def _civilian4():
    r=Recipe(4,"paradecivilian4","The umbrella observer")
    _shoe(r,"LeftShoe",-.42,-.22)
    _shoe(r,"RightShoe",.46,-.12)
    for side,x in (("Left",-.42),("Right",.46)):
        _limb(r,side+"Leg",[(x,0,.3),(x,.04,1.8),(x*.7,.1,3.5)],[.26,.29,.34])
    _vertical(r,"FittedCoat",[(1.45,.87,.54),(3.1,.80,.52),(4.8,.73,.52),
                                 (5.55,.94,.49),(5.80,.45,.37)],"teal")
    _limb(r,"PoleArm",[(-.78,-.02,5.4),(-1.02,-.50,4.6),(-1.18,-.64,5.15)],[.30,.26,.20])
    _oval(r,"PoleHand",(-1.18,-.66,5.17),(.23,.19,.25),"dark")
    _limb(r,"RelaxedArm",[(.78,0,5.40),(1.03,.10,4.14),(.87,-.15,3.28)],[.31,.25,.19])
    _oval(r,"RelaxedHand",(.86,-.15,3.08),(.20,.18,.30),"dark")
    _head(r,(.16,.02,6.55),(.59,.46,.75))
    _mask(r,(.16,-.40,6.52),.96,1.23)
    _limb(r,"UmbrellaHandle",[(-1.18,-.64,4.75),(-1.18,-.64,6.10),(-1.18,-.64,7.75)],[.105,.105,.105])
    _vertical(r,"UmbrellaCanopy",[(7.49,2.20,1.48,-.86,.05),
                                      (7.70,1.92,1.30,-.86,.05),
                                      (8.03,1.15,.80,-.86,.05),
                                      (8.24,.22,.17,-.86,.05)],"dark",sides=8,smooth=False)
    _rim(r,"UmbrellaFrontRib",[(-.86,-1.40,7.50),(-.86,-1.17,7.72),(-.86,-.62,8.06),(-.86,.05,8.25)],radius=.10)
    _rim(r,"CoatOpening",[(.11,-.52,2.0),(.13,-.55,3.8),(.13,-.48,5.47)],radius=.09)
    return _finish(r,"civilian",4,(.16,.02,5.78),
                   "Slim fitted raincoat beneath an offset low polygon umbrella.")


def _dead1():
    r=Recipe(5,"paradedead1","The bowler gentleman")
    _shoe(r,"LeftOldShoe",-.42,-.19,width=.31,length=.66)
    _shoe(r,"RightOldShoe",.43,-.01,width=.31,length=.66)
    for side,x in (("Left",-.43),("Right",.43)):
        _limb(r,side+"Trouser",[(x,0,.30),(x,0,1.6),(x*.8,.12,3.6)],[.27,.28,.34])
    _vertical(r,"FrockCoat",[(1.15,.94,.55),(3.4,.87,.57),(5.6,1.00,.59),(6.0,.50,.40)])
    _limb(r,"CaneSleeve",[(-.87,0,5.62),(-1.18,-.36,4.65),(-1.00,-.70,3.67)],[.31,.28,.21])
    _oval(r,"CaneHand",(-1.00,-.72,3.58),(.22,.19,.24))
    _limb(r,"Cane",[(-1.03,-.75,.03),(-1.03,-.75,2.0),(-1.03,-.75,3.6),(-.81,-.75,3.75)],[.105,.105,.105,.10],"dark")
    _limb(r,"RestingSleeve",[(.85,0,5.62),(1.02,.05,4.33),(.84,-.15,3.42)],[.31,.26,.21])
    _oval(r,"RestingHand",(.84,-.15,3.24),(.21,.19,.30))
    _head(r,(0,0,6.90),(.61,.47,.79))
    _mask(r,(0,-.42,6.87),.96,1.26,"long")
    _oval(r,"BowlerBrim",(0,0,7.53),(.98,.72,.15),"dark","head")
    _vertical(r,"BowlerCrown",[(7.50,.64,.49),(7.95,.63,.48),(8.17,.40,.33)],group="head")
    _rim(r,"OldLapel",[(-.23,-.53,5.88),(-.47,-.61,5.28),(-.13,-.61,4.52)],"violet_glow",.085)
    return _finish(r,"dead",1,(0,0,6.07),
                   "A bowler, long frock coat, worn shoes and an old walking cane.")


def _dead2():
    r=Recipe(6,"paradedead2","The shawled widow")
    _shoe(r,"HiddenLeftShoe",-.38,-.35,width=.26,length=.50)
    _shoe(r,"HiddenRightShoe",.38,-.28,width=.26,length=.50)
    _vertical(r,"BellDress",[(.34,1.52,.94),(1.0,1.47,.92),(2.5,1.17,.78),
                                 (3.9,.71,.50),(4.8,.76,.49),(5.7,.88,.49)])
    _vertical(r,"Shawl",[(4.15,1.22,.70),(5.2,1.19,.66),(5.85,.78,.50),(6.15,.39,.31)])
    for side,sign in (("Left",-1),("Right",1)):
        _limb(r,side+"FoldedArm",[(sign*.84,-.08,5.45),(sign*.85,-.63,4.7),
                                     (sign*.16,-.83,4.38)],[.25,.24,.17])
        _oval(r,side+"Hand",(sign*.14,-.85,4.36),(.20,.16,.22),"dark")
    _head(r,(0,-.02,6.91),(.59,.46,.75))
    _mask(r,(0,-.43,6.86),.93,1.18,"quiet")
    _oval(r,"WideHatBrim",(0,.02,7.48),(1.30,.91,.15),"dark","head")
    _oval(r,"HatCrown",(0,.10,7.73),(.69,.55,.40),"dark","head")
    _oval(r,"HatFlower",(.51,-.39,7.82),(.27,.21,.22),"violet_glow","head")
    _rim(r,"ShawlEdge",[(-1.04,-.38,4.3),(-.56,-.65,4.4),(0,-.74,4.65),(.95,-.40,4.32)],"violet_glow",.085)
    _tilt_head(r,(0,-.02,6.15),-5)
    return _finish(r,"dead",2,(0,-.02,6.15),
                   "A long bell dress, folded shawl, broad period hat and clasped hands.")


def _dead3():
    r=Recipe(7,"paradedead3","The robed elder")
    _shoe(r,"LeftSlipper",-.45,-.17,width=.33,length=.60,height=.17)
    _shoe(r,"RightSlipper",.45,-.17,width=.33,length=.60,height=.17)
    _vertical(r,"LongWrappedRobe",[(.30,1.10,.70,0,.10),(2.1,1.04,.68,0,.08),
                                       (4.0,.86,.58,0,0),(5.4,1.12,.60,0,-.06),
                                       (5.85,.49,.38,0,-.14)])
    _vertical(r,"RobeSash",[(3.82,.92,.63,0,0),(4.16,.93,.64,0,0)],"dark")
    _limb(r,"LeftWideSleeve",[(-.95,0,5.35),(-1.53,-.12,4.80),(-.75,-.71,4.28)],[.50,.55,.40])
    _limb(r,"RightWideSleeve",[(.95,0,5.35),(1.56,-.14,4.70),(.75,-.71,4.28)],[.50,.55,.40])
    _oval(r,"JoinedHands",(0,-.72,4.27),(.69,.22,.27))
    _limb(r,"BentNeck",[(0,-.14,5.68),(0,-.24,6.15),(0,-.35,6.4)],[.30,.30,.28])
    _head(r,(0,-.35,6.96),(.68,.49,.81))
    _mask(r,(0,-.79,6.88),1.03,1.29,"slit")
    _oval(r,"RearHairKnot",(0,.11,7.23),(.41,.39,.37),"dark","head")
    _oval(r,"OldSkullCap",(0,-.26,7.51),(.65,.49,.30),"dark","head")
    _rim(r,"RobeCrossing",[(-.77,-.47,5.48),(-.28,-.64,4.88),(.74,-.62,4.0)],"violet_glow",.085)
    return _finish(r,"dead",3,(0,-.22,6.05),
                   "A stooped elder in an old wrap robe, wide sleeves and a tied hair knot.")


def _dead4():
    r=Recipe(8,"paradedead4","The travelling shade")
    _shoe(r,"LeftBoot",-.52,-.09,width=.34,length=.59,height=.25)
    _shoe(r,"RightBoot",.52,.03,width=.34,length=.59,height=.25)
    for side,x in (("Left",-.52),("Right",.52)):
        _limb(r,side+"Leg",[(x,0,.35),(x,0,1.7),(x*.62,.10,3.5)],[.29,.32,.37])
    _vertical(r,"TravellingGreatcoat",[(1.0,1.15,.64),(3.5,.96,.62),
                                           (5.7,1.15,.63),(6.10,.59,.41)])
    _vertical(r,"ShoulderCape",[(4.7,1.49,.78),(5.5,1.45,.75),
                                    (6.13,.68,.48),(6.3,.40,.32)])
    _limb(r,"LeftCrossedSleeve",[(-1.04,-.08,5.62),(-1.12,-.67,4.92),(.45,-.89,4.62)],[.33,.29,.24])
    _limb(r,"RightCrossedSleeve",[(1.04,-.08,5.62),(1.10,-.64,4.86),(-.44,-.89,4.43)],[.33,.29,.24])
    _head(r,(0,0,6.96),(.57,.45,.74))
    _mask(r,(0,-.40,6.93),.89,1.28,"long")
    _oval(r,"TallHatBrim",(0,0,7.49),(.98,.70,.14),"dark","head")
    _vertical(r,"TallHatCrown",[(7.49,.60,.45),(8.42,.53,.40),(8.52,.63,.46)],group="head",smooth=False)
    r.leaf("TrailingScarf",(.33,.40,5.73),(2.15,.62,4.82),.66,"dark",
           width_axis=(0,0,1),bend=(.12,.08,.37),thickness=.18,group="body")
    _rim(r,"CapeEdge",[(-1.30,-.39,4.83),(0,-.76,4.71),(1.30,-.39,4.83)],"violet_glow",.085)
    return _finish(r,"dead",4,(0,0,6.17),
                   "A tall period hat, short shoulder cape, crossed arms and trailing scarf.")


def _ai1():
    r=Recipe(9,"paradeai1","Null Lux")
    # Separate closed mantle lobes and a rear panel leave a real open chest.
    for side,sign in (("Left",-1),("Right",1)):
        _vertical(r,side+"Mantle",[(0.0,.32,.33,sign*.88,.17),
                                       (1.5,.59,.52,sign*1.12,.08),
                                       (5.8,.56,.65,sign*1.20,0),
                                       (8.5,.65,.63,sign*.91,0),
                                       (10.3,.35,.41,sign*.43,.04)])
    r.patch("MantleBack",[[(-1.02,.58,1.0),(0,.73,1.0),(1.02,.58,1.0)],
                           [(-1.10,.61,5.3),(0,.81,5.3),(1.10,.61,5.3)],
                           [(-.40,.31,10.2),(0,.43,10.4),(.40,.31,10.2)]],
            "dark",thickness=.22,group="body")
    _oval(r,"QuietShoulders",(0,.08,9.95),(1.01,.49,.58))
    _limb(r,"ThinNeck",[(0,.03,10.05),(0,.03,10.85)],[.24,.24])
    _head(r,(0,.03,11.87),(.80,.49,1.39))
    _mask(r,(0,-.40,11.86),1.42,2.37,"slit",split=True)
    _vertical(r,"ChestLantern",[(5.05,.31,.31),(5.25,.43,.40),
                                    (6.0,.43,.40),(6.20,.30,.30)],"gold_glow",sides=8)
    _oval(r,"LanternCap",(0,0,6.23),(.48,.44,.13),"dark")
    _oval(r,"LanternBase",(0,0,5.04),(.43,.40,.13),"dark")
    _rim(r,"LanternSuspension",[(0,0,6.30),(0,0,7.20),(0,.10,8.0)],"gold_glow",.10)
    _rim(r,"LeftInnerEdge",[(-.56,-.38,1.1),(-.64,-.50,5.35),(-.43,-.40,8.65)],"cyan_glow",.10)
    _rim(r,"RightInnerEdge",[(.56,-.38,1.1),(.64,-.50,5.35),(.43,-.40,8.65)],"cyan_glow",.10)
    return _finish(r,"ai",1,(0,.03,10.35),
                   "Null Lux: a tall quiet open mantle, split pale mask and sheltered chest lantern.")


def _ai2():
    r=Recipe(10,"paradeai2","The bell-mantled visitor")
    _vertical(r,"BellMantle",[(0.0,3.35,1.32),(1.1,3.78,1.50),
                                   (3.7,3.22,1.45),(6.2,2.16,1.13),
                                   (8.10,.68,.50)],"dark",sides=12)
    _vertical(r,"CeremonialCollar",[(7.0,3.75,1.15),(7.32,4.10,1.30),
                                         (7.78,2.85,.91),(8.20,.73,.43)],"teal",sides=12,smooth=False)
    _limb(r,"SlenderNeck",[(0,0,8.0),(0,0,8.86)],[.23,.23])
    _head(r,(0,0,9.53),(.63,.44,1.10))
    _mask(r,(0,-.39,9.50),.92,1.91,"long")
    _rim(r,"WideCollarEdge",[(-3.68,-.48,7.31),(-2.08,-1.10,7.27),
                                  (0,-1.27,7.23),(2.08,-1.10,7.27),(3.68,-.48,7.31)],"gold_glow",.12)
    _rim(r,"BellFrontHem",[(-3.08,-.61,.30),(-1.75,-1.22,.23),(0,-1.36,.20),
                                (1.75,-1.22,.23),(3.08,-.61,.30)],"gold_glow",.11)
    return _finish(r,"ai",2,(0,0,8.28),
                   "A broad bell-shaped ceremonial presence with a tiny elongated masked head.")


def _ai3():
    r=Recipe(11,"paradeai3","The many-eyed pilgrim")
    _vertical(r,"PilgrimStem",[(0.0,.65,.49),(2.5,.88,.61),(4.7,.71,.54),
                                   (6.20,1.13,.62),(6.72,.53,.39)],"dark")
    _limb(r,"LeftHangingSleeve",[(-.88,0,6.15),(-2.20,.02,5.55),(-2.82,.14,3.70)],
          [.50,.67,.30],"dark")
    _limb(r,"RightOfferingSleeve",[(.88,0,6.15),(1.89,-.10,5.60),(2.72,-.40,6.20)],
          [.50,.60,.28],"dark")
    _oval(r,"OfferingPalm",(2.78,-.42,6.23),(.50,.39,.21),"teal")
    _limb(r,"PilgrimNeck",[(0,0,6.45),(0,0,7.30)],[.32,.32])
    _head(r,(0,.05,8.75),(2.07,.72,1.77),"teal")
    _mask(r,(0,-.59,8.72),2.72,2.55,"three")
    _rim(r,"CrownArc",[(-1.75,-.20,9.54),(-1.02,-.25,10.20),(0,-.25,10.45),
                             (1.02,-.25,10.20),(1.75,-.20,9.54)],"cyan_glow",.12,group="head")
    _rim(r,"SleeveEdge",[(-.94,-.31,5.94),(-2.19,-.43,5.35),(-2.78,-.17,3.72)],"cyan_glow",.105)
    _oval(r,"HeldLight",(2.83,-.43,6.69),(.25,.25,.36),"gold_glow")
    return _finish(r,"ai",3,(0,0,7.0),
                   "A narrow pilgrim with an enormous oval three-eyed mask and unequal hanging sleeves.")


def _ai4():
    r=Recipe(12,"paradeai4","The folded-sail spirit")
    _vertical(r,"FoldedSail",[(0.0,.16,.19,-.53,.08),(1.60,.84,.47,-.38,.04),
                                   (4.78,2.93,.85,0,0),(6.6,2.05,.75,.15,.05),
                                   (8.86,.43,.35,.41,.02)],"dark",sides=8,smooth=False)
    _limb(r,"LeftTrailingFold",[(-1.72,.18,5.60),(-2.55,.24,3.45),(-1.75,.45,.63)],
          [.35,.49,.14],"teal")
    _limb(r,"RightLiftedFold",[(1.93,.08,5.60),(3.25,-.10,6.5),(3.66,-.19,8.32)],
          [.35,.42,.17],"dark")
    _limb(r,"CurvedNeck",[(.41,.02,8.65),(.59,-.04,9.25),(.92,-.07,9.64)],
          [.23,.23,.24])
    _head(r,(1.06,-.07,10.26),(.71,.46,1.13))
    _mask(r,(1.06,-.48,10.26),1.03,1.88,"slit")
    _rim(r,"SailFold",[(-.52,-.15,.32),(-.10,-.56,3.0),(.34,-.83,5.05),(.47,-.40,8.60)],
         "violet_glow",.12)
    _rim(r,"SleeveTip",[(3.38,-.32,7.1),(3.58,-.36,7.70),(3.69,-.28,8.30)],"gold_glow",.11)
    _tilt_head(r,(.69,-.06,9.22),-17)
    return _finish(r,"ai",4,(.69,-.06,9.22),
                   "A kite-like folded mantle with unequal ribbon limbs and a tilted narrow mask.")


def _helper1():
    r=Recipe(13,"paradehelper1","The lantern tender")
    _shoe(r,"LeftFoot",-.20,-.03,width=.14,length=.24,height=.11,material="ivory_glow")
    _shoe(r,"RightFoot",.23,.08,width=.14,length=.24,height=.11,material="ivory_glow")
    _limb(r,"LeftLeg",[(-.20,0,.15),(-.21,.02,.42),(-.16,0,.63)],[.12,.13,.15],"ivory_glow")
    _limb(r,"RightLeg",[(.23,.09,.15),(.23,.07,.45),(.15,0,.66)],[.12,.13,.15],"ivory_glow")
    _vertical(r,"PearBody",[(.43,.27,.22),(.71,.38,.29),(1.12,.27,.22),(1.37,.14,.14)],"ivory_glow")
    _limb(r,"NearArm",[(.26,-.02,1.15),(.58,-.22,1.72),(.78,-.29,2.12)],[.12,.10,.085],"ivory_glow")
    _limb(r,"FarArm",[(-.25,0,1.12),(.02,-.43,1.52),(.61,-.38,2.02)],[.12,.10,.085],"ivory_glow")
    _oval(r,"NearHand",(.79,-.29,2.12),(.11,.10,.15),"ivory_glow")
    _oval(r,"FarHand",(.63,-.38,2.04),(.12,.10,.13),"ivory_glow")
    _head(r,(-.08,0,1.98),(.56,.40,.67),"cream")
    _mask(r,(-.08,-.35,1.98),.82,1.04,"helper")
    _rim(r,"LanternTassel",[(.83,-.26,2.10),(.87,-.23,2.38)],"gold_glow",.065)
    _oval(r,"SmallLantern",(.89,-.21,2.72),(.32,.28,.38),"gold_glow")
    _oval(r,"LanternTop",(.89,-.21,3.08),(.28,.25,.075),"dark")
    _oval(r,"LanternBottom",(.89,-.21,2.36),(.24,.23,.065),"dark")
    _tilt_head(r,(-.03,0,1.37),-10)
    return _finish(r,"helper",1,(-.03,0,1.37),
                   "A pear-shaped attendant stretching both hands to guide a small lantern.")


def _helper2():
    r=Recipe(14,"paradehelper2","The outline mender")
    _shoe(r,"TuckedFoot",-.25,.25,width=.14,length=.24,height=.10,material="ivory_glow")
    _shoe(r,"KneelingFoot",.35,.48,width=.14,length=.25,height=.10,material="ivory_glow")
    _oval(r,"LeftKnee",(-.32,-.10,.28),(.23,.28,.23),"ivory_glow")
    _limb(r,"BentShin",[(.35,.43,.15),(.47,.10,.28),(.31,-.22,.48)],[.14,.16,.18],"ivory_glow")
    _oval(r,"CrouchedBody",(0,0,.82),(.40,.33,.52),"ivory_glow")
    _limb(r,"WorkingArm",[(-.29,-.03,1.10),(-.51,-.43,.71),(-.65,-.79,.34)],[.13,.105,.085],"ivory_glow")
    _limb(r,"HoldingArm",[(.29,0,1.10),(.44,-.42,.86),(.03,-.79,.59)],[.13,.105,.085],"ivory_glow")
    _oval(r,"WorkingHand",(-.65,-.81,.32),(.14,.105,.11),"ivory_glow")
    _oval(r,"HoldingHand",(.01,-.81,.59),(.14,.105,.11),"ivory_glow")
    _head(r,(-.02,-.12,1.76),(.71,.42,.58),"cream")
    _mask(r,(-.02,-.48,1.75),1.02,.92,"helper")
    _rim(r,"RepairThread",[(-.67,-.84,.31),(-.44,-.86,.42),(-.15,-.85,.47),(.02,-.83,.58)],"cyan_glow",.067)
    r.box("FirstStitch",(-.52,-.87,.30),(.16,.14,.14),"gold_glow",group="body")
    r.box("SecondStitch",(-.30,-.87,.33),(.16,.14,.14),"gold_glow",group="body")
    _tilt_head(r,(-.02,-.07,1.25),15)
    return _finish(r,"helper",2,(-.02,-.07,1.25),
                   "A crouching broad-headed helper stitching a loose luminous outline.")


def _helper3():
    r=Recipe(15,"paradehelper3","The crane courier")
    _shoe(r,"PlantedFoot",-.20,-.13,width=.14,length=.26,height=.11,material="ivory_glow")
    _shoe(r,"LiftedFoot",.40,.21,z=.23,width=.14,length=.24,height=.11,material="ivory_glow")
    _limb(r,"PlantedLeg",[(-.20,-.06,.16),(-.22,.03,.54),(-.14,0,.75)],[.12,.14,.15],"ivory_glow")
    _limb(r,"LiftedLeg",[(.40,.24,.40),(.30,.28,.58),(.13,0,.79)],[.12,.14,.15],"ivory_glow")
    _oval(r,"RoundBody",(0,0,.99),(.38,.29,.46),"ivory_glow")
    _limb(r,"LeftRaisedArm",[(-.27,0,1.22),(-.49,-.03,1.72),(-.45,-.03,2.45)],[.12,.10,.08],"ivory_glow")
    _limb(r,"RightRaisedArm",[(.27,0,1.22),(.47,-.06,1.78),(.45,-.03,2.45)],[.12,.10,.08],"ivory_glow")
    for side,x in (("Left",-.45),("Right",.45)):
        _oval(r,side+"Hand",(x,-.03,2.44),(.12,.10,.13),"ivory_glow")
    _head(r,(0,-.07,1.88),(.57,.39,.58),"cream")
    _mask(r,(0,-.41,1.88),.82,.92,"helper")
    # The carried crane is a tiny folded object, not a texture billboard.
    r.box("CraneBody",(0,.01,2.55),(.47,.32,.25),"gold_glow",rotation=(0,0,15),group="body")
    r.leaf("CraneLeftWing",(-.15,.01,2.56),(-.91,.06,3.04),.48,"ivory_glow",
           width_axis=(0,1,0),bend=(0,-.04,.08),thickness=.11,group="body")
    r.leaf("CraneRightWing",(.15,.01,2.56),(.91,.06,3.04),.48,"ivory_glow",
           width_axis=(0,1,0),bend=(0,-.04,.08),thickness=.11,group="body")
    _limb(r,"CraneNeck",[(0,-.10,2.57),(0,-.39,2.81),(0,-.49,2.78)],[.095,.075,.045],"gold_glow")
    _tilt_head(r,(0,-.02,1.33),-10)
    return _finish(r,"helper",3,(0,-.02,1.33),
                   "A hurrying round-bodied courier carrying a folded crane above its head.")


def _helper4():
    r=Recipe(16,"paradehelper4","The curious lookout")
    _shoe(r,"LeftFoot",-.22,-.04,width=.15,length=.24,height=.11,material="ivory_glow")
    _shoe(r,"RightFoot",.23,.03,width=.15,length=.24,height=.11,material="ivory_glow")
    for side,x in (("Left",-.22),("Right",.23)):
        _limb(r,side+"Leg",[(x,0,.15),(x*.9,.04,.44),(x*.55,0,.67)],
              [.12,.12,.15],"ivory_glow")
    _vertical(r,"SmallBody",[(.48,.26,.22),(.79,.31,.25),(1.12,.22,.19),(1.28,.13,.13)],"ivory_glow")
    _limb(r,"LongNeck",[(0,0,1.13),(0,0,1.48),(0,-.01,1.78)],[.115,.11,.12],"ivory_glow")
    _limb(r,"LeftBehindArm",[(-.22,.01,1.11),(-.37,.20,.88),(-.08,.35,.74)],
          [.105,.09,.08],"ivory_glow")
    _limb(r,"RightBehindArm",[(.22,.01,1.11),(.38,.20,.88),(.08,.35,.74)],
          [.105,.09,.08],"ivory_glow")
    _oval(r,"JoinedHands",(0,.36,.73),(.20,.11,.12),"ivory_glow")
    _head(r,(0,0,2.22),(.61,.40,.67),"cream")
    _mask(r,(0,-.35,2.23),.88,1.06,"helper")
    _tilt_head(r,(0,0,1.64),28)
    return _finish(r,"helper",4,(0,0,1.64),
                   "A long-necked lookout with hands behind its back and a curious tilted mask.")


def build():
    """Return all sixteen distinct, independently regenerable source recipes."""
    builders = (_civilian1, _civilian2, _civilian3, _civilian4,
                _dead1, _dead2, _dead3, _dead4,
                _ai1, _ai2, _ai3, _ai4,
                _helper1, _helper2, _helper3, _helper4)
    return [builder() for builder in builders]
