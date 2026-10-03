#!/usr/bin/env python3
"""Lossless style subsets of house_asian.dae; Python stdlib only.

Run from any directory. --check regenerates in memory and compares every output.
Names with several style tokens are shared components (OR, not AND). Untagged
pieces are common. Keep complete child trees, original names, transforms, mesh
data, UVs, materials and import units. Never flatten or re-export the geometry.
"""
import argparse
import copy
import hashlib
import itertools
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
NS = "http://www.collada.org/2005/11/COLLADASchema"
Q = lambda name: "{" + NS + "}" + name
ET.register_namespace("", NS)
STYLES = ("pod", "industrial", "trad", "office")


def styles(name):
    return [i for i, style in enumerate(STYLES, 1) if style in name.lower()]


def subset(source, selected):
    root = copy.deepcopy(source)
    scenes = root.find(Q("library_visual_scenes"))

    def prune(parent):
        for node in list(parent.findall(Q("node"))):
            tags = styles(node.get("name", ""))
            if tags and not set(tags).intersection(selected):
                parent.remove(node)
            elif not tags:
                # Untagged helpers can be structural parents of style pieces.
                prune(node)
            # A tagged component and all its animated children stay together.

    for scene in scenes:
        prune(scene)
    geometries = root.find(Q("library_geometries"))
    referenced = {e.get("url")[1:] for e in scenes.iter(Q("instance_geometry"))}
    for geometry in list(geometries):
        if geometry.get("id") not in referenced:
            geometries.remove(geometry)
    # This source has no controllers/animations. Fail instead of producing stale
    # channel targets if the authoring pipeline starts exporting them later.
    for kind in ("library_controllers", "library_animations", "library_nodes"):
        assert not list(root.findall(Q(kind))), "Unsupported source: " + kind
    return root


def groups(source):
    """Only complete numbered components fitting a straight 6-wide facade.

    u = vertical; l = horizontal; a = either. Larger a groups use columns of
    four blocks, matching the maximum ground + three upper floors. Broken
    authoring names are reported, never silently repaired or renumbered.
    """
    candidates = {}
    for node in source.find(Q("library_visual_scenes")).iter(Q("node")):
        name = node.get("name", "")
        match = re.match(r"^ID_([ulaULA])(\d+)_(.*?)(\d+)$", name)
        if not match or any(s in name.lower() for s in ("sub", "spin", "deco", "base", "_ncl")):
            continue
        direction, number, label, member = match.groups()
        key = "id_" + direction.lower() + number + "_" + label.lower()
        candidates.setdefault(key, []).append((int(member), name))
    result, excluded = [], []
    for key, members in sorted(candidates.items()):
        members.sort()
        count = len(members)
        stage = "roof" if "roof" in key else "floor" if "floor" in key else "wall"
        direction = key[3]
        rows = 1
        if stage == "wall" and direction == "u":
            rows = count
        elif stage == "wall" and direction == "a" and count % 4 == 0:
            rows = 4
        columns = count // rows
        if count < 2 or [i for i, _ in members] != list(range(1, count + 1)) or rows > 4 or columns > 6:
            excluded.append({"id": key, "pieces": [n for _, n in members],
                             "reason": "incomplete numbering or exceeds one facade"})
            continue
        common = set.intersection(*(set(styles(n)) for _, n in members))
        if not common:
            continue
        result.append({"id": key, "styles": sorted(common), "stage": stage,
                       "rows": rows, "columns": columns, "pieces": [n for _, n in members]})
    return result, excluded


def lua(value):
    if isinstance(value, dict):
        return "{" + ", ".join(k + " = " + lua(v) for k, v in value.items()) + "}"
    if isinstance(value, list):
        return "{" + ", ".join(lua(v) for v in value) + "}"
    return json.dumps(value, ensure_ascii=True)


def generate(root=ROOT):
    source_path = root / "objects3d/house_asian.dae"
    source_bytes = source_path.read_bytes()
    source = ET.fromstring(source_bytes)
    coherent, excluded = groups(source)
    specs = []
    metadata = (root / "objects3d/house_asian.dae.lua").read_bytes()
    for a, b in itertools.combinations_with_replacement(range(1, 5), 2):
        name = f"house_asian_split_{a}_{b}"
        model = subset(source, {a, b})
        data = ET.tostring(model, encoding="utf-8", xml_declaration=True)
        pieces = [n.get("name") for n in model.find(Q("library_visual_scenes")).iter(Q("node"))]
        assert len(pieces) == len(set(pieces)), "Duplicate piece names"
        spec = {"name": name, "styles": [a] if a == b else [a, b],
                "nodes": len(pieces), "geometries": len(model.find(Q("library_geometries"))),
                "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}
        specs.append(spec)
        yield f"objects3d/{name}.dae", data
        yield f"objects3d/{name}.dae.lua", metadata
    manifest = {"source": "objects3d/house_asian.dae",
                "source_sha256": hashlib.sha256(source_bytes).hexdigest(),
                "source_nodes": len(list(source.find(Q("library_visual_scenes")).iter(Q("node")))),
                "styles": dict(enumerate(STYLES, 1)), "variants": specs,
                "groups": coherent, "excluded_groups": excluded}
    yield "tools/house_asian_split/manifest.json", (json.dumps(manifest, indent=2) + "\n").encode()
    # Runtime catalogue is generated from the same audited asset inventory.
    runtime = "-- Generated by tools/house_asian_split/generate.py; do not edit.\nreturn {\n"
    runtime += "    styles = " + lua(list(STYLES)) + ",\n    groups = {\n"
    runtime += "".join("        " + lua(group) + ",\n" for group in coherent)
    runtime += "    },\n}\n"
    yield "scripts/house_asian_split_catalog.lua", runtime.encode()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    stale = []
    for relative, data in generate():
        path = ROOT / relative
        if args.check:
            if not path.exists() or path.read_bytes() != data:
                stale.append(relative)
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
        print(relative, len(data))
    if stale:
        raise SystemExit("Stale/missing outputs: " + ", ".join(stale))


if __name__ == "__main__":
    main()
