#!/usr/bin/env python3
"""Recenter Float24Sub1 on its authored axle without moving its geometry.

Only repairs the known 3ds Max export with the rotor pivot at the platform.
Already corrected exports are left unchanged; unfamiliar geometry is rejected.
"""
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
MODEL = ROOT / "objects3d/truckPayloadParade.dae"
NS = {"c": "http://www.collada.org/2005/11/COLLADASchema"}


def main():
    original = MODEL.read_bytes()
    text = original.decode("utf-8")
    root = ET.fromstring(original)
    ids = {node.get("id"): node for node in root.iter() if node.get("id")}
    node = ids["Float24Sub1"]
    mesh = ids[node.find("c:instance_geometry", NS).get("url")[1:]].find("c:mesh", NS)
    source = ids[mesh.find("c:vertices/c:input[@semantic='POSITION']", NS).get("source")[1:]]
    array = source.find("c:float_array", NS)
    values = list(map(float, array.text.split()))
    vertices = list(zip(values[::3], values[1::3], values[2::3]))
    zmid = (min(p[2] for p in vertices) + max(p[2] for p in vertices)) / 2
    if abs(zmid) < 0.001:
        print("PASS: rotor pivot is already centered")
        return
    assert abs(zmid - 535) < 0.001, "Unknown rotor geometry; inspect its axle before changing the pivot"
    # Original authored WindmillRotor hinge; local X is the axle.
    shift = (-34.0, 0.0, 535.0)
    matrix_node = node.find("c:matrix", NS)
    matrix = list(map(float, matrix_node.text.split()))
    for row in range(3):
        matrix[row * 4 + 3] += sum(matrix[row * 4 + col] * shift[col] for col in range(3))
    replacement = " ".join(f"{value - shift[i % 3]:.6f}" for i, value in enumerate(values))
    pattern = r'(<float_array\b[^>]*\bid="' + re.escape(array.get("id")) + r'"[^>]*>).*?(</float_array>)'
    text, count = re.subn(pattern, lambda m: m[1] + replacement + m[2], text, flags=re.S)
    assert count == 1
    pattern = r'(<node\b[^>]*\bid="Float24Sub1"[^>]*>\s*<matrix\b[^>]*>).*?(</matrix>)'
    text, count = re.subn(pattern, lambda m: m[1] + " ".join(f"{x:.6f}" for x in matrix) + m[2], text, flags=re.S)
    assert count == 1
    ET.fromstring(text)
    assert MODEL.read_bytes() == original, "Exporter changed the file during pivot repair"
    MODEL.write_text(text)
    print("PASS: rotor pivot moved to its axle; vertex positions compensated")


if __name__ == "__main__":
    main()
