#!/usr/bin/env python3
"""Independent exported-model checks for native cage parade holograms.

Run after tools/parade_holograms/build.py (or its current generator entry point):
  python tests/parade_hologram_models_test.py --base-ref <original-commit>

The XML checks need NumPy and Pillow. Native importer checks additionally need
assimp_py, and are required unless --xml-only is explicitly requested. Use a
base ref/file to verify that every original float definition and hierarchy was
preserved; no generator module or generated preservation hash is trusted here.
"""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools/parade_holograms"))
from render_preview import (FIGURE_CATEGORIES, FIGURE_NAMES, PROP_NAMES, NS,
                            combine_pieces, figure_piece_names, load_export,
                            load_palette, local_tag, palette_indices)


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def semantic_digest(element):
    """Ignore indentation/namespace prefixes, retain every value and child order."""
    digest = hashlib.sha256()
    def feed(value):
        data = value.encode("utf-8")
        digest.update(str(len(data)).encode("ascii") + b":" + data)
    def visit(node):
        feed(node.tag)
        for key, value in sorted(node.attrib.items()):
            feed(key); feed(value)
        feed(" ".join((node.text or "").split()))
        digest.update(b"[")
        for child in node:
            visit(child)
        digest.update(b"]")
    visit(element)
    return digest.hexdigest()


def check_preservation(base, current):
    """Compare protected structures directly against the pre-change DAE."""
    require(base.tag == current.tag and base.attrib == current.attrib, "Original COLLADA root metadata changed")
    protected = Counter()
    for old_section in base:
        section_tag = local_tag(old_section)
        sections = [candidate for candidate in current if candidate.tag == old_section.tag]
        require(len(sections) == 1, f"Original {section_tag} missing or duplicated")
        new_section = sections[0]
        if section_tag == "library_visual_scenes":
            for old_scene in old_section:
                candidates = [node for node in new_section if node.get("id") == old_scene.get("id") and node.tag == old_scene.tag]
                require(len(candidates) == 1, f"Original visual scene missing: {old_scene.get('id')}")
                new_scene = candidates[0]
                require(old_scene.attrib == new_scene.attrib, "Original visual scene attributes changed")
                for old_child in old_scene:
                    identity = old_child.get("id")
                    matches = [node for node in new_scene if node.tag == old_child.tag
                               and (node.get("id") == identity if identity is not None else semantic_digest(node) == semantic_digest(old_child))]
                    require(len(matches) == 1, f"Original scene child missing or relocated: {identity or local_tag(old_child)}")
                    require(semantic_digest(old_child) == semantic_digest(matches[0]), f"Original scene subtree changed: {identity or local_tag(old_child)}")
                    protected["scene roots"] += local_tag(old_child) == "node"
                    protected["authored nodes"] += sum(local_tag(node) == "node" for node in old_child.iter())
        elif section_tag.startswith("library_"):
            require(old_section.attrib == new_section.attrib, f"Original {section_tag} attributes changed")
            for old_definition in old_section:
                identity = old_definition.get("id")
                matches = [node for node in new_section if node.tag == old_definition.tag and node.get("id") == identity]
                require(len(matches) == 1, f"Original definition missing or duplicated: {section_tag}/{identity}")
                require(semantic_digest(old_definition) == semantic_digest(matches[0]), f"Original definition changed: {section_tag}/{identity}")
                protected[section_tag.removeprefix("library_")] += 1
        else:
            require(semantic_digest(old_section) == semantic_digest(new_section), f"Original {section_tag} changed")
    return dict(protected)


def check_identity_nodes(nodes):
    require("paradeholograms" in nodes, "Missing generated paradeholograms root")
    for name, node in nodes.items():
        for child in node:
            tag = local_tag(child)
            if tag not in ("matrix", "translate", "scale", "rotate"):
                continue
            value = np.fromstring(child.text or "", sep=" ")
            if tag == "matrix":
                valid = len(value) == 16 and np.allclose(value.reshape(4, 4), np.eye(4), atol=1e-8)
            elif tag == "translate":
                valid = len(value) == 3 and np.allclose(value, 0, atol=1e-8)
            elif tag == "scale":
                valid = len(value) == 3 and np.allclose(value, 1, atol=1e-8)
            else:
                valid = len(value) == 4 and abs(value[3]) < 1e-8
            require(valid, f"{name}: nonidentity {tag} would be lost by raw gl.UnitPiece")


def check_piece(piece, palette):
    name = piece.name
    require(len(piece.positions) > 0, f"{name}: empty geometry")
    require(all(np.isfinite(array).all() for array in (piece.positions, piece.normals, piece.uvs)), f"{name}: NaN/Inf in vertex buffers")
    require(np.allclose(np.linalg.norm(piece.normals, axis=2), 1, atol=3e-5), f"{name}: nonunit normals")
    cross = np.cross(piece.positions[:, 1] - piece.positions[:, 0], piece.positions[:, 2] - piece.positions[:, 0])
    areas = np.linalg.norm(cross, axis=1)
    require((areas > 1e-9).all(), f"{name}: degenerate triangles")
    face_normals = cross / areas[:, None]
    agreement = (face_normals[:, None, :] * piece.normals).sum(axis=2)
    require((agreement > .99).all(), f"{name}: normals disagree with exported winding")
    require(np.any(np.abs(face_normals).max(axis=1) < .999), f"{name}: cage surface unexpectedly reduced to axis-aligned blocks")
    require(np.max(np.abs(piece.positions)) < 100, f"{name}: apparent centimetre/metre scale error")
    uv_edges_a = piece.uvs[:, 1] - piece.uvs[:, 0]
    uv_edges_b = piece.uvs[:, 2] - piece.uvs[:, 0]
    uv_area = np.abs(uv_edges_a[:, 0] * uv_edges_b[:, 1] - uv_edges_a[:, 1] * uv_edges_b[:, 0])
    require((uv_area > 1e-12).all(), f"{name}: collapsed UV triangle, invalid tangent basis")
    return palette_indices(piece.uvs, palette)


def check_role_surface_overlap(pieces):
    """Reject identical triangles shared by independently moving figure roles."""
    checks=0
    for figure in FIGURE_NAMES:
        seen=set()
        for name in figure_piece_names(figure):
            faces={tuple(sorted(tuple(np.round(v,6)) for v in tri)) for tri in pieces[name].positions}
            require(not seen.intersection(faces), name + ': coincident role surfaces')
            checks+=len(faces);seen.update(faces)
    return checks


def check_required_geometry(nodes, pieces, palette, max_triangles):
    expected_figures = set(FIGURE_NAMES)
    actual_figures = {name for name in nodes if re.fullmatch(r"parade(civilian|dead|ai|helper)\d+", name)}
    require(actual_figures == expected_figures, f"Expected exactly four of each figure category; missing={expected_figures-actual_figures}, unexpected={actual_figures-expected_figures}")
    expected_meshes = {name for figure in FIGURE_NAMES for name in figure_piece_names(figure)} | {"parade" + prop for prop in PROP_NAMES}
    require(expected_meshes <= pieces.keys(), f"Missing native geometry pieces: {sorted(expected_meshes-pieces.keys())}")
    swatch_names = tuple(palette)
    face_palettes = {name: check_piece(piece, palette) for name, piece in pieces.items()}
    category_ranges = {"civilian": (5, 11), "dead": (5, 12), "ai": (7, 18), "helper": (1, 4.5)}
    total = sum(len(piece.positions) for piece in pieces.values())
    require(total <= max_triangles, f"New scenery uses {total:,} triangles, over budget {max_triangles:,}")
    records = []
    for category in FIGURE_CATEGORIES:
        for number in range(1, 5):
            name = f"parade{category}{number}"
            roles = figure_piece_names(name)
            root_node = nodes[name]
            children = {child.get("name") or child.get("id") for child in root_node.findall("c:node", NS)}
            require(set(roles) <= children, f"{name}: body/head/mask must belong to their figure root")
            combined = combine_pieces(pieces, roles)
            lo, hi = combined.bounds
            height = hi[1] - lo[1]
            require(category_ranges[category][0] <= height <= category_ranges[category][1], f"{name}: implausible raw world height {height}")
            require(-.55 <= lo[1] <= .55, f"{name}: feet are not at local Y=0 ({lo[1]})")
            require(.3 < hi[0] - lo[0] < 15 and .15 < hi[2] - lo[2] < 12, f"{name}: collapsed or oversized width/depth")
            require(len(combined.positions) <= 24000, f"{name}: unbounded per-figure triangle cost ({len(combined.positions)})")
            mask_indices = face_palettes[name + "mask"]
            mask_materials = {swatch_names[i] for i in mask_indices}
            require(any(palette[material].get("emissive") for material in mask_materials), f"{name}: face mask has no luminous material")
            require("dark" in mask_materials, f"{name}: mask has no dark eye features")
            head = pieces[name + "head"].positions.reshape(-1, 3)
            mask = pieces[name + "mask"].positions.reshape(-1, 3)
            require(mask[:, 1].mean() > lo[1] + height * .5, f"{name}: face mask is below the upper body")
            require(mask[:, 2].max() >= np.quantile(head[:, 2], .55) - .25, f"{name}: mask faces away from +Z")
            records.append({"figure": name, "height": round(float(height), 4), "triangles": len(combined.positions), "mask_materials": sorted(mask_materials)})
    for prop in PROP_NAMES:
        piece = pieces["parade" + prop]
        lo, hi = piece.bounds
        require(np.all(hi - lo > .04), f"{prop}: planar/empty decoration instead of volumetric pixels")
        require((hi - lo).max() <= 15, f"{prop}: decorative scale out of range")
    return total, records


def check_standalone(document, nodes, pieces, embedded_pieces):
    unit = document.find("c:asset/c:unit", NS)
    require(unit is not None and abs(float(unit.get("meter", "0")) - 1) < 1e-8, "Standalone scenery DAE must use metre=1")
    require(document.findtext("c:asset/c:up_axis", "", NS).strip() == "Y_UP", "Standalone scenery DAE must use Y_UP")
    require(set(pieces) == set(embedded_pieces), "Standalone/embedded scenery piece sets differ")
    check_identity_nodes(nodes)
    for name, piece in pieces.items():
        other = embedded_pieces[name]
        for attr in ("positions", "normals", "uvs"):
            a, b = getattr(piece, attr), getattr(other, attr)
            require(a.shape == b.shape and np.allclose(a, b, atol=2e-7), f"{name}: standalone/embedded {attr} differ")


def check_assimp(path, pieces):
    import assimp_py
    flags = assimp_py.Process_Triangulate | assimp_py.Process_ValidateDataStructure | assimp_py.Process_CalcTangentSpace
    scene = assimp_py.import_file(str(path), flags)
    native_nodes = {}
    def visit(node):
        if node.name in pieces:
            require(node.name not in native_nodes, f"Assimp duplicate piece: {node.name}")
            native_nodes[node.name] = node
        for child in node.children:
            visit(child)
    visit(scene.root_node)
    require(set(native_nodes) == set(pieces), "Assimp lost generated geometry nodes")
    for name, expected in pieces.items():
        arrays, native_count = [], 0
        node = native_nodes[name]
        require(np.allclose(node.transformation, np.eye(4), atol=1e-6), f"Assimp transformed generated piece {name}")
        for mesh_id in node.mesh_indices:
            mesh = scene.meshes[mesh_id]
            vertices = np.asarray(mesh.vertices).reshape(-1, 3)
            indices = np.asarray(mesh.indices).reshape(-1, 3)
            require(np.isfinite(vertices).all(), f"Assimp nonfinite positions: {name}")
            arrays.append(vertices[indices])
            native_count += len(indices)
            for label, data in (("normals", mesh.normals), ("tangents", mesh.tangents), ("bitangents", mesh.bitangents)):
                require(data is not None, f"Assimp missing {label}: {name}")
                values = np.asarray(data).reshape(-1, 3)
                require(np.isfinite(values).all() and (np.linalg.norm(values, axis=1) > .01).all(), f"Assimp invalid {label}: {name}")
        require(native_count == len(expected.positions), f"Assimp triangle count changed: {name}")
        actual = np.concatenate(arrays).reshape(-1, 3)
        raw = expected.positions.reshape(-1, 3)
        require(np.allclose([actual.min(0), actual.max(0)], expected.bounds, atol=2e-5), f"Assimp raw bounds differ (unit/matrix baking?): {name}")
        require(np.allclose(np.mean(actual, axis=0), np.mean(raw, axis=0), atol=2e-5), f"Assimp raw geometry centroid differs: {name}")
    return len(native_nodes)


def check_editable_source(root):
    script = root / "tools/parade_holograms/Build_Parade_Hologram_Cages.ms"
    require(script.is_file(), "Missing editable MAXScript cage builder")
    text = script.read_text(encoding="utf-8")
    # The builder may load a small runtime; inspect its local .ms dependencies too.
    scripts = [script] + [path for path in script.parent.rglob("*.ms") if path != script]
    full_text = "\n".join(path.read_text(encoding="utf-8") for path in scripts)
    code = re.sub(r"/\*.*?\*/|--[^\n]*", "", full_text, flags=re.S)
    require(re.search(r"\bsplineShape\b", code, re.I), "Authoring source does not create editable SplineShape cages")
    require(re.search(r"\bSurface\b", code, re.I), "Authoring source has no live Surface modifier")
    require(not re.search(r"\b(convertToMesh|convertToPoly|collapseStack)\b", code, re.I), "Authoring builder collapses editable spline sources")
    cage_data = root / "tools/parade_holograms/source/cages.json"
    require(cage_data.is_file(), "Missing retained spline-cage control data")
    source_names = {model["slug"] for model in json.loads(cage_data.read_text())["models"]}
    for name in source_names:
        require(name in text or name in full_text, f"Editable authoring builder omits {name}")
    return len(scripts)


def check_cage_sources(root):
    """Verify the editable knot graph, separately from the exported voxels."""
    path = root / "tools/parade_holograms/source/cages.json"
    require(path.is_file(), "Missing retained spline-cage control data")
    models = json.loads(path.read_text())["models"]
    by_name = {model["slug"]: model for model in models}
    require(set(FIGURE_NAMES) <= by_name.keys(), "Cage source omits required figure variants")
    cage_count, tube_count = 0, 0
    for model in models:
        if model["slug"] in FIGURE_NAMES:
            require({part.get("group") for part in model["parts"]} == {"body", "head", "mask"},
                    f"{model['slug']}: editable body/head/mask source groups differ")
        for part in model["parts"]:
            label = model["slug"] + "/" + part["name"]
            if part["kind"] == "tube":
                points = np.asarray(part["points"], dtype=float)
                require(len(points) >= 2 and np.isfinite(points).all() and part["radius"] > 0,
                        f"{label}: invalid editable spline tube")
                require((np.linalg.norm(np.diff(points, axis=0), axis=1) > 1e-8).all(),
                        f"{label}: repeated consecutive tube knots")
                tube_count += 1
                continue
            require(part["kind"] == "cage", f"{label}: geometry lacks editable cage source")
            points = np.asarray(part["vertices"], dtype=float)
            require(points.ndim == 2 and points.shape[1] == 3 and np.isfinite(points).all(),
                    f"{label}: invalid cage control points")
            keys = [tuple(np.round(point, 6)) for point in points]
            curve_edges = set()
            for curve in part["curves"]:
                knots = [tuple(np.round(point, 6)) for point in curve["points"]]
                require(len(knots) >= 2 and all(np.isfinite(knot).all() for knot in knots),
                        f"{label}: invalid spline curve")
                following = knots[1:] + (knots[:1] if curve["closed"] else [])
                for a, b in zip(knots, following):
                    require(a != b, f"{label}: zero-length cage curve segment")
                    curve_edges.add(tuple(sorted((a, b))))
            edges = Counter()
            neighbours = {}
            for face in part["faces"]:
                require(len(face) in (3, 4) and len(set(face)) == len(face), f"{label}: invalid Surface patch loop")
                require(min(face) >= 0 and max(face) < len(points), f"{label}: cage face outside point array")
                for a, b in zip(face, face[1:] + face[:1]):
                    edge = tuple(sorted((a, b)))
                    edges[edge] += 1
                    neighbours.setdefault(a, set()).add(b)
                    neighbours.setdefault(b, set()).add(a)
                    require(tuple(sorted((keys[a], keys[b]))) in curve_edges,
                            f"{label}: patch edge absent from connected spline graph")
            require(edges and max(edges.values()) <= 2, f"{label}: non-manifold control net")
            if part.get("closed"):
                require(all(count == 2 for count in edges.values()), f"{label}: open edge in closed cage")
            reached, todo = set(), [next(iter(neighbours))]
            while todo:
                vertex = todo.pop()
                if vertex in reached:
                    continue
                reached.add(vertex)
                todo.extend(neighbours[vertex] - reached)
            require(len(reached) == len(neighbours), f"{label}: disconnected cage graph")
            cage_count += 1
    return {"models": len(models), "connected_cages": cage_count, "spline_tubes": tube_count}


def check_gradients(root, pieces, palette):
    diffuse = np.asarray(Image.open(root / "unittextures/house_asian_diffuse.dds").convert("RGB"))
    emission = np.asarray(Image.open(root / "unittextures/house_asian_selfilu_reflection.png").convert("RGBA"))
    uvs = np.concatenate([p.uvs for p in pieces.values()])
    indices = palette_indices(uvs, palette)
    for name in ("ivory_glow", "cyan_glow", "violet_glow", "gold_glow", "orange_glow"):
        patch = palette[name]
        selected = uvs[indices == tuple(palette).index(name)].reshape(-1, 2)
        require(len(selected) > 0, name + ": unused gradient")
        u0, v0, u1, v1 = patch["uv_rect"]
        require(np.all(np.ptp(selected, axis=0) >= .9 * np.array([u1-u0, v1-v0])), name + ": collapsed gradient coverage")
        x = np.clip((selected[:, 0] * diffuse.shape[1]).astype(int), 0, diffuse.shape[1]-1)
        y = np.clip(((1-selected[:, 1]) * diffuse.shape[0]).astype(int), 0, diffuse.shape[0]-1)
        require(np.ptp(diffuse[y, x].astype(float), axis=0).max() > 20, name + ": flat atlas colours")
        require(emission[y, x, 0].min() >= 240, name + ": UV escaped emissive strip")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--model", type=Path)
    parser.add_argument("--standalone", type=Path)
    baseline = parser.add_mutually_exclusive_group()
    baseline.add_argument("--base-ref", help="Git ref before the scenery was appended")
    baseline.add_argument("--base-dae", type=Path, help="Original untouched payload DAE")
    parser.add_argument("--xml-only", action="store_true", help="Explicitly omit native Assimp import; reports that limitation")
    parser.add_argument("--max-triangles", type=int, default=220000)
    parser.add_argument("--json-output", type=Path)
    args = parser.parse_args()
    root = args.root.resolve()
    model = args.model or root / "objects3d/truckPayloadParade.dae"
    standalone = args.standalone or root / "objects3d/paradeHologramScenery.dae"
    document, nodes, pieces = load_export(model)
    check_identity_nodes(nodes)
    palette = load_palette(root)
    total, figures = check_required_geometry(nodes, pieces, palette, args.max_triangles)
    check_gradients(root, pieces, palette)
    overlap_checks = check_role_surface_overlap(pieces)
    standalone_document, standalone_nodes, standalone_pieces = load_export(standalone)
    check_standalone(standalone_document, standalone_nodes, standalone_pieces, pieces)
    preservation = None
    if args.base_dae:
        base_document = ET.parse(args.base_dae).getroot()
        preservation = check_preservation(base_document, document)
    elif args.base_ref:
        data = subprocess.check_output(["git", "show", args.base_ref + ":objects3d/truckPayloadParade.dae"], cwd=root)
        preservation = check_preservation(ET.fromstring(data), document)
    scripts = check_editable_source(root)
    source_topology = check_cage_sources(root)
    native = None
    if not args.xml_only:
        if importlib.util.find_spec("assimp_py") is None:
            raise SystemExit("Native validation requires assimp_py. Install it, or explicitly use --xml-only for XML checks without claiming native import.")
        native = check_assimp(model, pieces)
        check_assimp(standalone, standalone_pieces)
    summary = {"result": "PASS", "figure_count": len(figures), "native_geometry_pieces": len(pieces),
               "triangles": total, "figures": figures, "original_preservation": preservation,
               "native_assimp_pieces": native, "editable_maxscripts": scripts,
               "source_topology": source_topology, "coplanar_role_comparisons": overlap_checks}
    if args.json_output:
        args.json_output.parent.mkdir(parents=True, exist_ok=True)
        args.json_output.write_text(json.dumps(summary, indent=2) + "\n")
    for figure in figures:
        print(f"PASS {figure['figure']}: {figure['height']:.2f} raw world units, {figure['triangles']:,} triangles, body/head/mask and eye features")
    print(f"PASS {len(pieces)} native geometry pieces; {total:,} cage-surface triangles; atlas UVs, winding, normals, standalone parity")
    print("PASS five existing atlas gradients: colour variation, full UV coverage and packed emission")
    print(f"PASS no identically facing role overlap ({overlap_checks:,} role triangles checked)")
    if preservation:
        print("PASS original authored content preserved:", json.dumps(preservation, sort_keys=True))
    else:
        print("NOT CHECKED original-content preservation: supply --base-ref or --base-dae")
    print(f"PASS editable spline source ({scripts} MAXScript file(s)); no mesh/poly collapse")
    print("PASS source knot graphs:", json.dumps(source_topology, sort_keys=True))
    print(f"PASS native Assimp import of both DAEs ({native} geometry pieces each)" if native is not None else "NOT CHECKED native Assimp import (--xml-only)")


if __name__ == "__main__":
    main()
