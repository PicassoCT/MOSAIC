#!/usr/bin/env python3
"""Validate shipped civilian occupation assets, independently of their generator.

Run from any directory with Python 3 and the optional asset-tooling packages
assimp-py, numpy, Pillow and lupa installed. This validates files and the native
piece/texture contract; it does not substitute for a Recoil visual smoke test.
"""
from pathlib import Path
import re
import xml.etree.ElementTree as ET

import assimp_py
import numpy as np
from PIL import Image
from lupa.lua51 import LuaRuntime


ROOT = Path(__file__).resolve().parents[1]
NS = {"c": "http://www.collada.org/2005/11/COLLADASchema"}
MODEL_NAMES = ("civilian_worker_western", "civilian_courier_asian")
ANATOMY = {
    "center", "UpBody", "Head1", "UpArm1", "UpArm2", "LowArm1", "LowArm2",
    "Hand1", "Hand2", "UpLeg1", "UpLeg2", "LowLeg1", "LowLeg2", "Feet1", "Feet2",
}
IMPORT_FLAGS = (
    assimp_py.Process_Triangulate
    | assimp_py.Process_ValidateDataStructure
    | assimp_py.Process_CalcTangentSpace
    | assimp_py.Process_JoinIdenticalVertices
)


def source_hierarchy(path):
    doc = ET.parse(path).getroot()
    result = {}

    def visit(node, parent):
        name = node.get("name")
        assert name and name not in result, (path, "duplicate/empty piece", name)
        matrices = node.findall("c:matrix", NS)
        assert len(matrices) == 1, (path, "expected explicit bind matrix", name)
        matrix = np.fromstring(matrices[0].text, sep=" ").reshape(4, 4)
        assert np.isfinite(matrix).all(), (path, "nonfinite transform", name)
        result[name] = (parent, matrix)
        for child in node.findall("c:node", NS):
            visit(child, name)

    for node in doc.findall("c:library_visual_scenes/c:visual_scene/c:node", NS):
        visit(node, None)
    return doc, result


def imported_hierarchy(scene):
    result = {}

    def visit(node, parent, transform):
        assert node.name not in result, ("Assimp renamed/duplicated a piece", node.name)
        local = np.asarray(node.transformation, dtype=float).reshape(4, 4)
        world = transform @ local
        result[node.name] = (parent, local, world, list(node.mesh_indices))
        for child in node.children:
            visit(child, node.name, world)

    visit(scene.root_node, None, np.eye(4))
    return result


def world_vertices(scene, hierarchy, pieces):
    chunks = []
    for name in pieces:
        transform, indices = hierarchy[name][2:]
        for index in indices:
            vertices = np.asarray(scene.meshes[index].vertices).reshape(-1, 3)
            chunks.append((transform @ np.column_stack((vertices, np.ones(len(vertices)))).T).T[:, :3])
    assert chunks, "no visible anatomical geometry"
    return np.concatenate(chunks)


reference_path = ROOT / "objects3d/civilian0_western.dae"
reference_doc, reference_nodes = source_hierarchy(reference_path)
reference_scene = assimp_py.import_file(str(reference_path), IMPORT_FLAGS)
reference_imported = imported_hierarchy(reference_scene)
reference_triangles = sum(mesh.num_faces for mesh in reference_scene.meshes)
script = (ROOT / "scripts/civilianscript.lua").read_text()
direct_pieces = set(re.findall(r"piece\s*\(?\s*['\"]([^'\"]+)", script))
# Conditional RPG pieces are absent even from the reference civilian. All actual
# reference props and both full protest alphabets must remain available.
required_pieces = (direct_pieces & reference_nodes.keys()) | ANATOMY

for model_name in MODEL_NAMES:
    path = ROOT / "objects3d" / (model_name + ".dae")
    doc, nodes = source_hierarchy(path)
    assert required_pieces <= nodes.keys(), (model_name, "missing script piece", required_pieces - nodes.keys())
    assert reference_nodes.keys() <= nodes.keys(), (model_name, "lost legacy prop/letter piece")
    # The shared animation data contains absolute source-space translations.
    # Merely retaining bone names while changing parentage/scales can look fine
    # in a still image and then tear the model apart during animation.
    for name, (parent, matrix) in reference_nodes.items():
        actual_parent, actual_matrix = nodes[name]
        assert actual_parent == parent, (model_name, name, "changed parent")
        assert np.allclose(actual_matrix, matrix, rtol=0, atol=1e-6), (model_name, name, "changed bind transform")
    for field in ("unit", "up_axis"):
        original = reference_doc.find("c:asset/c:" + field, NS)
        actual = doc.find("c:asset/c:" + field, NS)
        assert original is not None and actual is not None
        assert original.attrib == actual.attrib and (original.text or "").strip() == (actual.text or "").strip(), (model_name, "changed source axis/units", field)

    scene = assimp_py.import_file(str(path), IMPORT_FLAGS)
    hierarchy = imported_hierarchy(scene)
    assert reference_nodes.keys() <= hierarchy.keys(), (model_name, "piece names changed on import")
    for name in reference_nodes:
        assert np.allclose(hierarchy[name][2], reference_imported[name][2], rtol=0, atol=1e-5), (model_name, name, "imported bind differs")
        assert hierarchy[name][3], (model_name, name, "functional piece has no geometry")

    triangles = sum(mesh.num_faces for mesh in scene.meshes)
    assert 0 < triangles < reference_triangles, (model_name, "placeholder is not lower-poly", triangles)
    anatomy_meshes = {index for name in ANATOMY for index in hierarchy[name][3]}
    for mesh_index, mesh in enumerate(scene.meshes):
        vertices = np.asarray(mesh.vertices).reshape(-1, 3)
        indices = np.asarray(mesh.indices).reshape(-1, 3)
        normals = np.asarray(mesh.normals).reshape(-1, 3)
        assert mesh.num_faces == len(indices) and len(vertices) == len(normals)
        assert np.isfinite(vertices).all() and np.isfinite(normals).all()
        assert np.allclose(np.linalg.norm(normals, axis=1), 1, atol=1e-4), (model_name, mesh.name, "invalid normals")
        assert len(mesh.texcoords) and mesh.texcoords[0] is not None, (model_name, mesh.name, "missing UV")
        uv = np.asarray(mesh.texcoords[0]).reshape(len(vertices), -1)[:, :2]
        assert np.isfinite(uv).all() and uv.min() >= -1e-5 and uv.max() <= 1 + 1e-5, (model_name, mesh.name, "UV outside atlas")
        assert mesh.tangents is not None and np.isfinite(np.asarray(mesh.tangents)).all(), (model_name, mesh.name, "invalid tangents")
        assert indices.min() >= 0 and indices.max() < len(vertices), (model_name, "invalid triangle index")
        if mesh_index in anatomy_meshes:
            triangle_vertices = vertices[indices]
            face_normals = np.cross(triangle_vertices[:, 1] - triangle_vertices[:, 0],
                                    triangle_vertices[:, 2] - triangle_vertices[:, 0])
            areas = np.linalg.norm(face_normals, axis=1)
            assert (areas > 1e-6).all(), (model_name, mesh.name, "degenerate body triangle")
            agreement = (face_normals * normals[indices].mean(axis=1)).sum(axis=1)
            assert (agreement > 0).all(), (model_name, mesh.name, "normal/winding mismatch")

    body = world_vertices(scene, hierarchy, ANATOMY)
    assert np.isfinite(body).all()
    minimum, maximum = body.min(axis=0), body.max(axis=0)
    assert -2 < minimum[1] < 3, (model_name, "feet no longer near ground", minimum)
    assert 24 < maximum[1] < 40, (model_name, "not civilian-scale", maximum)
    assert np.max(np.abs(body[:, [0, 2]])) < 16, (model_name, "body/gear spills outside civilian scale")

    lua = LuaRuntime(unpack_returned_tuples=True)
    meta = lua.execute(path.with_suffix(".dae.lua").read_text())
    # These atlases use bottom-left UVs. Recoil loads PNG rows top-down, so
    # the same explicit flip used by the inspection renderer is required.
    assert meta["fliptextures"] is True, (model_name, "PNG atlas orientation mismatch")
    assert isinstance(meta["invertteamcolor"], bool), (model_name, "implicit legacy teamcolour inversion")
    textures = []
    for key in ("tex1", "tex2"):
        image = Image.open(ROOT / "unittextures" / meta[key]).convert("RGBA")
        image.load()
        assert all(v > 0 and v & (v - 1) == 0 for v in image.size), (model_name, key, "non-power-of-two atlas")
        textures.append(np.asarray(image))
    diffuse, special = textures
    assert diffuse.shape == special.shape, (model_name, "mismatched atlases")
    teamcolour = 255 - diffuse[:, :, 3] if meta["invertteamcolor"] else diffuse[:, :, 3]
    assert teamcolour.max() == 0, (model_name, "unexpected Gaia team tint")
    assert special[:, :, 3].min() == 255, (model_name, "transparent occupation geometry")
    normal = Image.open(ROOT / "unittextures/civ_occupations_normal.png").convert("RGB")
    assert normal.size == (diffuse.shape[1], diffuse.shape[0]), (model_name, "normal atlas mismatch")
    assert np.asarray(normal)[:, :, 2].min() > 127, (model_name, "inverted tangent-space normals")
    print(f"PASS {model_name}: {triangles:,} triangles, {len(nodes)} pieces; Assimp, bind transforms, UVs, materials and civilian scale")

print("Civilian street asset validation passed; Recoil gameplay/visual acceptance remains an in-engine check.")
