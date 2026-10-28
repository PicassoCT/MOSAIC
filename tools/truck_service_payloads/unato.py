"""Approved UNATO ration module, with four real mating stack contacts.

All markings sample the existing Asian-house atlas. The five UNATO glyphs are
flat UV-mapped faces cut from its food poster; no texture or extruded text is
generated. This module does not change any material used by the first twelve
payloads. Stacking is a geometry contract, not a new runtime unit behavior.
"""

from generate import ATLAS, FLOOR, Mesh


def atlas_pixels(x0, y0, x1, y1):
    return tuple(v / 4096 for v in (x0, y0, x1, y1))


# Quiet blue paint sampled below the label of an existing industrial cabinet.
# Its special-map red channel averages 1.2/255, avoiding an emissive body band.
ATLAS["unato_blue"] = atlas_pixels(3370, 949, 3390, 967)

# Existing uppercase food-poster letters. Their original warm/red backing is
# intentionally retained as a small illuminated administrative placard, rather
# than pretending the atlas contains the concept's white-on-blue UNATO stencil.
for letter, bounds in {
    "U": (889, 1502, 918, 1539),
    "N": (863, 1470, 886, 1501),
    "A": (782, 1470, 806, 1501),
    "T": (806, 1470, 829, 1501),
    "O": (839, 1470, 863, 1501),
}.items():
    ATLAS["unato_glyph_" + letter] = atlas_pixels(*bounds)


STACK = {
    "pitch_y": 28.0,
    "bottom_plane_y": FLOOR,
    "top_plane_y": 30.1,
    "contacts": [
        {"center_xz": [x, z], "size_xz": [3.6, 4.4]}
        for x in (-12.2, 12.2) for z in (-21.8, 21.8)
    ],
    "max_equipment_y": 29.0,
    "rationale": [
        "Four solid corner columns join aligned lower feet to flat roof pads.",
        "Only the four feet reach the bottom plane; the skid deck starts at y=3.3.",
        "Roof ventilation, awning and all geometry outside the contact footprints stay below y=29.0.",
        "A copy translated by +28.0 Y meets all four roof pads at y=30.1 without volume overlap.",
        "The exported piece is one module; no automatic stacking or additional runtime actor is introduced.",
    ],
}


def front_placard(m, center, width=14.0, height=2.7):
    """Five readable atlas glyphs, facing +X; ten triangles in total."""
    x, y, z = center
    gap = .12
    char_width = (width - 4 * gap) / 5
    # On a +X-facing surface, screen-right is -Z. Explicit UVs keep the
    # letters upright and preserve their order rather than relying on the
    # primitive helper's generic dominant-plane projection.
    for i, letter in enumerate("UNATO"):
        right = z + width / 2 - i * (char_width + gap)
        left = right - char_width
        u0, v0, u1, v1 = ATLAS["unato_glyph_" + letter]
        points = [(x, y-height/2, right), (x, y-height/2, left),
                  (x, y+height/2, left), (x, y+height/2, right)]
        uv = [(u0, 1-v1), (u1, 1-v1), (u1, 1-v0), (u0, 1-v0)]
        m.face(points, "unato_glyph_" + letter, "details", (1, 0, 0), uv)


def ration_bay(m, z):
    """A genuinely recessed collection bay, with a small token/status face."""
    # The mechanical back sits well behind the upper reader face, so the
    # dispensing opening remains visibly hollow from both oblique sides.
    m.box((5.0, 14.0, z), (.6, 8.0, 10.2), "dark", "equipment")
    m.box((8.25, 20.0, z), (.9, 6.6, 10.2), "paint", "equipment")
    for zz in (z-4.55, z+4.55):
        m.box((7.9, 13.5, zz), (1.6, 6.2, 1.1), "metal", "equipment")
    m.box((8.15, 16.55, z), (1.1, .45, 8.3), "metal", "equipment")
    m.box((8.15, 10.6, z), (1.1, .5, 8.3), "metal", "equipment")
    # Shallow collection tray and a single sealed meal packet. The packet's
    # band is a texture face; no lettering or seams are extruded.
    m.box((10.6, 10.95, z), (4.6, .45, 8.4), "metal", "equipment")
    for zz in (z-4.0, z+4.0):
        m.box((10.6, 11.3, zz), (4.6, .35, .35), "metal", "equipment")
    m.box((12.75, 11.3, z), (.3, .35, 8.4), "metal", "equipment")
    m.bevel((10.7, 11.65, z), (2.8, .8, 4.3), .28,
            "paint", "equipment", edge="paint")
    m.plate((10.7, 12.06, z), .9, 3.9, "y", "unato_blue",
            normal=(0, 1, 0))
    # Broad texture faces provide the UI, reader plate and tiny status lamps.
    m.box((8.78, 20.15, z+.85), (.24, 3.9, 5.3), "metal", "details")
    m.plate((8.92, 20.15, z+.85), 4.9, 3.5, "x", "dark",
            normal=(1, 0, 0))
    m.plate((8.94, 20.15, z+.85), 2.2, 2.2, "x", "medical",
            normal=(1, 0, 0))
    m.plate((8.72, 19.8, z-3.2), 1.5, 4.5, "x", "door",
            normal=(1, 0, 0))
    m.plate((8.74, 22.9, z-3.2), 1.5, .55, "x", "amber",
            normal=(1, 0, 0))
    m.plate((8.72, 17.3, z+.85), 3.5, .5, "x", "warning",
            normal=(1, 0, 0))


def unato_rations():
    m = Mesh("unato_rations")
    # Unlike the ordinary common base, four independent feet establish the
    # lowest plane. Their solid posts provide continuous corner load paths.
    for contact in STACK["contacts"]:
        x, z = contact["center_xz"]
        m.box((x, 2.7, z), (3.6, 1.2, 4.4), "metal", "skid")
        m.box((x, 16.325, z), (2.2, 26.05, 2.2), "metal", "body")
        m.box((x, 29.725, z), (3.6, .75, 4.4), "metal", "body")
        # A narrow existing warning stripe identifies the structural foot.
        m.plate((x, 2.75, z + (2.21 if z > 0 else -2.21)),
                2.2, .65, "z", "hazard", normal=(0, 0, 1 if z > 0 else -1))
    m.box((0, 4.0, 0), (28.0, 1.4, 48.0), "metal", "skid", top="worn")
    for x in (-13.4, 13.4):
        m.box((x, 4.4, 0), (1.2, 2.2, 43.2), "metal", "skid")
    for z in (-23.4, 23.4):
        m.box((0, 4.4, z), (24.0, 2.2, 1.2), "metal", "skid")

    # Cabinet rear and end shells, with major roof bevels kept as geometry.
    m.box((-11.5, 16.45, 0), (1.2, 22.5, 40.0), "paint", "body")
    end_profile = [(-11.8, 5.2), (11.8, 5.2), (11.8, 25.4),
                   (9.5, 27.7), (-9.5, 27.7), (-11.8, 25.4)]
    for z0 in (-20.1, 19.0):
        m.prism(end_profile, (z0, z0+1.1), "z", "paint", "body", "worn")
    m.box((-3.45, 15.9, 0), (14.5, 21.4, 37.8), "worn", "body")
    m.box((0, 27.4, 0), (23.4, .6, 40.2), "paint", "body")

    # Solid front apron, top header and divider pillars surround two real
    # apertures; neither opening is a black sticker on a solid box.
    m.box((8.6, 7.6, 0), (6.4, 4.8, 40.0), "paint", "body")
    m.box((8.6, 25.65, 0), (6.4, 4.1, 40.0), "paint", "body")
    m.box((8.6, 16.8, -18.225), (6.4, 13.6, 3.55), "paint", "body")
    m.box((8.6, 16.8, -4.7), (6.4, 13.6, 2.9), "paint", "body")
    m.box((8.6, 16.8, 13.625), (6.4, 13.6, 12.75), "paint", "body")
    for z in (-11.3, 2.0):
        ration_bay(m, z)

    # Existing atlas paint provides the UNATO identity band on every shell
    # face. The small warm-backed UNATO placard is five reused poster glyphs.
    m.plate((-12.12, 21.3, 0), 39.0, 5.0, "x", "unato_blue",
            normal=(-1, 0, 0))
    for z, normal in ((-20.12, (0, 0, -1)), (20.12, (0, 0, 1))):
        m.plate((0, 21.3, z), 22.5, 5.0, "z", "unato_blue", normal=normal)
    m.plate((11.82, 25.65, 0), 39.0, 3.45, "x", "unato_blue",
            normal=(1, 0, 0))
    m.box((11.86, 25.55, -4.6), (.12, 3.15, 14.5), "metal", "details")
    front_placard(m, (11.94, 25.55, -4.6))

    # A slim refill door is proud of the closed front service compartment.
    m.bevel((11.95, 16.5, 14.1), (.5, 18.0, 8.6), .2,
            "paint", "equipment", edge="metal")
    m.plate((12.22, 16.6, 14.1), 7.3, 14.7, "x", "door",
            normal=(1, 0, 0))
    m.plate((12.25, 23.55, 14.1), 5.7, .75, "x", "warning",
            normal=(1, 0, 0))

    # The shallow awning projects only to the common bed edge. Its pitched
    # profile remains far below the upper pads, even when stacked two high.
    canopy = [(10.6, 24.15), (13.95, 23.15),
              (14.05, 23.5), (10.6, 24.55)]
    m.prism(canopy, (-17.25, 7.9), "z", "paint", "equipment", "metal")
    for z in (-16.8, 7.45):
        m.beam((11.2, 20.7, z), (13.5, 23.2, z), .35, "metal")

    # Flat roof frame and recessed low-profile ventilation: all equipment is
    # below y29; the only higher structures are the four aligned load paths.
    for x in (-12.2, 12.2):
        m.box((x, 28.55, 0), (1.1, .9, 39.2), "metal", "body")
    for z in (-21.8, 21.8):
        m.box((0, 28.55, z), (20.8, .9, 1.1), "metal", "body")
    m.bevel((-2.6, 28.25, -5.8), (10.0, 1.1, 11.0), .3,
            "metal", "equipment", edge="metal")
    m.plate((-2.6, 28.82, -5.8), 8.4, 9.1, "y", "vent",
            normal=(0, 1, 0))
    m.plate((-12.14, 11.7, 10.0), 7.0, 6.0, "x", "vent",
            normal=(-1, 0, 0))

    # A folded queue rail stays against the rear shell inside the skid.
    for x in (-8.6, 8.6):
        m.beam((x, 5.8, -21.1), (x, 12.3, -21.1), .55, "metal")
    for y in (7.0, 10.9):
        m.beam((-8.6, y, -21.1), (8.6, y, -21.1), .55, "metal")

    m.features = [
        "two recessed ration dispensing bays with token/status faces and meal trays",
        "off-white cabinet, low-emission blue band and five atlas-sampled UNATO glyphs",
        "shallow serving awning, refill door and folded queue rail",
        "four continuous corner supports with aligned flat stacking pads",
    ]
    m.stack = STACK
    return m


UNATO_SPECS = [(unato_rations, "UNATO Ration Dispenser")]
