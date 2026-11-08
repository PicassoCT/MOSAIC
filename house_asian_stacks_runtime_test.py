#!/usr/bin/env python3
"""Exercise the production stack planner and house assembly using Lua 5.1.

Requires `python -m pip install lupa`. Run from any directory, for example:
    python tests/house_asian_stacks_runtime_test.py
    python tests/house_asian_stacks_runtime_test.py --source /path/to/house_asian.dae

The split fixtures derive the actual source DAE visual trees using the export
pruning rule: retain untagged helpers and any selected style component with all
its descendants. This does not regenerate assets or depend on the split-model
manifest. The engine API is stubbed; mesh rendering is outside this test.
All ten pure/pair style combinations, four legacy styles and the featured
component catalogue run through the real house script. The pure planner suite
runs first; --pure-only runs it without loading the source model.
"""
import argparse
import itertools
import os
from pathlib import Path
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
NS = "{http://www.collada.org/2005/11/COLLADASchema}"
STYLES = ("pod", "industrial", "trad", "office")


def read_scenes(source):
    # Geometry is irrelevant to these piece-map fixtures. Clear it as it is
    # parsed so the large source asset need not be retained in memory twice.
    for _, element in ET.iterparse(source, events=("end",)):
        if element.tag == NS + "library_visual_scenes":
            return element
        if element.tag == NS + "geometry":
            element.clear()
    raise AssertionError("Source DAE has no visual scenes")


def fixture(scenes, selected):
    pieces, children = [], {}

    def walk(node, keep_descendants=False):
        name = node.get("name")
        assert name, "Unnamed source piece"
        tags = {i for i, style in enumerate(STYLES, 1) if style in name.lower()}
        if not keep_descendants and tags and not tags.intersection(selected):
            return None
        assert name not in children, "Duplicate source piece: " + name
        pieces.append(name)
        children[name] = []
        for child in node.findall(NS + "node"):
            kept = walk(child, keep_descendants or bool(tags))
            if kept:
                children[name].append(kept)
        return name

    for scene in scenes:
        for node in scene.findall(NS + "node"):
            walk(node)
    return {"pieces": pieces, "children": children, "styles": sorted(selected)}


def run(source=None):
    os.chdir(ROOT)
    LuaRuntime(unpack_returned_tuples=True).execute(
        "dofile('tests/house_asian_stack_plan_test.lua')"
    )
    if source is None:
        return None
    scenes = read_scenes(source)
    fixtures = []
    for a, b in itertools.combinations_with_replacement(range(1, 5), 2):
        model = fixture(scenes, {a, b})
        model["name"] = f"house_asian_split_{a}_{b}"
        fixtures.append(model)
    legacy = fixture(scenes, {1, 2, 3, 4})
    legacy.update(name="house_asian0", legacy=True)
    fixtures.append(legacy)
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.globals().MODEL_FIXTURES = lua.table_from(fixtures, recursive=True)
    return lua.execute("return dofile('tests/house_asian_split_assembly_test.lua')")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=ROOT / "objects3d/house_asian.dae")
    parser.add_argument("--pure-only", action="store_true")
    args = parser.parse_args()
    # Resolve before changing directory, so user-supplied relative paths work.
    run(None if args.pure_only else args.source.resolve())


if __name__ == "__main__":
    main()
