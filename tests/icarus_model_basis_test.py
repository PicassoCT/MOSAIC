#!/usr/bin/env python3
"""Check the actual Icarus meshes against Recoil's projectile model basis.

Run from the repository root with Python 3. The arithmetic follows Recoil
058c8ea AssParser::LoadPieceTransformations, S3DModelPiece::ComposeTransform,
and CProjectile::GetTransformMatrix; no renderer or third-party package needed.
"""

import math
from pathlib import Path
import re
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
NS = {"c": "http://www.collada.org/2005/11/COLLADASchema"}


def multiply(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)]
            for i in range(3)]


def transform(matrix, vector):
    return [sum(matrix[i][j] * vector[j] for j in range(3)) for i in range(3)]


def rotate(axis, degrees):
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
    if axis == "x":
        return [[1, 0, 0], [0, c, -s], [0, s, c]]
    if axis == "y":
        return [[c, 0, s], [0, 1, 0], [-s, 0, c]]
    return [[c, -s, 0], [s, c, 0], [0, 0, 1]]


def scripted_rotation(x=0, y=0, z=0):
    # Spring's LH RotateEulerYXZ(-angles) is RH Ry(y) * Rx(x) * Rz(z).
    return multiply(multiply(rotate("y", y), rotate("x", x)), rotate("z", z))


def node_rotation(document, name):
    node = document.find(f".//c:visual_scene//c:node[@name='{name}']", NS)
    assert node is not None, f"missing model piece {name}"
    matrix = [float(n) for n in node.findtext("c:matrix", namespaces=NS).split()]
    return [[matrix[i * 4 + j] for j in range(3)] for i in range(3)], matrix


def positions(document, name):
    mesh = document.find(f".//c:geometry[@id='{name}-lib']/c:mesh", NS)
    source = mesh.find("c:vertices/c:input[@semantic='POSITION']", NS).get("source")[1:]
    values = mesh.findtext(f"c:source[@id='{source}']/c:float_array", namespaces=NS)
    values = [float(n) for n in values.split()]
    return list(zip(values[0::3], values[1::3], values[2::3]))


def close(actual, expected, message):
    assert all(abs(a - b) < 1e-6 for a, b in zip(actual, expected)), \
        f"{message}: {actual} != {expected}"


aircraft = ET.parse(ROOT / "objects3d/air_plane_artillery.dae")
projectile = ET.parse(ROOT / "objects3d/air_plane_artillery_projectile.dae")
base_bake, _ = node_rotation(aircraft, "Base")
_, tail = node_rotation(aircraft, "Tail")
body_vertices = positions(aircraft, "Base")
bomb_vertices = positions(projectile, "Projectile")
bomb_bake, _ = node_rotation(projectile, "Projectile")

# Establish the longitudinal directions from the assets, including the matching
# nose dimension in the folded mesh; do not assume every model uses the same axis.
assert tail[11] < -200, "airframe tail no longer establishes a negative-Z aft axis"
airframe_nose = max(v[2] for v in body_vertices)
bomb_min = [min(v[i] for v in bomb_vertices) for i in range(3)]
bomb_max = [max(v[i] for v in bomb_vertices) for i in range(3)]
assert abs(airframe_nose + bomb_min[0]) < 0.001, "folded mesh nose axis changed"
assert bomb_max[0] - bomb_min[0] > 4 * max(
    bomb_max[1] - bomb_min[1], bomb_max[2] - bomb_min[2]), "folded body axis changed"

script = (ROOT / "scripts/airplaneartilleryscript.lua").read_text()
header = (ROOT / "gamedata/unit_script_header.lua").read_text()
# MOSAIC swaps the y_axis/z_axis aliases. Recoil's ParseAxis still interprets
# the resulting numbers as 1=X, 2=Y, 3=Z, so resolve the real header first.
script_axes = {axis: int(index) for axis, index in re.findall(
    r"\blocal\s+([xyz])_axis\s*=\s*([123])\b", header)}
assert set(script_axes.values()) == {1, 2, 3}, "unit-script axis mapping changed"
base_angles = {}
for axis in ("x", "z"):
    match = re.search(r"Turn\(Base,\s*" + axis +
                      r"_axis,\s*math\.rad\(([-\d.]+)\)", script)
    assert match, f"missing Base {axis}-axis unfold pose"
    physical_axis = "xyz"[script_axes[axis] - 1]
    base_angles[physical_axis] = float(match.group(1))
airframe_pose = multiply(base_bake, scripted_rotation(**base_angles))
close(transform(airframe_pose, [0, 0, 1]), [0, 0, 1],
      "unfolded airframe must face unit forward")

metadata = (ROOT / "objects3d/air_plane_artillery_projectile.dae.lua").read_text()
piece = re.search(r"\bProjectile\s*=\s*\{([^}]+)\}", metadata)
assert piece, "missing folded-projectile piece orientation metadata"
angles = {"x": 0, "y": 0, "z": 0}
for axis, degrees in re.findall(r"\brotate([xyz])\s*=\s*([-\d.]+)", piece.group(1)):
    angles[axis] = float(degrees)
bomb_pose = multiply(bomb_bake, scripted_rotation(**angles))
folded_nose = transform(bomb_pose, [-1, 0, 0])
close(folded_nose, [0, 0, 1], "folded projectile nose must align with velocity")

# For a vertical fall, Recoil chooses xdir=(1,0,0), ydir=xdir cross velocity,
# and model columns (-xdir, ydir, velocity). The corrected nose must point down.
fall_matrix = [[-1, 0, 0], [0, 0, -1], [0, -1, 0]]
close(transform(fall_matrix, folded_nose), [0, -1, 0],
      "native gravity projectile must descend nose first")
uncorrected_nose = transform(bomb_bake, [-1, 0, 0])
assert abs(transform(fall_matrix, uncorrected_nose)[1]) < 0.001, \
    "regression fixture no longer describes the former sideways drop"

print("PASS: actual Icarus DAE airframe pose and folded projectile nose align with "
      "Recoil forward/vertical gravity-drop bases")
