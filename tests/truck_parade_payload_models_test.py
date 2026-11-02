#!/usr/bin/env python3
"""Validate exported lantern floats through Assimp, independently of exporter.

Requires numpy and assimp_py. --carrier-dir supports a sparse source checkout;
--lua chooses the installed Lua interpreter for the actual runtime catalog.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET

import assimp_py
import numpy as np
from truck_service_payload_models_test import import_geometry, carrier_surface_under

ROOT = Path(__file__).resolve().parents[1]
MODEL = ROOT / "objects3d/truckPayloadParade.dae"
NS = {"c": "http://www.collada.org/2005/11/COLLADASchema"}


def read_catalog(lua):
    with tempfile.NamedTemporaryFile("w", suffix=".lua") as file:
        file.write("local c=dofile('scripts/lib_truck_parade_payloads.lua')\n"
                   "for name,o in pairs(c.carrierOffsets) do print('MOUNT',name,o.y,o.z) end\n"
                   "for i,v in ipairs(c.variants) do print('VARIANT',i,v.key,table.concat(v.pieces,',')) end\n")
        file.flush()
        output = subprocess.check_output([lua, file.name], cwd=ROOT, text=True)
    mounts, variants = {}, []
    for line in output.splitlines():
        fields = line.split("\t")
        if fields[0] == "MOUNT":
            mounts[fields[1]] = np.array([0, float(fields[2]), float(fields[3])])
        elif fields[0] == "VARIANT":
            variants.append((fields[2], fields[3].split(",")))
    return mounts, variants


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--carrier-dir", type=Path, default=ROOT / "objects3d")
    parser.add_argument("--lua", default=shutil.which("lua") or shutil.which("texlua"))
    args = parser.parse_args()
    assert args.lua, "Use --lua to specify a Lua interpreter"
    mounts, variants = read_catalog(args.lua)
    assert set(mounts) == {"truck_arab6", "truck_arab7", "truck_arab8"}
    manifest = json.loads((ROOT / "tools/truck_parade_payloads/manifest.json").read_text())
    assert manifest["model_sha256"] == hashlib.sha256(MODEL.read_bytes()).hexdigest()
    assert [(v["key"], v["pieces"]) for v in manifest["variants"]] == variants
    palette = json.loads((ROOT / "tools/truck_parade_payloads/source/palette.json").read_text())
    patches = list(palette["patches"].values())
    root = ET.parse(MODEL).getroot()
    assert root.find("c:asset/c:unit", NS).get("meter") == "1"
    assert root.find("c:asset/c:up_axis", NS).text == "Y_UP"
    center = root.find(".//c:visual_scene/c:node", NS)
    assert center.get("name") == "center" and not center.findall("c:instance_geometry", NS)
    assert {n.get("name") for n in center.findall("c:node", NS)} == {f"container{i}" for i in range(66, 72)}
    pieces, transforms = import_geometry(MODEL)
    native = assimp_py.import_file(str(MODEL), assimp_py.Process_Triangulate
        | assimp_py.Process_ValidateDataStructure | assimp_py.Process_CalcTangentSpace)
    for mesh in native.meshes:
        tangents = np.asarray(mesh.tangents).reshape(-1, 3)
        assert np.isfinite(tangents).all() and (np.linalg.norm(tangents, axis=1) > .01).all()
    assert set(pieces) == {piece for _, names in variants for piece in names}
    assert np.allclose(transforms["center"], np.eye(4))
    bounds = manifest["culling"]
    mid = np.array(bounds["midpos"])
    total = 0
    for record in manifest["variants"]:
        data = np.concatenate([pieces[name] for name in record["pieces"]])
        triangles = data.reshape(-1, 3, 8)
        total += len(triangles)
        assert len(triangles) == record["triangles"] <= 13000
        assert np.isfinite(data).all()
        assert np.allclose(np.linalg.norm(data[:, 3:6], axis=1), 1, atol=1e-5)
        cross = np.cross(triangles[:, 1, :3] - triangles[:, 0, :3],
                         triangles[:, 2, :3] - triangles[:, 0, :3])
        area = np.linalg.norm(cross, axis=1)
        assert (area > 1e-8).all(), record["key"] + ": degenerate face"
        agreement = (cross[:, None, :] * triangles[:, :, 3:6]).sum(2) / area[:, None]
        assert (agreement > 0).all(), record["key"] + ": inward vertex normal"
        uv = triangles[:, :, 6:8]
        contained = np.zeros(len(triangles), dtype=bool)
        emissive = np.zeros(len(triangles), dtype=bool)
        for patch in patches:
            u0, v0, u1, v1 = patch["uv_rect"]
            matches = ((uv[:, :, 0] >= u0 - 1e-7) & (uv[:, :, 0] <= u1 + 1e-7)
                       & (uv[:, :, 1] >= v0 - 1e-7) & (uv[:, :, 1] <= v1 + 1e-7)).all(1)
            contained |= matches
            if patch["emissive"]:
                emissive |= matches
        assert contained.all(), record["key"] + ": UV outside verified atlas islands"
        assert emissive.sum() >= 50, record["key"] + ": missing luminous panels"
        lo, hi = data[:, :3].min(0), data[:, :3].max(0)
        assert np.allclose([lo, hi], record["bounds"], atol=2e-5)
        assert abs(lo[1] - 2.1) < 1e-5 and 35 < hi[1] < 65
        for offset in mounts.values():
            assert np.linalg.norm(data[:, :3] + offset - mid, axis=1).max() <= bounds["radius"]
        for group in record["groups"]:
            assert np.allclose(transforms[group["piece"]][:3, 3], group["pivot"], atol=1e-5)
        print(f"PASS: {record['title']}: {len(triangles):,} triangles; native hierarchy, UVs, luminous panels and normals")
    assert 50000 <= total <= 55000
    # The original four-pillar skid is narrowed to 17.6 x 45.6 world units.
    # Check its actual floor against the imported carrier bed, not a guessed
    # bounding-box height. Upper float silhouettes may overhang the skid.
    for carrier, offset in mounts.items():
        geometry, nodes = import_geometry(args.carrier_dir / (carrier + ".dae"))
        attachment = nodes["attachPoint"][:3, 3]
        surface = geometry["body"][:, :3].reshape(-1, 3, 3) - attachment
        lo = np.array([-8.8, 2.1, -22.8]) + offset
        hi = np.array([8.8, 2.74, 22.8]) + offset
        bed = carrier_surface_under(surface, lo, hi)
        gap = lo[1] - bed[:, 1].max()
        assert .01 <= gap <= .8, f"{carrier}: float skid bed clearance {gap}"
        print(f"PASS: {carrier} float skid mounting, bed clearance {gap:.3f}")
    print(f"PASS: 6 native lantern floats, {len(pieces)} separately controlled pieces, {total:,} triangles resident")


if __name__ == "__main__":
    main()
