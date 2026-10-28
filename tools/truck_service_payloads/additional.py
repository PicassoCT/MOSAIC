"""The six additional approved street-service payloads, all in one bundle.

Every builder returns complete static geometry for one container piece. People
on the three venue stages are small, clothed figures baked into that piece;
they are not spawned civilians or new gameplay actors.
"""
import math

from generate import ATLAS, FLOOR, Mesh, add

# A measured, nearly non-emissive warm island of the existing Asian atlas.
# These few pixels are used only on the small faces and hands of venue staff.
ATLAS["skin"] = (.89892578, .47705078, .90185547, .47998047)


def arched_roof(m, half_width=12.8, spring=23.0, rise=7.5,
                z0=-21.0, z1=21.0, material="teal", ribs=5):
    """A faceted barrel roof, with physical seams and two thick closed ends."""
    arc = [(half_width*math.cos(i*math.pi/8),
            spring+rise*math.sin(i*math.pi/8)) for i in range(9)]
    for a, b in zip(arc, arc[1:]):
        ps = [(a[0], a[1], z0), (a[0], a[1], z1),
              (b[0], b[1], z1), (b[0], b[1], z0)]
        m.face(ps, material, "body", ((a[0]+b[0])/2, 5, 0))
    cap = [(-half_width, 4.3), (half_width, 4.3)] + arc
    for zz in (z0, z1-.65):
        m.prism(cap, (zz, zz+.65), "z", "worn", side="metal")
    for i in range(ribs):
        zz = z0+(z1-z0)*i/(ribs-1)
        for a, b in zip(arc, arc[1:]):
            m.beam((a[0], a[1]+.12, zz),
                   (b[0], b[1]+.12, zz), .32, "metal")


def staff(m, position, pose="standing", shirt="dark", scale=1.0):
    """Small angular adult venue figures, facing the +X serving side."""
    x, y, z = position
    def p(a, b, c):
        return (x+a*scale, y+b*scale, z+c*scale)
    def box(c, size, mat):
        # Tiny clothing, hands and boots are deliberately plain boxes. Their
        # texture supplies surface detail; chamfers here disappear at RTS zoom.
        m.box(p(*c), tuple(v*scale for v in size), mat, "details")
    if pose == "seated":
        hip, head = 7.4, 14.8
        for side in (-1, 1):
            m.beam(p(0, hip, side*.95), p(2.8, 6.4, side*1.4),
                   1.2*scale, "dark")
            m.beam(p(2.8, 6.4, side*1.4), p(2.8, 1.3, side*1.4),
                   1.1*scale, "dark")
            box((3.2, .7, side*1.4), (2.0, 1.2, 1.3), "dark")
        box((0, 6.4, 0), (3.5, .7, 4), "metal")
        m.cylinder(p(0, 0, 0), p(0, 6.0, 0), .35*scale, "metal", 6)
    else:
        hip, head = 9.4, 17.0
        for side in (-1, 1):
            m.beam(p(0, hip, side*.9), p(.6, 1.3, side*1.3),
                   1.35*scale, "dark")
            box((1, .7, side*1.3), (2.3, 1.3, 1.5), "dark")
    box((0, hip+.3, 0), (2.3, 2.2, 3.3), "dark")
    box((0, hip+3.8, 0), (2.4, 5.1, 4.2), shirt)
    m.cylinder(p(0, head-2.7, 0), p(0, head-1.7, 0),
               .64*scale, "skin", 6, "details")
    m.bevel(p(.15, head, 0), (2.3*scale, 2.8*scale, 2.5*scale),
            .35*scale, "skin", "details", edge="skin")
    box((-.1, head+1.0, 0), (2.5, .8, 2.7), "dark")
    # A short nose/visor and a cap brim keep the face direction readable.
    box((1.35, head, 0), (.5, .5, .8), "skin")
    box((.6, head+1.2, 0), (3.4, .35, 2.8), "dark")
    for side in (-1, 1):
        shoulder = p(0, hip+5.2, side*2.2)
        if pose == "guitar":
            elbow = p(2.2, hip+2.1, side*2.8)
            hand = p(3.2, hip+(4.2 if side > 0 else 1.2), side*3.4)
        elif pose == "raised":
            elbow = p(.8, hip+7.4 if side > 0 else hip+3.4, side*3.5)
            hand = p(1.5, head+1.5 if side > 0 else hip+1.5, side*2.6)
        else:
            elbow = p(2.3, hip+2.3, side*3.0)
            hand = p(4.5, hip+2.1, side*2.2)
        m.beam(shoulder, elbow, 1.05*scale, shirt)
        m.beam(elbow, hand, .9*scale, shirt)
        m.box(hand, (.8*scale, .8*scale, .85*scale), "skin", "details")


def crematorium():
    m = Mesh("mobile_crematorium"); m.base()
    m.bevel((0, 15.3, -1.0), (25, 22, 39), 2.0, "worn", edge="metal")
    # A sealed refractory chamber and a heavy rear door, not an exposed fire.
    m.cylinder((0, 15.5, -21.2), (0, 15.5, -20.2), 9.8,
               "metal", 8, cap="dark")
    m.cylinder((0, 15.5, -21.6), (0, 15.5, -21.15), 8.35,
               "worn", 8, cap="door")
    for angle in (0, math.pi/2, math.pi, math.pi*1.5):
        xx, yy = 8.7*math.cos(angle), 15.5+8.7*math.sin(angle)
        m.box((xx, yy, -22.0), (1.7, 1.0, .7), "metal", "details")
    m.beam((-2.5, 15.5, -22.1), (2.5, 15.5, -22.1), .7, "metal")
    for zz in (-14, -6, 2, 10):
        m.box((0, 26.6, zz), (23, .65, .65), "metal", "details")
        for side in (-1, 1):
            m.box((side*12.55, 16, zz), (.45, 18, .65), "metal", "details")
    # Paired low service lockers along the kerb side, and a short scrubber stack.
    for zz in (-10, -3, 4):
        for yy in (8.5, 14.0):
            m.plate((12.75, yy, zz), 5.4, 4.4, "x", "door")
            m.latch(13.0, yy, zz+1.6)
    m.grille((-12.8, 15, 0), 23, 12, "x", 8)
    m.bevel((0, 14.6, 20), (24, 21, 5.6), .6, "teal")
    m.grille((12.1, 18, 20), 4.3, 10, "x", 6)
    m.cylinder((-8, 24, 16), (-8, 34.0, 16), 2.65, "metal", 10)
    for yy in (25.5, 29.5, 33.2):
        m.cylinder((-8, yy, 16), (-8, yy+.5, 16), 2.95, "worn", 10)
    m.tube([(-8, 33.8, 16), (-8, 35.0, 15), (-8, 35.0, 11.5)], 2.2, "metal", 8)
    m.plate((12.9, 21.5, -8), 7.5, 2.5, "x", "sign")
    m.plate((0, 8, -22.1), 5.0, 2.0, "z", "warning")
    m.features = ["sealed octagonal furnace door", "heat-scrubber stack",
                  "six closed urn lockers and refractory panel ribs"]
    return m


def noodles():
    m = Mesh("noodle_stall"); m.base()
    m.box((-10.0, 14.5, 0), (4.1, 20.4, 41), "teal")
    m.box((0, 7.0, 0), (24, 5.4, 41), "worn")
    arched_roof(m, spring=22.4, rise=7.2, material="teal")
    m.box((1.0, 11.3, 0), (25, .8, 38), "metal", "equipment")
    m.box((12.3, 11.2, 0), (3.4, .7, 39), "worn", "equipment")
    m.box((12.0, 21.5, 0), (1, 2.5, 37), "shutter", "equipment")
    m.plate((12.65, 22.8, 0), 18, 1.6, "x", "sign")
    m.plate((12.7, 20.0, 0), 24, .45, "x", "amber")
    # Two large stockpots, lids, handles, and a separate broth boiler.
    for zz in (-8, 7):
        m.cylinder((7, 11.9, zz), (7, 16.6, zz), 2.55, "metal", 12)
        m.cylinder((7, 16.6, zz), (7, 17.0, zz), 2.75, "worn", 12)
        m.box((7, 17.35, zz), (.65, .7, 1.4), "dark", "details")
        for side in (-1, 1):
            m.beam((7, 15.7, zz+side*2.6), (7, 15.7, zz+side*3.6), .45)
    m.bevel((-1.5, 15, -15.8), (8.5, 6.2, 6), .5, "worn")
    m.tube([(3, 14, -16), (5.0, 14, -16), (5.0, 12.3, -16)], .25)
    for zz in (-12, -4, 4, 12):
        m.box((-7.1, 18.5, zz), (1, .4, 5.1), "metal", "details")
        m.cylinder((-6, 18.8, zz), (-6, 20.2, zz), .7, "paint", 8, "details")
    m.plate((12.8, 16.2, 17.8), 3.6, 6.2, "x", "menu")
    # Folded stool seats are bolted within the road width, not on the pavement.
    for zz in (-12, 0, 12):
        m.cylinder((12.7, 7.3, zz), (13.5, 7.3, zz), 1.8,
                   "worn", 10, "details", cap="teal")
        m.box((12.1, 5.4, zz), (.8, 3.5, .6), "metal", "details")
    m.cylinder((-6, 28, 15), (-6, 33.4, 15), 1.6, "metal", 10)
    m.cylinder((-6, 33.4, 15), (-6, 33.9, 15), 2.3, "worn", 10)
    staff(m, (-3.0, 10.5, 0), scale=.72, shirt="paint")
    m.features = ["ribbed barrel roof and noodle-counter recess", "paired stockpots and broth boiler",
                  "folded stools, small clothed cook and extractor"]
    return m


def casino():
    m = Mesh("mobile_casino"); m.base()
    m.bevel((-7, 15.7, 0), (11, 23, 42), 1.1, "teal")
    m.box((0, 6.4, 0), (25, 4.3, 42), "metal")
    for zz in (-13.5, 0, 13.5):
        m.bevel((4.5, 15.7, zz), (13, 17, 11), .7, "worn")
        m.box((11.3, 18.6, zz), (.6, 8, 8.5), "dark", "equipment")
        m.plate((11.68, 18.6, zz), 6.7, 6.0, "x", "window")
        # Physical reel strips and buttons are readable without a new texture.
        for dz in (-2, 0, 2):
            m.plate((11.9, 18.5, zz+dz), 1.25, 4.4, "x", "sign")
        m.prism([(11.2, zz-4.6), (12.4, zz-4.6), (12.4, zz+4.6), (11.2, zz+4.6)],
                (11, 13.2), "x", "metal", part="equipment")
        for dz in (-2.7, 0, 2.7):
            m.cylinder((12.8, 12.55, zz+dz), (12.8, 12.9, zz+dz),
                       .38, "amber", 8, "details")
        m.box((12.0, 9.0, zz), (1.7, 1, 4.5), "dark", "details")
    # Side-facing, protected jackpot marquee with a stepped hood.
    m.prism([(25.0, -22), (29.7, -21), (33.1, -15), (33.1, 16),
             (30.5, 22), (25, 22)], (-11.7, 11.7), "x", "worn", side="metal")
    m.plate((11.85, 28.8, 0), 35, 4.4, "x", "sign")
    for zz in range(-18, 19, 4):
        m.box((12.15, 32.1, zz), (.6, .65, .65), "amber", "details")
    # Small rear roulette table in a protective recess.
    m.box((0, 10.7, -21.4), (20, 1.2, 3.3), "metal", "equipment")
    m.cylinder((0, 11.4, -19.5), (0, 12, -19.5), 3.5,
               "metal", 16, cap="dark")
    for i in range(12):
        a, b = i*math.tau/12, (i+1)*math.tau/12
        m.face([(0, 12.05, -19.5),
                (3.0*math.cos(a), 12.05, -19.5+3*math.sin(a)),
                (3.0*math.cos(b), 12.05, -19.5+3*math.sin(b))],
               "worn" if i%2 else "dark", "details", (0, 1, 0))
    m.cylinder((0, 12.1, -19.5), (0, 13.0, -19.5), .4, "metal", 8)
    m.grille((-12.7, 16, 4), 25, 12, "x", 8)
    m.features = ["three physical slot-machine stations", "stepped illuminated jackpot marquee",
                  "small roulette wheel and protected cashier hardware"]
    return m


def strip_club():
    m = Mesh("mobile_strip_club"); m.base()
    arched_roof(m, half_width=12.7, spring=22.7, rise=8.2,
                z0=-21.2, z1=21.2, material="worn", ribs=5)
    m.box((-11.8, 13.5, 0), (1.8, 18.5, 40), "teal")
    m.box((0, 5.5, 0), (25.6, 2.5, 40), "dark", "equipment")
    # A narrow public opening framed by folded dark drapes, not a glass box.
    for zz in (-17.9, -16.8, 16.8, 17.9):
        m.cylinder((8, 6.8, zz), (8, 22.6, zz), .73,
                   "dark", 7, "details")
    for zz in range(-17, 18, 3):
        m.cylinder((-10.7, 6.9, zz), (-10.7, 23.0, zz), .65,
                   "dark", 6, "details")
    m.cylinder((7.3, 6.8, 0), (7.3, 23.0, 0), .34, "metal", 10)
    for yy in (7, 22.7):
        m.cylinder((7.3, yy, 0), (7.3, yy+.25, 0), .8, "worn", 10)
    m.box((12.1, 23.0, 0), (2.3, .7, 37), "teal", "equipment")
    m.plate((13.35, 23, 0), 31, .45, "x", "redlamp")
    # Sign is an existing atlas graphic; no bespoke bitmap is introduced.
    m.box((8.9, 28, 0), (1.0, 5.5, 26), "metal", "equipment")
    m.plate((9.48, 28, 0), 23, 3.9, "x", "sign")
    for zz in (-18, -12, -6, 0, 6, 12, 18):
        m.box((12.7, 7.1, zz), (.6, .5, 1.0), "redlamp", "details")
    # A folded access step and fully clothed adult stage silhouette.
    m.box((12.8, 5.4, 11), (1.6, 2.7, 7), "metal", "equipment")
    m.box((13.5, 6.2, 11), (.8, .35, 6), "hazard", "details")
    staff(m, (1.2, 6.8, 6.0), pose="raised", scale=.78, shirt="teal")
    for zz in (-14, 14):
        m.bevel((-7, 28.5, zz), (7, 6, 8), .7, "metal")
        m.grille((-3.4, 28.5, zz), 6.4, 4.0, "x", 4)
    m.features = ["rounded cabaret shell and shutter frame", "small pole stage with dark curtains",
                  "clothed adult performer, footlights and folded access step"]
    return m


def bar():
    m = Mesh("mobile_bar"); m.base()
    m.box((-10.2, 15.2, 1), (4.8, 21.8, 39), "teal")
    m.box((0, 7.3, 1), (25, 5.8, 39), "worn")
    for zz in (-18.3, 20.3):
        m.box((0, 15, zz), (25, 19, 1.3), "metal")
    m.box((1.0, 12.0, 1), (25, 1.0, 37), "metal", "equipment")
    m.box((12.1, 11.8, 1), (3.8, .8, 38), "worn", "equipment")
    # Strong one-sided sloping canopy, with a warmer service recess below.
    m.prism([(-12.7, 29.5), (-12.7, 31), (13.6, 25.6), (13.6, 24.4)],
            (-20, 22), "z", "teal", side="metal")
    m.plate((13.7, 24.5, 0), 30, .45, "x", "amber")
    for yy in (15.1, 19.1):
        m.box((-6.8, yy, 1), (3.8, .4, 32), "metal", "equipment")
        for zz in range(-13, 16, 4):
            m.cylinder((-5.4, yy+.3, zz), (-5.4, yy+2.1, zz), .55,
                       "window", 7, "details")
            m.cylinder((-5.4, yy+2.1, zz), (-5.4, yy+2.8, zz), .25,
                       "metal", 7, "details")
    for zz in (-9, 0, 9):
        m.tube([(9, 12.5, zz), (9, 16.4, zz), (11.0, 16.4, zz),
                (11.0, 15.4, zz)], .32, "metal", 6)
        m.box((9, 17.4, zz), (.65, 1.9, .75), "worn", "details")
    # Paired keg backs distinguish this silhouette from both food stalls.
    for xx in (-7.5, 3.5):
        m.cylinder((xx, 4.6, -19.5), (xx, 14.2, -19.5), 3.0,
                   "worn", 12, cap="metal")
        for yy in (5.5, 9.0, 13.2):
            m.cylinder((xx, yy, -19.5), (xx, yy+.5, -19.5), 3.16,
                       "metal", 12, "details")
    m.bevel((-6.5, 30.2, 13), (8.5, 7.0, 12), .7, "metal")
    m.grille((-2.1, 30.5, 13), 9.8, 4.6, "x", 5)
    m.plate((10.1, 26.7, 8), 13, 2.2, "x", "sign")
    staff(m, (-1.0, 5.0, 1.0), scale=.94, shirt="dark")
    m.features = ["asymmetric canopy and long bar counter", "three taps and bottle shelves",
                  "paired keg cradles and clothed adult bartender"]
    return m


def speaker(m, z):
    m.bevel((-9.3, 19.0, z), (6.6, 27, 7.1), .65, "dark")
    for yy, rr in ((10.1, 2.5), (17.0, 2.5), (24.0, 1.8)):
        # One coarse recessed cone carries the readable circular form; the
        # existing dark/vent atlas patches supply its fine grille detail.
        m.cylinder((-5.9, yy, z), (-5.55, yy, z), rr,
                   "dark", 8, cap="vent", r2=rr*.55)
    m.plate((-5.8, 29.4, z), 3.1, 1.8, "x", "vent")


def band():
    m = Mesh("mobile_band_stage"); m.base()
    m.box((0, 5.2, 0), (26, 1.3, 44), "dark", "equipment")
    # Open front and a half-retracted rear canopy keep the band visible from
    # normal RTS camera elevation. There is no additional wheeled trailer.
    for zz in (-19.3, 19.3):
        speaker(m, zz)
        m.beam((-11.8, 5.4, zz), (-11.8, 33.4, zz), .8, "metal")
        m.beam((-11.8, 33.1, zz), (12.3, 33.1, zz), .7, "metal")
    m.box((-7.9, 33.2, 0), (9.5, 1.0, 44), "teal", "equipment")
    m.beam((12.3, 33.1, -21), (12.3, 33.1, 21), .7, "metal")
    for zz in (-13, 0, 13):
        m.cylinder((8.5, 32.4, zz), (9.4, 31.0, zz), .7,
                   "dark", 8, "details", cap="redlamp")
    # Compact drum kit: bass drum, two toms, snare, and small cymbals.
    m.cylinder((-3.3, 9.2, 3.4), (-.2, 9.2, 3.4), 3.25,
               "teal", 12, cap="paint")
    for zz in (-.2, 6.4):
        m.cylinder((-3, 12, zz), (-3, 14.2, zz), 1.65,
                   "metal", 10, cap="paint")
    m.cylinder((-4.8, 10.8, -2.6), (-4.8, 12.1, -2.6), 1.8,
               "metal", 10, cap="paint")
    for xx, zz, yy in ((-1, -3.6, 17), (-3.5, 9.6, 17.8)):
        m.beam((xx, 5.9, zz), (xx, yy, zz), .25, "metal")
        m.cylinder((xx, yy, zz), (xx, yy+.18, zz), 2.45,
                   "worn", 12, "details")
        for off in (-1.4, 1.4):
            m.beam((xx, 7, zz), (xx+off, 5.9, zz+off), .22)
    staff(m, (-7.7, 6.0, 3.4), pose="seated", scale=.92, shirt="dark")
    for zz in (1.1, 5.7):
        m.beam((-3.3, 14.5, zz), (-.6, 15.6, zz+.6), .12, "paint")
    # Guitarist, instrument body, neck, microphone and a floor amplifier.
    staff(m, (5.0, 5.9, -9.5), pose="guitar", scale=.93, shirt="worn")
    m.bevel((7.9, 16.0, -10.4), (1.1, 4.7, 3.5), .8,
            "teal", "details", edge="metal")
    m.beam((8.1, 16.3, -9.5), (8.1, 21.6, -4.7), .55, "worn")
    m.box((8.1, 21.9, -4.4), (1.0, 1.2, .7), "metal", "details")
    m.beam((10.5, 5.9, -6), (10.5, 22.3, -6), .24, "metal")
    m.beam((10.5, 22.3, -6), (7.0, 22.3, -7), .28, "dark")
    m.bevel((9.3, 7.7, -16), (5.2, 3.4, 5.2), .3, "dark")
    m.plate((12.0, 7.8, -16), 3.8, 2.4, "x", "vent")
    # Keyboardist: the keyboard is a real solid object; its small key detail
    # reuses a striped shutter island instead of dozens of separate key boxes.
    staff(m, (3.2, 5.9, 12), scale=.91, shirt="teal")
    m.box((8.3, 16.1, 11.5), (3.2, 1.1, 10.1), "dark", "equipment")
    m.face([(8.5, 16.71, 6.8), (9.7, 16.71, 6.8),
            (9.7, 16.71, 16.2), (8.5, 16.71, 16.2)],
           "shutter", "details", (0, 1, 0))
    m.beam((8.3, 15.6, 7.5), (8.3, 6.0, 15.5), .45)
    m.beam((8.3, 15.6, 15.5), (8.3, 6.0, 7.5), .45)
    m.box((12.7, 5.3, 0), (1.0, .4, 37), "hazard", "details")
    m.features = ["open truck-mounted stage and twin speaker towers",
                  "three clothed adult musicians with drums, guitar and keyboard",
                  "half-retracted canopy, lamps, amplifiers and microphone"]
    return m


ADDITIONAL_SPECS = [
    (crematorium, "Mobile Crematorium"),
    (noodles, "Noodle Stall"),
    (casino, "Mobile Casino"),
    (strip_club, "Mobile Strip Club"),
    (bar, "Mobile Bar"),
    (band, "Mobile Band Stage"),
]
