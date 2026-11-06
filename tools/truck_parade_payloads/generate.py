#!/usr/bin/env python3
"""Export the six authored lantern spline cages as one native truck payload.

Only evaluated game meshes are triangulated. The copied spline authoring
recipes retain all original parts, control nets, handles and movable groups.
The unmodified Asian house textures provide both colour and emission.
Run from any directory with Python 3 and NumPy.
"""
from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

import numpy as np

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE / "source"))
sys.path.insert(0, str(HERE / "source" / "recipes"))
from geometry import evaluate, triangulate
from build_first_three import build as first_three
from build_last_three import build as last_three

SCALE = 0.08
FLOOR = 2.1
# Source front -X becomes native +Z, source Z becomes native Y. This is a
# proper rotation (det=+1), preserving winding, normals and handedness.
ROTATION = np.array([[0, -1, 0], [0, 0, 1], [-1, 0, 0]], dtype=float)
OFFSETS = ((0, 0, 0), (0, 0, -3.5), (0, 3.2, 1), (0, -1.8, 0))


def transform(points, position=True):
    result = np.asarray(points, dtype=float) @ ROTATION.T * SCALE
    if position:
        result[..., 1] += FLOOR
    return result


def part_mesh(part, palette, pivot):
    vertices, faces = evaluate(part)
    triangles = triangulate(faces)
    vertices = transform(vertices) - pivot
    raw = np.cross(vertices[triangles[:, 1]] - vertices[triangles[:, 0]],
                   vertices[triangles[:, 2]] - vertices[triangles[:, 0]])
    lengths = np.linalg.norm(raw, axis=1)
    if np.any(lengths < 1e-10):
        raise ValueError("Degenerate triangle in " + part["name"])
    face_normals = raw / lengths[:, None]
    smooth = part["kind"] == "tube" or (not part.get("thickness", 0)
             and all(c["smooth"] for c in part.get("curves", [])))
    normals = np.zeros_like(vertices)
    if smooth:
        for corner in range(3):
            np.add.at(normals, triangles[:, corner], raw)
        nlengths = np.linalg.norm(normals, axis=1)
        if np.any(nlengths < 1e-10):
            raise ValueError("Undefined vertex normal in " + part["name"])
        normals /= nlengths[:, None]
    # A tiny verified atlas island is a solid material swatch. Project each
    # complete part within that island so adjacent triangles share their UVs.
    lo = vertices.min(axis=0)
    extent = np.ptp(vertices, axis=0)
    u0, v0, u1, v1 = palette["patches"][part["material"]]["uv_rect"]
    projections = {}
    for axes in ((0, 1), (0, 2), (1, 2)):
        selected = list(axes)
        uv = (vertices[:, selected] - lo[selected]) / np.maximum(extent[selected], 1e-9)
        projections[axes] = uv * (u1 - u0, v1 - v0) + (u0, v0)
    result = []
    for i, triangle in enumerate(triangles):
        # Select a projection per face: side walls and end caps retain area
        # in UV space, allowing Assimp to form a finite tangent basis.
        axes = tuple(sorted(np.argsort(np.abs(face_normals[i]))[:2]))
        uv = projections[axes]
        for index in triangle:
            # Tight pole caps and sharply folded ribs are hard edges. An
            # averaged normal may otherwise point behind one adjacent face.
            normal = (normals[index] if smooth and np.dot(normals[index], face_normals[i]) > .4
                      else face_normals[i])
            result.append(tuple(np.concatenate((vertices[index],
                          normal, uv[index]))))
    return result


def make_pieces(models, palette):
    pieces, variants = {}, []
    for model in models:
        base = "container" + str(65 + model["index"])
        groups = {g["name"]: g for g in model["groups"]}
        names = {None: base, **{name: base + "Act" + name.removeprefix("Act") for name in groups}}
        for group_name, name in names.items():
            pivot = transform(groups[group_name]["pivot"]) if group_name else np.zeros(3)
            pieces[name] = {"vertices": [], "pivot": pivot, "parent": base if group_name else "center"}
        for part in model["parts"]:
            piece = pieces[names[part["group"]]]
            piece["vertices"].extend(part_mesh(part, palette, piece["pivot"]))
        all_points = np.concatenate([np.array(pieces[name]["vertices"])[:, :3] + pieces[name]["pivot"]
                                     for name in names.values()])
        variants.append({"key": model["slug"], "title": model["title"], "piece": base,
            "parts": len(model["parts"]), "pieces": list(names.values()),
            "triangles": sum(len(pieces[name]["vertices"]) // 3 for name in names.values()),
            "bounds": [all_points.min(0).tolist(), all_points.max(0).tolist()],
            "groups": [{"piece": names[g["name"]], "pivot": transform(g["pivot"]).tolist(),
                        "axis": (np.array(g["axis"]) @ ROTATION.T).tolist(),
                        "kind": g["kind"], "notes": g["notes"]} for g in model["groups"]]})
    return pieces, variants


def write_dae(pieces, path):
    ns = "http://www.collada.org/2005/11/COLLADASchema"
    ET.register_namespace("", ns)
    def el(parent, tag, attrs=None, text=None):
        e = ET.SubElement(parent, "{" + ns + "}" + tag, attrs or {})
        if text is not None:
            e.text = str(text)
        return e
    doc = ET.Element("{" + ns + "}COLLADA", {"version": "1.4.1"})
    asset = el(doc, "asset")
    el(el(asset, "contributor"), "authoring_tool", text="MOSAIC truck_parade_payloads/generate.py")
    for key in ("created", "modified"):
        el(asset, key, text="2026-11-02T00:00:00Z")
    el(asset, "unit", {"name": "meter", "meter": "1"})
    el(asset, "up_axis", text="Y_UP")
    im = el(el(doc, "library_images"), "image", {"id": "asian_atlas"})
    el(im, "init_from", text="../unittextures/house_asian_diffuse.dds")
    effect = el(el(doc, "library_effects"), "effect", {"id": "atlas_effect"})
    profile = el(effect, "profile_COMMON")
    surface = el(el(profile, "newparam", {"sid": "atlas_surface"}), "surface", {"type": "2D"})
    el(surface, "init_from", text="asian_atlas")
    sampler = el(el(profile, "newparam", {"sid": "atlas_sampler"}), "sampler2D")
    el(sampler, "source", text="atlas_surface")
    diffuse = el(el(el(profile, "technique", {"sid": "common"}), "lambert"), "diffuse")
    el(diffuse, "texture", {"texture": "atlas_sampler", "texcoord": "UVMap"})
    material = el(el(doc, "library_materials"), "material", {"id": "atlas_material", "name": "AsianHouseAtlas"})
    el(material, "instance_effect", {"url": "#atlas_effect"})
    geometries = el(doc, "library_geometries")
    for name, piece in pieces.items():
        # Index identical records without changing geometry or authored parts.
        records, indices, lookup = [], [], {}
        for vertex in piece["vertices"]:
            vertex = tuple(round(float(x), 9) for x in vertex)
            if vertex not in lookup:
                lookup[vertex] = len(records)
                records.append(vertex)
            indices.append(lookup[vertex])
        mesh = el(el(geometries, "geometry", {"id": name + "_mesh", "name": name}), "mesh")
        for label, start, size, names in (("pos", 0, 3, "XYZ"), ("norm", 3, 3, "XYZ"), ("uv", 6, 2, "ST")):
            sid = name + "_" + label
            source = el(mesh, "source", {"id": sid})
            array = el(source, "float_array", {"id": sid + "_array", "count": str(len(records) * size)},
                       " ".join(f"{v[k]:.9f}" for v in records for k in range(start, start + size)))
            accessor = el(el(source, "technique_common"), "accessor",
                          {"source": "#" + array.get("id"), "count": str(len(records)), "stride": str(size)})
            for component in names:
                el(accessor, "param", {"name": component, "type": "float"})
        vertices = el(mesh, "vertices", {"id": name + "_vertices"})
        el(vertices, "input", {"semantic": "POSITION", "source": "#" + name + "_pos"})
        triangles = el(mesh, "triangles", {"count": str(len(indices) // 3), "material": "atlas"})
        for semantic, suffix, offset in (("VERTEX", "vertices", 0), ("NORMAL", "norm", 1), ("TEXCOORD", "uv", 2)):
            attrs = {"semantic": semantic, "source": "#" + name + "_" + suffix, "offset": str(offset)}
            if semantic == "TEXCOORD":
                attrs["set"] = "0"
            el(triangles, "input", attrs)
        el(triangles, "p", text=" ".join(f"{i} {i} {i}" for i in indices))
    scene = el(el(doc, "library_visual_scenes"), "visual_scene", {"id": "Scene", "name": "Scene"})
    center = el(scene, "node", {"id": "center", "name": "center", "type": "NODE"})
    nodes = {"center": center}
    for name, piece in pieces.items():
        node = nodes[name] = el(nodes[piece["parent"]], "node", {"id": name, "name": name, "type": "NODE"})
        el(node, "translate", text=" ".join(f"{x:.6f}" for x in piece["pivot"]))
        instance = el(node, "instance_geometry", {"url": "#" + name + "_mesh"})
        binding = el(el(el(instance, "bind_material"), "technique_common"), "instance_material",
                     {"symbol": "atlas", "target": "#atlas_material"})
        el(binding, "bind_vertex_input", {"semantic": "UVMap", "input_semantic": "TEXCOORD", "input_set": "0"})
    el(el(doc, "scene"), "instance_visual_scene", {"url": "#Scene"})
    ET.indent(doc, space="  ")
    ET.ElementTree(doc).write(path, encoding="utf-8", xml_declaration=True)


def main():
    palette = json.loads((HERE / "source" / "palette.json").read_text())
    models = [recipe.to_dict() for recipe in first_three() + last_three()]
    pieces, variants = make_pieces(models, palette)
    path = ROOT / "objects3d" / "truckPayloadParade.dae"
    path.parent.mkdir(parents=True, exist_ok=True)
    write_dae(pieces, path)
    points = np.concatenate([np.array(p["vertices"])[:, :3] + p["pivot"] for p in pieces.values()])
    lo, hi = points.min(0), points.max(0)
    mid = (lo + hi) / 2
    # Each movable piece may rotate around its authored pivot. A sphere using
    # pivot distance plus local radius bounds all poses, including the rotor.
    radius = max((np.linalg.norm(p["pivot"] + offset - mid) +
                  max(np.linalg.norm(np.array(p["vertices"])[:, :3], axis=1)))
                 if p["parent"] != "center" else
                 max(np.linalg.norm(np.array(p["vertices"])[:, :3] + offset - mid, axis=1))
                 for p in pieces.values() for offset in np.array(OFFSETS))
    radius = math.ceil(radius) + 1
    height = math.ceil(mid[1] + radius)
    (path.with_suffix(".dae.lua")).write_text(
        "-- Generated by tools/truck_parade_payloads/generate.py.\n"
        "-- Culling bounds include mounting offsets and every articulated pose.\n"
        f"return {{radius = {radius}, height = {height}, midpos = "
        "{" + ", ".join(f"{x:.6f}" for x in mid) + "},\n"
        '    tex1 = "house_asian_diffuse.dds",\n'
        '    tex2 = "house_asian_selfilu_reflection.png",\n}\n')
    manifest = {"schema": 1, "generator": "tools/truck_parade_payloads/generate.py",
        "source": "MOSAIC Lantern Float Cages, 2026-11-02; original editable sources preserved",
        "atlas_commit": palette["source_commit"], "scale": SCALE, "floor_y": FLOOR,
        "coordinate_system": "Y up, +Z front; meter=1; empty center mount root",
        "model_sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "culling": {"radius": radius, "height": height, "midpos": mid.tolist()}, "variants": variants}
    (HERE / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    for variant in variants:
        print(f"{variant['key']}: {variant['triangles']} triangles, {len(variant['pieces'])} pieces")


if __name__ == "__main__":
    main()
