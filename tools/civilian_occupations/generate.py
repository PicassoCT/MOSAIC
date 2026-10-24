#!/usr/bin/env python3
"""Build the two street-civilian placeholder meshes and their shared atlas.

The existing civilian rig is deliberately retained byte-for-byte at the node
matrix level.  This matters because civilianscript.lua plays authored piece
rotations and source-space translations, rather than a retargetable skin rig.
Only the NEW assets are generated; no reference civilian is modified.

Requirements: Python 3, numpy, Pillow.  Run from any directory.
The concept sheets are art direction, not texture projections.  Geometry and
occupational materials are authored below; legacy functional props retain
their shapes/UVs in the upper-left atlas island.  The two disproportionately
expensive weapon props and carried baby get deliberately low-poly meshes.
"""
from __future__ import annotations

import copy
import json
import math
from pathlib import Path
import xml.etree.ElementTree as ET

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "objects3d/civilian0_western.dae"
NS_URI = "http://www.collada.org/2005/11/COLLADASchema"
NS = {"c": NS_URI}
ET.register_namespace("", NS_URI)
ATLAS_SIZE = 1024
TEX_DIFFUSE = "civ_occupations_diffuse.png"
TEX_SPECIAL = "civ_occupations_special.png"
TEX_NORMAL = "civ_occupations_normal.png"
MATERIAL = "civ_occupations_material"
ANATOMY = [
    "center", "UpBody", "Head1", "UpArm1", "UpArm2", "LowArm1", "LowArm2",
    "Hand1", "Hand2", "UpLeg1", "UpLeg2", "LowLeg1", "LowLeg2", "Feet1", "Feet2",
]

# RGB, reflectivity, self illumination.  Diffuse alpha is zero throughout:
# neither ordinary Gaia citizens nor their equipment should acquire team tint.
PALETTE = {
    "indigo": ((39, 48, 64), 24, 0),
    "indigo_light": ((55, 65, 79), 24, 0),
    "yellow": ((194, 155, 49), 24, 0),
    "silver": ((166, 174, 172), 115, 0),
    "rubber": ((28, 31, 33), 12, 0),
    "leather": ((81, 65, 43), 30, 0),
    "skin_worker": ((183, 139, 111), 20, 0),
    "skin_courier": ((197, 155, 125), 20, 0),
    "hair_worker": ((54, 45, 37), 12, 0),
    "hair_courier": ((29, 30, 31), 18, 0),
    "burgundy": ((80, 43, 46), 16, 0),
    "teal": ((63, 89, 95), 28, 0),
    "teal_light": ((84, 106, 111), 28, 0),
    "trousers": ((54, 57, 59), 20, 0),
    "trousers_light": ((70, 74, 75), 20, 0),
    "ochre": ((174, 126, 43), 22, 0),
    "ochre_light": ((199, 153, 61), 22, 0),
    "strap": ((42, 39, 32), 22, 0),
    "metal": ((112, 123, 126), 100, 0),
    "cyan": ((34, 167, 180), 42, 110),
    "paper": ((181, 172, 147), 10, 0),
    "red_label": ((139, 65, 48), 10, 0),
    "eye": ((39, 34, 30), 35, 0),
    "eye_white": ((186, 175, 155), 25, 0),
    "gunmetal": ((54, 60, 59), 55, 0),
    "wood": ((96, 57, 35), 18, 0),
    "baby_clothes": ((116, 133, 131), 15, 0),
    "orange": ((163, 91, 40), 25, 0),
}
SWATCHES = {}
for i, name in enumerate(PALETTE):
    x, y = 512 + (i % 4) * 128, (i // 4) * 128
    SWATCHES[name] = ((x + 8) / 1024, 1 - (y + 120) / 1024,
                      (x + 120) / 1024, 1 - (y + 8) / 1024)


def tag(name):
    return "{" + NS_URI + "}" + name


def element(parent, tag_name, text=None, **attributes):
    child = ET.SubElement(parent, tag(tag_name), {k: str(v) for k, v in attributes.items()})
    if text is not None:
        child.text = text
    return child


def unit(vector):
    vector = np.asarray(vector, dtype=float)
    return vector / np.linalg.norm(vector)


def vector_text(values):
    return " ".join(f"{float(v):.7f}" for v in np.asarray(values).ravel())


class Mesh:
    """Triangle soup with flat normals and nondegenerate UVs per face."""

    def __init__(self):
        self.positions, self.normals, self.uvs = [], [], []

    def triangle(self, a, b, c, color, outward=None):
        a, b, c = map(lambda p: np.asarray(p, dtype=float), (a, b, c))
        cross = np.cross(b - a, c - a)
        if np.linalg.norm(cross) < 1e-9:
            return
        if outward is not None and np.dot(cross, outward) < 0:
            b, c = c, b
            cross = -cross
        normal = unit(cross)
        u0, v0, u1, v1 = SWATCHES[color]
        self.positions.extend((a, b, c))
        self.normals.extend((normal, normal, normal))
        self.uvs.extend(((u0, v0), (u1, v0), ((u0 + u1) / 2, v1)))

    def quad(self, a, b, c, d, color, outward):
        self.triangle(a, b, c, color, outward)
        self.triangle(a, c, d, color, outward)

    def box(self, center, size, color, axes=None):
        center, size = np.asarray(center, float), np.asarray(size, float) / 2
        axes = np.eye(3) if axes is None else np.asarray(axes, float)
        points = [center + axes @ (size * signs) for signs in
                  ((-1, -1, -1), (1, -1, -1), (1, 1, -1), (-1, 1, -1),
                   (-1, -1, 1), (1, -1, 1), (1, 1, 1), (-1, 1, 1))]
        for indices, normal in (
            ((0, 3, 2, 1), (0, 0, -1)), ((4, 5, 6, 7), (0, 0, 1)),
            ((0, 4, 7, 3), (-1, 0, 0)), ((1, 2, 6, 5), (1, 0, 0)),
            ((0, 1, 5, 4), (0, -1, 0)), ((3, 7, 6, 2), (0, 1, 0)),
        ):
            self.quad(*(points[i] for i in indices), color, axes @ normal)

    def rings(self, centers, radii, color, sides=10, axes=None, caps=True):
        centers = np.asarray(centers, float)
        if axes is None:
            direction = unit(centers[-1] - centers[0])
            u = unit(np.cross(direction, [0, 0, 1]))
            v = unit(np.cross(u, direction))
        else:
            u, v = map(lambda a: np.asarray(a, float), axes)
            direction = unit(np.cross(v, u))
        rings = []
        for center, (ru, rv) in zip(centers, radii):
            rings.append([center + math.cos(i * 2 * math.pi / sides) * ru * u
                          + math.sin(i * 2 * math.pi / sides) * rv * v
                          for i in range(sides)])
        for j in range(len(rings) - 1):
            for i in range(sides):
                ni = (i + 1) % sides
                outward = (rings[j][i] + rings[j][ni] - 2 * centers[j])
                self.quad(rings[j][i], rings[j][ni], rings[j + 1][ni], rings[j + 1][i], color, outward)
        if caps:
            for ring, center, normal in ((rings[0], centers[0], -direction),
                                         (rings[-1], centers[-1], direction)):
                for i in range(sides):
                    self.triangle(center, ring[i], ring[(i + 1) % sides], color, normal)

    def limb(self, start, end, radius_start, radius_end, color, sides=10):
        start, end = np.asarray(start, float), np.asarray(end, float)
        delta = end - start
        self.rings([start, start + delta * .15, start + delta * .78, end],
                   [(radius_start * .78, radius_start * .75),
                    (radius_start, radius_start * .85),
                    (radius_end, radius_end * .86),
                    (radius_end * .83, radius_end * .75)], color, sides)

    def ellipsoid(self, center, radius, color, sides=12, levels=7):
        center, radius = np.asarray(center, float), np.asarray(radius, float)
        rings = []
        for j in range(1, levels):
            latitude = -math.pi / 2 + math.pi * j / levels
            rings.append([center + radius * np.array([
                math.cos(latitude) * math.cos(i * 2 * math.pi / sides),
                math.sin(latitude), math.cos(latitude) * math.sin(i * 2 * math.pi / sides)])
                for i in range(sides)])
        for j in range(len(rings) - 1):
            for i in range(sides):
                ni = (i + 1) % sides
                self.quad(rings[j][i], rings[j][ni], rings[j + 1][ni], rings[j + 1][i], color,
                          (rings[j][i] + rings[j + 1][ni]) / 2 - center)
        for ring, pole in ((rings[0], center - [0, radius[1], 0]),
                           (rings[-1], center + [0, radius[1], 0])):
            for i in range(sides):
                self.triangle(pole, ring[i], ring[(i + 1) % sides], color,
                              (pole + ring[i] + ring[(i + 1) % sides]) / 3 - center)

    def panel(self, center, size, color):
        self.box(center, size, color)

    def beveled_box(self, center, size, color, bevel=.22):
        center, half = np.asarray(center, float), np.asarray(size, float) / 2
        rings = []
        for y, inset in ((-half[1], bevel), (-half[1] + bevel, 0),
                         (half[1] - bevel, 0), (half[1], bevel)):
            x, z = half[0] - inset, half[2] - inset
            b = min(bevel, x * .3, z * .3)
            ring = [(-x + b, -z), (x - b, -z), (x, -z + b), (x, z - b),
                    (x - b, z), (-x + b, z), (-x, z - b), (-x, -z + b)]
            rings.append([center + [rx, y, rz] for rx, rz in ring])
        for a, b in zip(rings, rings[1:]):
            for i in range(8):
                j = (i + 1) % 8
                outward = (a[i] + a[j]) / 2 - center
                outward[1] = 0
                self.quad(a[i], a[j], b[j], b[i], color, outward)
        for ring, normal in ((rings[0], [0, -1, 0]), (rings[-1], [0, 1, 0])):
            middle = np.mean(ring, axis=0)
            for i in range(8):
                self.triangle(middle, ring[i], ring[(i + 1) % 8], color, normal)


def read_rig(document):
    nodes, transforms, parents = {}, {}, {}
    unit_scale = float(document.find("c:asset/c:unit", NS).get("meter"))

    def walk(node, parent, transform):
        name = node.get("name")
        matrix = np.fromstring(node.find("c:matrix", NS).text, sep=" ").reshape(4, 4)
        world = transform @ matrix
        nodes[name], transforms[name], parents[name] = node, world, parent
        for child in node.findall("c:node", NS):
            walk(child, name, world)

    for node in document.findall("c:library_visual_scenes/c:visual_scene/c:node", NS):
        walk(node, None, np.diag([unit_scale, unit_scale, unit_scale, 1]))
    return nodes, transforms, parents


def draw_character(kind, transforms):
    worker = kind == "worker"
    meshes = {name: Mesh() for name in ANATOMY +
              ["Eye1", "Eye2", "Suit1", "Suit2", "Suit3", "Suit4", "Suit5", "Pistol", "ak47", "SittingBaby"]}
    p = {name: transform[:3, 3] for name, transform in transforms.items()}
    cloth = "indigo" if worker else "teal"
    pants = "indigo" if worker else "trousers"
    skin = "skin_worker" if worker else "skin_courier"
    hair = "hair_worker" if worker else "hair_courier"
    glove = "leather" if worker else "rubber"
    hip = meshes["center"]
    hip.rings([[-.1, 13.9, -.75], [-.1, 15.1, -.75], [-.1, 17.3, -.75]],
              [(2.3, 1.3), (2.65 if worker else 2.4, 1.75), (2.5, 1.6)], pants, 12)
    body = meshes["UpBody"]
    body.rings([[-.2, y, -.7] for y in [16.1, 17.3, 20.0, 22.8, 24.3, 25.3]],
               [(2.55, 1.65), (2.9 if worker else 2.65, 1.8),
                (3.1 if worker else 2.65, 1.8), (3.35 if worker else 2.95, 1.6),
                (3.0 if worker else 2.75, 1.45), (.9, .72)], cloth, 12)
    body.box([-.2, 18.0, 1.11], [.17, 6.0, .13], "metal" if worker else "strap")

    for side in (1, 2):
        shoulder, elbow, wrist = (p[f"{part}{side}"] for part in ("UpArm", "LowArm", "Hand"))
        meshes[f"UpArm{side}"].limb(shoulder, elbow, 1.22 if worker else 1.04, .98, cloth)
        meshes[f"LowArm{side}"].limb(elbow, wrist, 1.02 if worker else .9, .73, cloth)
        direction = unit(wrist - elbow)
        hand = meshes[f"Hand{side}"]
        hand.limb(wrist - direction * .2, wrist + direction * 1.5, .65, .48, glove, 8)
        # Four separated finger ends and a thumb retain a human hand silhouette.
        lateral = unit(np.cross(direction, [0, 0, 1]))
        for finger in range(4):
            start = wrist + direction * 1.13 + lateral * (finger - 1.5) * .22
            hand.limb(start, start + direction * (.65 - abs(finger - 1.5) * .08),
                      .16, .12, glove if worker else skin, 6)
        hand.limb(wrist + np.array([0, 0, .36]), wrist + direction * .75 + [0, 0, .75], .25, .16, glove, 6)

        upper, lower, ankle = (p[f"{part}{side}"] for part in ("UpLeg", "LowLeg", "Feet"))
        meshes[f"UpLeg{side}"].limb(upper + [0, .5, 0], lower, 1.35 if worker else 1.19, 1.0, pants, 12)
        leg = meshes[f"LowLeg{side}"]
        leg.limb(lower, ankle + [0, .3, 0], 1.08 if worker else .98, .85, pants, 12)
        # Knee and thigh cargo pockets are geometry, so they read in silhouette.
        sign = -1 if side == 1 else 1
        meshes[f"UpLeg{side}"].box([upper[0] + sign * 1.05, 11.6, -.7], [.42, 2.1, 1.45],
                                   "indigo_light" if worker else "trousers_light")
        leg.box([lower[0], 8.2, -.0], [1.5, 1.65, .5], "indigo_light" if worker else "trousers_light")
        if worker:
            leg.rings([[ankle[0], y, ankle[2]] for y in [3.25, 3.8]], [(1.0, .9), (1.0, .9)], "silver", 12)
        boot = meshes[f"Feet{side}"]
        boot.rings([[ankle[0], .18, -.0], [ankle[0], .7, .05], [ankle[0], 1.4, -.15], [ankle[0], 2.1, -.65]],
                   [(.98, 1.8), (.99, 1.8), (.88, 1.45), (.76, .88)], "rubber", 12,
                   axes=([1, 0, 0], [0, 0, 1]))
        boot.rings([[ankle[0], .08, .0], [ankle[0], .4, .0]], [(1.03, 1.85), (1.03, 1.85)], "strap", 12)
        for j in range(3):
            boot.box([ankle[0], 1.35 + j * .18, .25 - j * .3], [1.15, .1, .13], "metal" if worker else "strap")

    head = meshes["Head1"]
    hx, hz = p["Head1"][[0, 2]]
    head.rings([[hx, 24.8, hz], [hx, 26.3, hz]], [(.67, .66), (.73, .72)], skin, 10)
    head.ellipsoid([hx, 27.55, hz], [1.4 if worker else 1.27, 2.08, 1.22], skin, 16, 8)
    head.ellipsoid([hx, 27.3, hz + 1.14], [.34 if worker else .25, .52, .43], skin, 8, 5)
    for sign in (-1, 1):
        head.ellipsoid([hx + sign * 1.29, 27.5, hz], [.3, .55, .36], skin, 8, 5)
        # Brow lines and mouth are kept restrained at RTS scale.
        head.box([hx + sign * .53, 28.15, hz + 1.01], [.65, .13, .15], hair)
    head.box([hx, 26.5, hz + 1.12], [.68, .08, .09], "hair_worker" if worker else "red_label")
    for side, sign in ((1, -1), (2, 1)):
        eye = meshes[f"Eye{side}"]
        eye.ellipsoid([hx + sign * .51, 27.86, hz + 1.07], [.33, .14 if worker else .115, .12], "eye_white", 8, 4)
        eye.ellipsoid([hx + sign * .49, 27.86, hz + 1.17], [.13, .125 if worker else .1, .07], "eye", 8, 4)

    if worker:
        # Fit the vest to the torso cross-sections.  Bands use matching rings,
        # rather than billboards that would float in strict side views.
        body.rings([[-.2, y, -.7] for y in (16.3, 17.3, 20, 22.8, 24.25)],
                   [(2.77, 1.83), (3.02, 1.92), (3.22, 1.92), (3.47, 1.72), (3.16, 1.59)],
                   "yellow", 12)
        for y, width in ((17.4, 3.04), (19.4, 3.19)):
            body.rings([[-.2, y - .26, -.7], [-.2, y + .26, -.7]],
                       [(width + .025, 1.95), (width + .065, 1.95)], "silver", 12)
        for a, b in (([-.2, 16.4, 1.16], [-.2, 20.0, 1.25]),
                     ([-.2, 20.0, 1.25], [-.2, 24.1, .93])):
            a, b = np.asarray(a), np.asarray(b)
            y_axis = unit(b - a)
            axes = np.column_stack(([1, 0, 0], y_axis, np.cross([1, 0, 0], y_axis)))
            body.box((a + b) / 2, [.18, np.linalg.norm(b - a), .18], "indigo", axes)
        for sign in (-1, 1):
            for front in (True, False):
                a = np.array([sign * 1.85 - .2, 21.0, .93 if front else -2.33])
                b = np.array([sign * 1.85 - .2, 24.0, .65 if front else -2.05])
                y_axis = unit(b - a)
                axes = np.column_stack(([1, 0, 0], y_axis, np.cross([1, 0, 0], y_axis)))
                body.box((a + b) / 2, [.5, np.linalg.norm(b - a), .24], "silver", axes)
            body.box([sign * 1.6 - .2, 21.6, .8], [1.35, 1.5, .8], "ochre_light")
        body.ellipsoid([hx, 25.35, hz], [1.05, .6, 1.02], "burgundy", 12, 5)
        body.triangle([hx - .8, 25.5, hz + .9], [hx + .8, 25.5, hz + .9], [hx, 23.9, hz + 1.2], "burgundy", [0, 0, 1])
        head.ellipsoid([hx, 29.15, hz - .08], [1.5, .84, 1.37], "indigo", 16, 6)
        head.rings([[hx, y, hz + .72] for y in [28.94, 29.08]], [(1.5, 1.55), (1.5, 1.55)], "indigo", 12)
        head.ellipsoid([hx, 26.46, hz + .85], [.9, .32, .28], "hair_worker", 12, 4)
        pouch = meshes["center"]
        pouch.box([2.9, 14.5, .05], [1.15, 2.2, 1.25], "leather")
        pouch.box([2.9, 15.2, .74], [.95, .45, .16], "ochre")
        for x in (2.6, 3.1):
            pouch.limb([x, 14.8, .25], [x, 16.7, .25], .13, .14, "metal", 6)
            pouch.limb([x, 16.3, .25], [x, 16.95, .25], .23, .23, "orange", 6)
    else:
        # Hood folds, bun and a box pack give three complementary readable cues.
        body.ellipsoid([hx, 24.75, hz - 1.05], [1.5, .72, 1.0], "teal_light", 12, 5)
        head.ellipsoid([hx, 28.35, hz - .34], [1.35, 1.53, 1.16], hair, 16, 7)
        head.ellipsoid([hx, 29.3, hz - 1.35], [.77, .78, .8], hair, 12, 6)
        for sign in (-1, 1):
            head.limb([hx + sign * 1.0, 28.9, hz + .45],
                      [hx + sign * 1.16, 27.2, hz + .55], .24, .1, hair, 6)
        body.beveled_box([-.2, 21.9, -4.3], [6.4, 10.5, 3.3], "ochre", .25)
        body.beveled_box([-.2, 27.0, -4.3], [6.45, .42, 3.3], "ochre_light", .16)
        body.box([-.2, 25.6, -5.99], [5.9, .6, .16], "silver")
        body.box([-.2, 24.6, -6.0], [5.95, .65, .2], "rubber")
        body.box([-.2, 18.1, -6.0], [5.95, .8, .2], "rubber")
        body.box([-.2, 16.7, -4.3], [6.55, .55, 3.55], "rubber")
        for sign in (-1, 1):
            body.box([sign * 3.05 - .2, 21.9, -6.0], [.36, 10.0, .27], "rubber")
            for z in (-2.65, -5.95):
                body.box([sign * 3.08 - .2, 21.9, z], [.3, 10.0, .3], "strap")
            body.box([sign * 3.08 - .2, 20.4, -4.3], [.3, .4, 3.35], "strap")
            a = np.array([sign * 1.8 - .2, 18.0, .85])
            b = np.array([sign * 1.8 - .2, 23.8, .48])
            y_axis = unit(b - a)
            axes = np.column_stack(([1, 0, 0], y_axis, np.cross([1, 0, 0], y_axis)))
            body.box((a + b) / 2, [.52, np.linalg.norm(b - a), .5], "strap", axes)
            body.box([sign * 1.8 - .2, 22.8, .83], [.75, .65, .27], "metal")
        body.rings([[-.2, 21.12, -.7], [-.2, 21.5, -.7]], [(2.94, 1.92), (2.98, 1.92)], "strap", 12)
        body.rings([[-.2, 17.6, -.7], [-.2, 18.2, -.7]], [(2.79, 1.92), (2.79, 1.92)], "strap", 12)
        body.box([-.2, 17.9, 1.25], [.9, .76, .22], "metal")
        body.box([2.0, 22.2, -6.07], [.7, 1.35, .3], "rubber")
        body.box([2.0, 22.2, -6.24], [.4, .95, .06], "cyan")
        body.box([-.65, 20.4, -6.0], [1.7, 1.0, .14], "paper")
        body.box([-.65, 20.75, -6.09], [1.7, .23, .07], "red_label")
        body.box([-2.4, 17.0, .1], [.75, 1.8, .65], "strap")
        body.box([-2.4, 17.1, .47], [.4, .95, .1], "ochre_light")

    # Retain every optional clothing-piece name without changing the silhouette
    # to the reference citizen's outfit.  They become optional repair patches.
    for name in ("Suit1", "Suit2", "Suit3", "Suit4", "Suit5"):
        patch = meshes[name]
        point = p[name].copy()
        if name == "Suit1":
            point = np.array([1.5 if worker else -.8, 22.0 if worker else 19.1, 1.21 if worker else -6.0])
            patch.box(point, [.65, .65, .09], "indigo_light" if worker else "paper")
        else:
            point[2] += .94
            patch.box(point, [.75, .9, .12], "indigo_light" if worker else "silver")

    # Functional equipment remains opt-in via the unchanged civilian script.
    gun = meshes["ak47"]
    q = p["ak47"]
    gun.box(q + [1.0, .25, 0], [3.7, .55, .55], "gunmetal")
    gun.box(q + [-1.3, .05, 0], [1.3, .7, .5], "wood")
    gun.box(q + [.8, -.7, 0], [.55, 1.4, .45], "gunmetal")
    gun.limb(q + [2.7, .25, 0], q + [4.5, .25, 0], .16, .12, "gunmetal", 8)
    pistol = meshes["Pistol"]
    q = p["Pistol"]
    pistol.box(q + [.7, 0, 0], [1.6, .45, .45], "gunmetal")
    pistol.box(q + [.2, -.6, 0], [.45, .95, .4], "rubber")
    baby = meshes["SittingBaby"]
    q = p["SittingBaby"]
    baby.ellipsoid(q + [0, .5, 0], [.75, 1.05, .55], "baby_clothes", 10, 5)
    baby.ellipsoid(q + [0, 1.9, .1], [.65, .72, .6], "skin_courier", 12, 6)
    for sign in (-1, 1):
        baby.limb(q + [sign * .5, .7, 0], q + [sign * 1.0, -.1, .35], .25, .2, "baby_clothes", 6)
        baby.limb(q + [sign * .38, -.3, 0], q + [sign * .5, -1.0, .8], .3, .23, "baby_clothes", 6)
    return meshes


def write_geometry(geometry, mesh, world):
    for child in list(geometry):
        geometry.remove(child)
    container = element(geometry, "mesh")
    inverse = np.linalg.inv(world)
    positions = np.asarray(mesh.positions)
    local = (inverse @ np.column_stack((positions, np.ones(len(positions)))).T).T[:, :3]
    normals = (world[:3, :3].T @ np.asarray(mesh.normals).T).T
    normals /= np.linalg.norm(normals, axis=1)[:, None]
    ident = geometry.get("id")
    for suffix, data, labels in (("positions", local, ("X", "Y", "Z")),
                                 ("normals", normals, ("X", "Y", "Z")),
                                 ("uv", np.asarray(mesh.uvs), ("S", "T"))):
        source_id = ident + "-" + suffix
        source = element(container, "source", id=source_id)
        element(source, "float_array", vector_text(data), id=source_id + "-array", count=data.size)
        common = element(source, "technique_common")
        accessor = element(common, "accessor", source="#" + source_id + "-array", count=len(data), stride=len(labels))
        for label in labels:
            element(accessor, "param", name=label, type="float")
    vertices = element(container, "vertices", id=ident + "-vertices")
    element(vertices, "input", semantic="POSITION", source="#" + ident + "-positions")
    triangles = element(container, "triangles", count=len(local) // 3, material=MATERIAL)
    for offset, semantic, source in ((0, "VERTEX", ident + "-vertices"), (1, "NORMAL", ident + "-normals"), (2, "TEXCOORD", ident + "-uv")):
        element(triangles, "input", semantic=semantic, source="#" + source, offset=offset,
                **({"set": "0"} if semantic == "TEXCOORD" else {}))
    element(triangles, "p", " ".join(str(i) for i in np.repeat(np.arange(len(local)), 3)))


def remap_legacy_uvs(geometry):
    sources = {source.get("id"): source for source in geometry.findall("c:mesh/c:source", NS)}
    done = set()
    for triangles in geometry.findall("c:mesh/c:triangles", NS):
        triangles.set("material", MATERIAL)
        for inp in triangles.findall("c:input", NS):
            if inp.get("semantic") != "TEXCOORD" or inp.get("source") in done:
                continue
            done.add(inp.get("source"))
            source = sources[inp.get("source")[1:]]
            array = source.find("c:float_array", NS)
            stride = int(source.find("c:technique_common/c:accessor", NS).get("stride"))
            values = np.fromstring(array.text, sep=" ").reshape(-1, stride)
            values[:, 0] *= .5
            values[:, 1] = .5 + values[:, 1] * .5
            array.text = vector_text(values)


def replace_materials(document):
    for name in ("library_images", "library_effects", "library_materials"):
        existing = document.find("c:" + name, NS)
        if existing is not None:
            document.remove(existing)
    images = element(document, "library_images")
    image = element(images, "image", id="occupations-atlas", name="occupations-atlas")
    element(image, "init_from", "../unittextures/" + TEX_DIFFUSE)
    effects = element(document, "library_effects")
    effect = element(effects, "effect", id="occupations-effect")
    profile = element(effect, "profile_COMMON")
    surface = element(element(profile, "newparam", sid="atlas-surface"), "surface", type="2D")
    element(surface, "init_from", "occupations-atlas")
    sampler = element(element(profile, "newparam", sid="atlas-sampler"), "sampler2D")
    element(sampler, "source", "atlas-surface")
    lambert = element(element(profile, "technique", sid="common"), "lambert")
    element(element(lambert, "diffuse"), "texture", texture="atlas-sampler", texcoord="UVMap")
    materials = element(document, "library_materials")
    material = element(materials, "material", id=MATERIAL, name=MATERIAL)
    element(material, "instance_effect", url="#occupations-effect")
    for instance in document.findall(".//c:instance_geometry", NS):
        for old in instance.findall("c:bind_material", NS):
            instance.remove(old)
        technique = element(element(instance, "bind_material"), "technique_common")
        bound = element(technique, "instance_material", symbol=MATERIAL, target="#" + MATERIAL)
        element(bound, "bind_vertex_input", semantic="UVMap", input_semantic="TEXCOORD", input_set="0")


def write_atlas():
    # This is a model-material atlas, not an edit of either generated design sheet.
    diffuse = np.zeros((ATLAS_SIZE, ATLAS_SIZE, 4), dtype=np.uint8)
    diffuse[:, :, :3] = (35, 39, 43)
    legacy = Image.open(ROOT / "unittextures/western_civilian_diffuse.dds").convert("RGB")
    legacy = legacy.resize((512, 512), Image.Resampling.LANCZOS)
    diffuse[:512, :512, :3] = np.asarray(legacy)
    special = np.zeros_like(diffuse)
    special[:, :, 1] = 22
    special[:, :, 3] = 255
    rng = np.random.default_rng(13072026)
    yy, xx = np.mgrid[:128, :128]
    for i, (name, (rgb, reflection, emission)) in enumerate(PALETTE.items()):
        x, y = 512 + (i % 4) * 128, (i // 4) * 128
        grain = rng.integers(-5, 6, (128, 128))
        weave = ((xx % 4 == 0).astype(int) - (yy % 4 == 0).astype(int)) * 2
        dirt = np.where(((xx * 19 + yy * 31) % 211) < 5, -15, 0)
        texture = np.clip(np.array(rgb)[None, None, :] + (grain + weave + dirt)[:, :, None], 0, 255)
        diffuse[y:y + 128, x:x + 128, :3] = texture
        special[y:y + 128, x:x + 128, 0] = emission
        special[y:y + 128, x:x + 128, 1] = reflection
    normal = np.zeros_like(diffuse)
    normal[:, :, :] = (128, 128, 255, 255)
    for filename, array in ((TEX_DIFFUSE, diffuse), (TEX_SPECIAL, special), (TEX_NORMAL, normal)):
        Image.fromarray(array, "RGBA").save(ROOT / "unittextures" / filename, optimize=True)


def generate(kind, model_name, title):
    document = ET.parse(REFERENCE).getroot()
    nodes, transforms, parents = read_rig(document)
    meshes = draw_character(kind, transforms)
    geometry_by_id = {g.get("id"): g for g in document.findall("c:library_geometries/c:geometry", NS)}
    node_geometry = {name: node.find("c:instance_geometry", NS).get("url")[1:]
                     for name, node in nodes.items()}
    for name, node in nodes.items():
        geometry = geometry_by_id[node_geometry[name]]
        if name in meshes:
            write_geometry(geometry, meshes[name], transforms[name])
        else:
            remap_legacy_uvs(geometry)
    replace_materials(document)
    scene = document.find("c:library_visual_scenes/c:visual_scene", NS)
    scene.set("id", model_name)
    scene.set("name", model_name)
    document.find("c:scene/c:instance_visual_scene", NS).set("url", "#" + model_name)
    contributor = document.find("c:asset/c:contributor", NS)
    if contributor is not None:
        tool = contributor.find("c:authoring_tool", NS)
        if tool is not None:
            tool.text = "MOSAIC civilian_occupations/generate.py; inherited civilian0 rig"
    for name in ("created", "modified"):
        node = document.find("c:asset/c:" + name, NS)
        if node is not None:
            node.text = "2026-10-24T00:00:00Z"
    ET.indent(document, space="  ")
    path = ROOT / "objects3d" / (model_name + ".dae")
    ET.ElementTree(document).write(path, encoding="utf-8", xml_declaration=True)
    visible = ANATOMY + ["Eye1", "Eye2"]
    positions = np.concatenate([np.asarray(meshes[name].positions) for name in ANATOMY])
    bounds = [positions.min(0).round(6).tolist(), positions.max(0).round(6).tolist()]
    triangles = sum(int(t.get("count")) for t in document.findall("c:library_geometries/c:geometry/c:mesh/c:triangles", NS))
    meta = f'''-- Generated by tools/civilian_occupations/generate.py.
-- PNG UVs are authored bottom-up; diffuse alpha intentionally disables team tint.
return {{
    radius = 16,
    height = {bounds[1][1]:.6f},
    midpos = {{0, 15, 0}},
    tex1 = "{TEX_DIFFUSE}",
    tex2 = "{TEX_SPECIAL}",
    fliptextures = true,
    invertteamcolor = false,
    rotAxisSigns = {{1, 1, 1}},
}}
'''
    path.with_suffix(".dae.lua").write_text(meta)
    return {
        "name": model_name, "title": title, "role": kind,
        "triangles": triangles, "height": bounds[1][1], "bounds": bounds,
        "pieces": list(nodes), "defaultVisiblePieces": visible,
        "optionalVisiblePieces": [name for name in nodes if name not in visible and name != "root"],
        "texture": TEX_DIFFUSE, "specialTexture": TEX_SPECIAL, "normalTexture": TEX_NORMAL,
        "referenceRig": "civilian0_western.dae", "sourceUnitMeter": .0254,
        "forwardAxis": "+Z after imported bind transforms", "upAxis": "+Y after imported bind transforms",
        "bindPose": "Reference A-pose; use existing civilian standing animation for neutral game stance",
        "geometrySource": "Procedural occupation body; reference functional props with remapped UVs",
        "simplifiedProps": ["Pistol", "ak47", "SittingBaby"],
    }


def main():
    write_atlas()
    records = [generate("worker", "civilian_worker_western", "Municipal worker"),
               generate("courier", "civilian_courier_asian", "Foot courier")]
    manifest = ROOT / "tools/civilian_occupations/manifest.json"
    manifest.write_text(json.dumps(records, indent=2) + "\n")
    for record in records:
        print(record["name"], record["triangles"], "triangles;", len(record["pieces"]), "pieces; body bounds", record["bounds"])


if __name__ == "__main__":
    main()
