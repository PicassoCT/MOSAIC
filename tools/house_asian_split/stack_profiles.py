#!/usr/bin/env python3
"""Generate small assembly socket profiles without changing house geometry.

The imported model's source coordinates are deliberately retained. A socket is
the convex X/Z envelope of triangle intersections in a shallow band inside one
storey boundary. Several slices capture plinths and cornices that a single
recessed-wall slice would miss. This is a conservative compatibility aid for
ordinary fallback modules, not a replacement for authored complete components.

Python standard library only. Run from any directory; --source permits a
separately materialized source model and --check verifies the checked-in output.
"""

import argparse
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import re
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "objects3d/house_asian.dae"
OUTPUT = ROOT / "scripts/house_asian_stack_profiles.lua"
NS = "http://www.collada.org/2005/11/COLLADASchema"
STYLES = ("pod", "industrial", "trad", "office")
FLOOR_HEIGHT = 595.4
BOTTOM_SAMPLES = (20.0, 35.0, 50.0)
TOP_SAMPLES = tuple(FLOOR_HEIGHT - y for y in reversed(BOTTOM_SAMPLES))
TOLERANCE = 35.0
DIRECTIONS = tuple((math.cos(i * math.pi / 8), math.sin(i * math.pi / 8))
                   for i in range(16))
# Generic fallback is a single normal storey. Larger authored/animated parts
# retain their profiles and remain available to the existing component planner.
MIN_Y = -120.0
MAX_Y = 750.0
MAX_WIDTH = 1100.0


def q(tag):
    return "{" + NS + "}" + tag


def canonical(name):
    return re.sub(r"\d+", lambda m: str(int(m.group())), name.lower())


def piece_styles(name):
    return [i for i, style in enumerate(STYLES, 1) if style in name.lower()]


def geometry_data(geometry):
    """Return source vertices and unique triangle edges for one root mesh."""
    mesh = geometry.find(q("mesh"))
    sources = {source.get("id"): source for source in mesh.findall(q("source"))}
    vertex_inputs = mesh.find(q("vertices")).findall(q("input"))
    position_id = next(i.get("source")[1:] for i in vertex_inputs
                       if i.get("semantic") == "POSITION")
    source = sources[position_id]
    accessor = source.find(q("technique_common")).find(q("accessor"))
    if int(accessor.get("stride", "1")) != 3:
        raise ValueError("Expected XYZ positions: " + geometry.get("id"))
    values = [float(v) for v in source.find(q("float_array")).text.split()]
    vertices = [tuple(values[i:i + 3]) for i in range(0, len(values), 3)]
    edges = set()
    for primitive in mesh:
        kind = primitive.tag.rsplit("}", 1)[-1]
        if kind in ("source", "vertices", "extra"):
            continue
        if kind != "triangles":
            raise ValueError("Unsupported mesh primitive " + kind)
        inputs = primitive.findall(q("input"))
        stride = 1 + max(int(i.get("offset", "0")) for i in inputs)
        offset = int(next(i.get("offset", "0") for i in inputs
                          if i.get("semantic") == "VERTEX"))
        indices = [int(v) for v in primitive.find(q("p")).text.split()]
        corners = indices[offset::stride]
        if len(corners) % 3:
            raise ValueError("Incomplete triangle in " + geometry.get("id"))
        for i in range(0, len(corners), 3):
            a, b, c = corners[i:i + 3]
            edges.update((min(x, y), max(x, y))
                         for x, y in ((a, b), (b, c), (c, a)) if x != y)
    return vertices, sorted(edges)


def transformed(vertices, node):
    matrix_node = node.find(q("matrix"))
    if matrix_node is None:
        raise ValueError("Expected exported node matrix: " + node.get("name"))
    m = [float(v) for v in matrix_node.text.split()]
    if len(m) != 16:
        raise ValueError("Expected 4x4 node matrix: " + node.get("name"))
    return [(m[0] * x + m[1] * y + m[2] * z + m[3],
             m[4] * x + m[5] * y + m[6] * z + m[7],
             m[8] * x + m[9] * y + m[10] * z + m[11])
            for x, y, z in vertices]


def socket(vertices, edges, planes):
    """Sixteen convex support distances; no assumption about a square shell."""
    support = [-math.inf] * len(DIRECTIONS)
    hit = False
    for a, b in edges:
        ax, ay, az = vertices[a]
        bx, by, bz = vertices[b]
        dy = by - ay
        if abs(dy) < 1e-8:
            continue
        for y in planes:
            if min(ay, by) <= y <= max(ay, by):
                f = (y - ay) / dy
                x, z = ax + f * (bx - ax), az + f * (bz - az)
                for i, (dx, dz) in enumerate(DIRECTIONS):
                    support[i] = max(support[i], x * dx + z * dz)
                hit = True
    return [round(v, 3) for v in support] if hit else None


def profiles(source):
    geometries = {g.get("id"): g
                  for g in source.find(q("library_geometries"))}
    result = {}
    for scene in source.find(q("library_visual_scenes")):
        # The unit script independently places these root modules. Animated
        # child meshes travel with them; they are not independent stack stock.
        for node in scene.findall(q("node")):
            name = node.get("name", "")
            lower = name.lower()
            styles = piece_styles(name)
            if not styles or any(s in lower for s in ("sub", "spin", "deco", "base", "roof")):
                continue
            instances = node.findall(q("instance_geometry"))
            if not instances:
                continue
            if len(instances) != 1:
                raise ValueError("Expected one root mesh: " + name)
            vertices, edges = geometry_data(geometries[instances[0].get("url")[1:]])
            vertices = transformed(vertices, node)
            low = [min(p[i] for p in vertices) for i in range(3)]
            high = [max(p[i] for p in vertices) for i in range(3)]
            bottom = socket(vertices, edges, BOTTOM_SAMPLES)
            top = socket(vertices, edges, TOP_SAMPLES)
            eligible = (bottom is not None and top is not None
                        and low[1] >= MIN_Y and high[1] <= MAX_Y
                        and high[0] - low[0] <= MAX_WIDTH
                        and high[2] - low[2] <= MAX_WIDTH)
            result[name] = {
                "styles": styles,
                "groundOnly": "floor" in lower,
                "fallbackEligible": eligible,
                "bottom": bottom,
                "top": top,
                "min": [round(v, 3) for v in low],
                "max": [round(v, 3) for v in high],
            }
    return dict(sorted(result.items()))


def authored_groups(source):
    # Reuse the same structural interpretation as the existing split exporter.
    spec = importlib.util.spec_from_file_location("house_asian_split_exporter",
                                                 Path(__file__).with_name("generate.py"))
    exporter = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(exporter)
    return exporter.groups(source)[0]


def compatible(lower, upper):
    return (lower["top"] is not None and upper["bottom"] is not None
            and max(abs(a - b) for a, b in zip(lower["top"], upper["bottom"])) <= TOLERANCE)


def fallback_paths(pieces, groups, style):
    """Deterministic disjoint suggestions; runtime still checks live inventory.

    Reserve every complete four-row authored component before looking at the
    ordinary stock. This makes these paths additional capacity, rather than a
    second way to spend the same pieces. Prefer long paths and genuine ground
    pieces. Short complete paths remain useful when a featured component has
    consumed stock from one of the longer suggestions.
    """
    reserved = {canonical(n) for g in groups
                if style in g["styles"] and g["stage"] == "wall" and g["rows"] == 4
                for n in g["pieces"]}
    names = sorted(n for n, p in pieces.items()
                   if style in p["styles"] and p["fallbackEligible"]
                   and canonical(n) not in reserved)
    left = set(names)
    follows = {n: [m for m in names if m != n and not pieces[m]["groundOnly"]
                   and compatible(pieces[n], pieces[m])] for n in names}

    def walk(path, length):
        if len(path) == length:
            return path
        options = [n for n in follows[path[-1]] if n in left and n not in path]
        options.sort(key=lambda n: (len(set(follows[n]) & left), n))
        for name in options:
            found = walk(path + [name], length)
            if found:
                return found
        return None

    paths = []
    for length in (4, 3, 2):
        while True:
            starters = sorted(left, key=lambda n: (not pieces[n]["groundOnly"],
                                                   len(set(follows[n]) & left), n))
            found = next((path for n in starters
                          if (path := walk([n], length)) is not None), None)
            if not found:
                break
            paths.append(found)
            left.difference_update(found)
    return paths


def lua(value):
    if value is None:
        return "nil"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, list) or isinstance(value, tuple):
        return "{" + ", ".join(lua(v) for v in value) + "}"
    if isinstance(value, dict):
        return "{" + ", ".join(k + " = " + lua(v) for k, v in value.items()) + "}"
    return json.dumps(value, ensure_ascii=True)


def generate(source_path):
    source_bytes = source_path.read_bytes()
    source = ET.fromstring(source_bytes)
    unit = source.find(q("asset")).find(q("unit"))
    unit_scale = float(unit.get("meter", "1"))
    if abs(unit_scale - 0.0254) > 1e-8:
        raise ValueError("Re-audit socket sampling after a model import-unit change")
    pieces = profiles(source)
    groups = authored_groups(source)
    paths = {style: fallback_paths(pieces, groups, style) for style in range(1, 5)}
    header = {
        "version": 1,
        "sourceSha256": hashlib.sha256(source_bytes).hexdigest(),
        "unitScale": unit_scale,
        "floorHeight": FLOOR_HEIGHT,
        "directions": len(DIRECTIONS),
        "tolerance": TOLERANCE,
        "sampleBottom": BOTTOM_SAMPLES[-1],
        "sampleTop": TOP_SAMPLES[0],
        "bottomSamples": BOTTOM_SAMPLES,
        "topSamples": TOP_SAMPLES,
        "minY": MIN_Y,
        "maxY": MAX_Y,
        "maxWidth": MAX_WIDTH,
    }
    lines = ["-- Generated by tools/house_asian_split/stack_profiles.py; do not edit.",
             "-- X/Z socket supports are in original DAE units (game units / 0.0254).",
             "-- Tolerance 35 is 0.889 game units; authored components remain authoritative.",
             "return {"]
    lines += ["    " + key + " = " + lua(value) + "," for key, value in header.items()]
    lines.append("    pieces = {")
    lines += ["        [" + lua(name) + "] = " + lua(profile) + ","
              for name, profile in pieces.items()]
    lines += ["    },", "    fallbackPaths = {"]
    for style in range(1, 5):
        lines.append("        [" + str(style) + "] = {")
        lines += ["            " + lua(path) + "," for path in paths[style]]
        lines.append("        },")
    lines += ["    },", "}", ""]
    return "\n".join(lines).encode(), pieces, paths


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=SOURCE)
    parser.add_argument("--output", type=Path, default=OUTPUT)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    data, pieces, paths = generate(args.source)
    if args.check:
        if not args.output.exists() or args.output.read_bytes() != data:
            raise SystemExit("Stale/missing socket catalogue: " + str(args.output))
    else:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_bytes(data)
    print(str(args.output), len(data), "bytes;", len(pieces), "profiles")
    for style in range(1, 5):
        lengths = [sum(len(p) == n for p in paths[style]) for n in (4, 3, 2)]
        print(STYLES[style - 1], "additional paths of 4/3/2 pieces:", *lengths)


if __name__ == "__main__":
    main()
