#!/usr/bin/env python3
"""Static asset checks; --runtime adds Assimp import and Lua 5.1 assembly tests.

Runtime dependencies: pip install assimp_py lupa
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools/house_asian_split"))
from generate import Q, STYLES


def nodes(root):
    return {n.get("name"): n for n in root.find(Q("library_visual_scenes")).iter(Q("node"))}


def check(runtime=False):
    manifest = json.loads((ROOT / "tools/house_asian_split/manifest.json").read_text())
    source_data = (ROOT / manifest["source"]).read_bytes()
    assert hashlib.sha256(source_data).hexdigest() == manifest["source_sha256"]
    source = ET.fromstring(source_data)
    original = nodes(source)
    geoms = {g.get("id"): ET.tostring(g) for g in source.find(Q("library_geometries"))}
    tracked = set(subprocess.check_output(["git", "ls-files"], cwd=ROOT, text=True).splitlines())
    fixtures = []
    assert len(manifest["variants"]) == 10
    for spec in manifest["variants"]:
        path = ROOT / "objects3d" / (spec["name"] + ".dae")
        data = path.read_bytes()
        assert hashlib.sha256(data).hexdigest() == spec["sha256"]
        root = ET.fromstring(data)
        pieces = nodes(root)
        assert len(pieces) == spec["nodes"] < manifest["source_nodes"]
        assert {"center", "Icon", "ErrorIcon"}.issubset(pieces)
        assert ET.tostring(root.find(Q("asset"))) == ET.tostring(source.find(Q("asset")))
        for name, node in pieces.items():
            # Whole subtrees, hierarchy, bind transforms and original names.
            assert ET.tostring(node) == ET.tostring(original[name]), name
        for geometry in root.find(Q("library_geometries")):
            assert ET.tostring(geometry) == geoms[geometry.get("id")], "mesh/UV/normal modified"
        ids = {element.get("id") for element in root.iter() if element.get("id")}
        for element in root.iter():
            for key in ("url", "source", "target"):
                value = element.get(key, "")
                if value.startswith("#"):
                    assert value[1:] in ids, "dangling COLLADA reference: " + value
        lua = path.with_suffix(".dae.lua").read_bytes()
        assert lua == (ROOT / "objects3d/house_asian.dae.lua").read_bytes()
        for texture in re.findall(r'tex[12]\s*=\s*"([^"]+)"', lua.decode().split('--tex2')[0]):
            assert "unittextures/" + texture in tracked, texture
        for group in manifest["groups"]:
            if set(spec["styles"]).intersection(group["styles"]):
                assert set(group["pieces"]).issubset(pieces), group["id"]
        if runtime:
            import assimp_py
            scene = assimp_py.import_file(str(path), assimp_py.Process_Triangulate |
                                         assimp_py.Process_ValidateDataStructure |
                                         assimp_py.Process_CalcTangentSpace)
            imported = []
            def walk(node):
                imported.append(node.name)
                for child in node.children:
                    walk(child)
            walk(scene.root_node)
            assert set(pieces).issubset(imported), "import changed script piece names"
            assert all(m.normals is not None and m.texcoords is not None for m in scene.meshes)
            fixtures.append({"name": spec["name"], "pieces": imported,
                             "styles": spec["styles"]})
        print(spec["name"], spec["nodes"], "nodes: PASS", flush=True)
    if runtime:
        from lupa.lua51 import LuaRuntime
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.globals().MODEL_FIXTURES = lua.table_from(fixtures, recursive=True)
        lua.execute("dofile('tests/house_asian_split_assembly_test.lua')")
    print("PASS: model references, lossless geometry/hierarchy/UVs, textures, import scale, coherent groups")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtime", action="store_true")
    check(parser.parse_args().runtime)
