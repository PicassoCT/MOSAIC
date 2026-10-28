#!/usr/bin/env python3
"""Independently validate the exported bundle and its actual carrier clearance.

Run from any directory with numpy, assimp_py and texlua available.  This test
does not import the model generator or renderer.  Assimp is the engine's
importer family; clearance is measured against the existing carrier triangles.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile
import xml.etree.ElementTree as ET

import assimp_py
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
MODEL = ROOT / "objects3d/truckPayloadService.dae"
NS = {"c": "http://www.collada.org/2005/11/COLLADASchema"}
VARIANTS = (
    "air_scrubber", "night_kitchen", "battery_exchange", "salvage_press",
    "cold_chain", "sleeper_shuttle", "crematorium", "noodle_shop", "casino",
    "strip_club", "bar", "band", "unato_rations",
)


def import_geometry(path):
    scene = assimp_py.import_file(str(path),
        assimp_py.Process_Triangulate | assimp_py.Process_ValidateDataStructure
        | assimp_py.Process_CalcTangentSpace | assimp_py.Process_JoinIdenticalVertices)
    result, nodes = {}, {}

    def visit(node, parent):
        matrix = parent @ np.asarray(node.transformation, dtype=float)
        nodes[node.name] = matrix
        chunks = []
        for idx in node.mesh_indices:
            mesh = scene.meshes[idx]
            assert mesh.normals is not None and mesh.texcoords, f"missing surface attributes: {node.name}"
            assert mesh.tangents is not None, f"cannot form tangent basis: {node.name}"
            xyz = np.asarray(mesh.vertices).reshape(-1, 3)
            xyz = (matrix @ np.column_stack((xyz, np.ones(len(xyz)))).T).T[:, :3]
            normals = np.asarray(mesh.normals).reshape(-1, 3)
            normals = (np.linalg.inv(matrix[:3, :3]).T @ normals.T).T
            lengths = np.linalg.norm(normals, axis=1)[:, None]
            # Some original carrier helper meshes contain zero normals. Keep
            # those zeros; the new visible pieces must still pass the explicit
            # unit-normal assertion below.
            np.divide(normals, lengths, out=normals, where=lengths > 1e-12)
            uv = np.asarray(mesh.texcoords[0]).reshape(-1, mesh.num_uv_components[0])[:, :2]
            indices = np.asarray(mesh.indices, dtype=int)
            chunks.append(np.column_stack((xyz, normals, uv))[indices])
        if chunks:
            result[node.name] = np.concatenate(chunks)
        for child in node.children:
            visit(child, matrix)

    visit(scene.root_node, np.eye(4))
    return result, nodes


def read_lua_contract():
    # Execute the actual unit/catalog files. Recursive normalization matches the
    # engine environment and catches incorrectly cased inherited customParams.
    source = """
function lowerkeys(value)
  if type(value) ~= 'table' then return value end
  local result={}
  for key,item in pairs(value) do
    result[type(key)=='string' and key:lower() or key]=lowerkeys(item)
  end
  return result
end
VFS={Include=dofile}
local c=dofile('scripts/lib_truck_service_payloads.lua')
for name,offset in pairs(c.carrierOffsets) do
  print('MOUNT',name,offset.y,offset.z)
end
for i,v in ipairs(c.variants) do print('VARIANT',i,v.key,v.pieceName) end
local d=dofile('units/neutral/truckPayloadService.lua').truckpayloadservice
print('UNIT',d.objectname,d.script,d.customparams.normaltex)
"""
    with tempfile.NamedTemporaryFile("w", suffix=".lua") as file:
        file.write(source)
        file.flush()
        text = subprocess.check_output(["texlua", file.name], cwd=ROOT, text=True)
    mounts, variants, unit = {}, [], None
    for line in text.splitlines():
        fields = line.split("\t")
        if fields[0] == "MOUNT": mounts[fields[1]] = np.asarray([0, float(fields[2]), float(fields[3])])
        if fields[0] == "VARIANT": variants.append((int(fields[1]), fields[2], fields[3]))
        if fields[0] == "UNIT": unit = fields[1:]
    assert tuple(v[1] for v in variants) == VARIANTS, "catalog order differs from approved model bodies"
    assert [v[2] for v in variants] == [f"container{i}" for i in range(1, len(VARIANTS)+1)]
    assert unit == ["truckPayloadService.dae", "truckServicePayloadScript.lua", "unittextures/house_asian_normal.dds"]
    assert set(mounts) == {"truck_arab6", "truck_arab7", "truck_arab8"}
    return mounts


def clip_polygon(poly, axis, boundary, sign):
    """Sutherland-Hodgman clipping in XZ while interpolating true surface Y."""
    if not poly: return []
    result = []
    previous = poly[-1]
    previous_inside = sign*(previous[axis]-boundary) >= 0
    for current in poly:
        inside = sign*(current[axis]-boundary) >= 0
        if inside != previous_inside:
            t = (boundary-previous[axis])/(current[axis]-previous[axis])
            result.append(previous + t*(current-previous))
        if inside: result.append(current)
        previous, previous_inside = current, inside
    return result


def carrier_surface_under(triangles, lo, hi):
    points = []
    for triangle in triangles:
        # Reject triangles whose projected AABBs do not overlap the footprint.
        if np.any(triangle[:, [0,2]].max(0) < lo[[0,2]]) or np.any(triangle[:, [0,2]].min(0) > hi[[0,2]]):
            continue
        polygon = list(triangle)
        for axis,boundary,sign in ((0,lo[0],1),(0,hi[0],-1),(2,lo[2],1),(2,hi[2],-1)):
            polygon = clip_polygon(polygon, axis, boundary, sign)
        points.extend(polygon)
    assert points, "payload footprint has no support on carrier"
    return np.asarray(points)


def polygon_area(poly):
    if len(poly) < 3:
        return 0.0
    points = np.asarray(poly)
    return abs(np.dot(points[:, 0], np.roll(points[:, 1], -1))
               - np.dot(points[:, 1], np.roll(points[:, 0], -1))) * .5


def clip_halfplane(poly, a, b, sign):
    """Clip a 2D polygon to one side of an oriented line."""
    if not poly:
        return []
    edge = b-a

    def distance(point):
        delta = point-a
        return sign*(edge[0]*delta[1]-edge[1]*delta[0])

    result = []
    previous = poly[-1]
    before = distance(previous)
    for current in poly:
        after = distance(current)
        if (before >= -1e-10) != (after >= -1e-10):
            result.append(previous + before/(before-after)*(current-previous))
        if after >= -1e-10:
            result.append(current)
        previous, before = current, after
    return result


def uncovered_contact_area(triangles, center, size):
    """Measure a contact rectangle minus the union of actual flat triangles.

    Subtracting their projected polygons prevents overlapping duplicate faces
    from concealing a hole, as a simple sum of triangle areas could do.
    """
    lo, hi = center-size*.5, center+size*.5
    remaining = [[np.asarray(p) for p in (
        (lo[0],lo[1]), (hi[0],lo[1]), (hi[0],hi[1]), (lo[0],hi[1]))]]
    for triangle in triangles:
        projected = triangle[:, [0,2]]
        if np.any(projected.max(0) < lo) or np.any(projected.min(0) > hi):
            continue
        a, b, c = projected
        if (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0]) < 0:
            projected = projected[::-1]
        next_remaining = []
        for polygon in remaining:
            candidate = polygon
            for i in range(3):
                a, b = projected[i], projected[(i+1)%3]
                outside = clip_halfplane(candidate, a, b, -1)
                if polygon_area(outside) > 1e-9:
                    next_remaining.append(outside)
                candidate = clip_halfplane(candidate, a, b, 1)
                if not candidate:
                    break
        remaining = next_remaining
        if not remaining:
            return 0.0
    return sum(polygon_area(poly) for poly in remaining)


def verify_vertical_support(triangles, point, bottom, top):
    """Check a complete load path by oriented vertical ray intersections.

    Signed entry/exit counts describe the union of overlapping closed beams.
    Each interval between real triangle crossings must contain solid geometry;
    this catches a floating roof pad even when both contact faces are present.
    """
    projected = triangles[:, :, [0,2]]
    a = projected[:, 0]
    edge_b, edge_c = projected[:, 1]-a, projected[:, 2]-a
    delta = point-a
    determinant = edge_b[:, 0]*edge_c[:, 1]-edge_b[:, 1]*edge_c[:, 0]
    nonvertical = abs(determinant) > 1e-10
    u, v = np.zeros(len(triangles)), np.zeros(len(triangles))
    u[nonvertical] = ((delta[:,0]*edge_c[:,1]-delta[:,1]*edge_c[:,0])[nonvertical]
                      / determinant[nonvertical])
    v[nonvertical] = ((edge_b[:,0]*delta[:,1]-edge_b[:,1]*delta[:,0])[nonvertical]
                      / determinant[nonvertical])
    inside = nonvertical & (u >= 0) & (v >= 0) & (u+v <= 1)
    hit_y = (triangles[:,0,1] + u*(triangles[:,1,1]-triangles[:,0,1])
             + v*(triangles[:,2,1]-triangles[:,0,1]))
    # The XZ determinant is minus the triangle normal's Y component.
    events = sorted(zip(hit_y[inside], np.sign(determinant[inside])))
    grouped = []
    for y, change in events:
        if grouped and abs(y-grouped[-1][0]) <= 1e-5:
            grouped[-1][1] += int(change)
        else:
            grouped.append([float(y), int(change)])
    winding = 0
    previous_y = float("-inf")
    for y, change in grouped:
        interval_lo, interval_hi = max(previous_y,bottom), min(y,top)
        assert interval_hi-interval_lo <= 1e-4 or winding > 0, (
            f"UNATO support at XZ {point.tolist()} has a vertical gap "
            f"from Y {interval_lo:.5f} to {interval_hi:.5f}")
        winding += change
        previous_y = y
    assert previous_y >= top-1e-4 and winding == 0, "UNATO corner support is open or does not reach the contact plane"


def verify_stack(data, record):
    stack = record["stack"]
    pitch = float(stack["pitch_y"])
    bottom, top = float(stack["bottom_plane_y"]), float(stack["top_plane_y"])
    equipment_y = float(stack["max_equipment_y"])
    xyz = data[:, :3]
    triangles = xyz.reshape(-1,3,3)
    lo, hi = xyz.min(0), xyz.max(0)
    tolerance = 1e-4
    assert pitch > 0 and abs(top-bottom-pitch) <= tolerance
    assert abs(lo[1]-bottom) <= tolerance and abs(hi[1]-top) <= tolerance, "stack planes differ from actual exported extrema"
    # Global vertical separation proves that even roof equipment cannot
    # intersect an identical copy translated by the declared stack pitch.
    separation = (lo[1]+pitch)-hi[1]
    assert abs(separation) <= tolerance, f"UNATO copies overlap or float at the declared pitch: gap={separation}"

    contacts = stack["contacts"]
    assert len(contacts) == 4, "four corner contact pads are required"
    footprint_size = (hi-lo)[[0,2]]
    footprint_mid = ((hi+lo)*.5)[[0,2]]
    quadrants = set()
    contact_vertices = np.zeros(len(xyz), dtype=bool)
    face_cross = np.cross(triangles[:,1]-triangles[:,0],triangles[:,2]-triangles[:,0])
    face_normals = face_cross/np.linalg.norm(face_cross,axis=1)[:,None]
    top_faces = triangles[(abs(triangles[:,:,1]-top) <= tolerance).all(1) & (face_normals[:,1] > .999)]
    bottom_faces = triangles[(abs(triangles[:,:,1]-bottom) <= tolerance).all(1) & (face_normals[:,1] < -.999)]
    for index, contact in enumerate(contacts, 1):
        center = np.asarray(contact["center_xz"], dtype=float)
        size = np.asarray(contact["size_xz"], dtype=float)
        assert center.shape == (2,) and size.shape == (2,) and np.isfinite([center,size]).all()
        assert (size > 0).all() and np.prod(size) >= .01*np.prod(footprint_size), "corner contact pad is too small for the footprint"
        pad_lo, pad_hi = center-size*.5, center+size*.5
        assert (pad_lo >= lo[[0,2]]-tolerance).all() and (pad_hi <= hi[[0,2]]+tolerance).all(), "contact pad lies beyond exported geometry"
        displacement = center-footprint_mid
        assert (abs(displacement) >= .35*footprint_size).all(), "stack contact must support an outer corner"
        quadrants.add(tuple(np.sign(displacement).astype(int)))
        for faces, label in ((top_faces,"top"),(bottom_faces,"bottom")):
            missing_area = uncovered_contact_area(faces, center, size)
            assert missing_area <= np.prod(size)*1e-5, f"UNATO corner {index} {label} contact has {missing_area:.6f} uncovered area"
        # A small off-center offset avoids triangulation diagonals. Both
        # samples must remain in actual solid support all the way up.
        for offset in ((.137,.073),(-.113,-.097)):
            verify_vertical_support(triangles, center+np.asarray(offset), bottom, top)
        contact_vertices |= ((xyz[:,[0,2]] >= pad_lo-tolerance)
                             & (xyz[:,[0,2]] <= pad_hi+tolerance)).all(1)
    assert quadrants == {(-1,-1),(-1,1),(1,-1),(1,1)}, "stack pads do not cover all four corners"
    assert (~contact_vertices).any(), "missing noncontact body geometry"
    assert xyz[~contact_vertices,1].max() <= equipment_y+tolerance, "roof equipment exceeds its declared stacking clearance"
    assert equipment_y <= top-.5, "roof equipment has insufficient clearance beneath the next module"
    print(f"PASS: container13 stack at +{pitch:g}Y — no overlap, four fully covered flat contacts, continuous corner supports, roof clearance")


def main():
    mounts = read_lua_contract()
    doc = ET.parse(MODEL)
    root = doc.getroot()
    assert root.find("c:asset/c:up_axis", NS).text == "Y_UP"
    assert float(root.find("c:asset/c:unit", NS).get("meter")) == 1, "engine-unit geometry must not be rescaled"
    centers = root.findall(".//c:visual_scene/c:node[@name='center']", NS)
    assert len(centers) == 1, "one common center root required for mount adaptation"
    center = centers[0]
    assert not center.findall("c:instance_geometry", NS), "center must stay empty"
    children = center.findall("c:node", NS)
    assert {n.get("name") for n in children} == {f"container{i}" for i in range(1,len(VARIANTS)+1)}
    for node in children:
        assert not node.findall("c:node", NS), "variant must be one flat complete piece"
        assert len(node.findall("c:instance_geometry", NS)) == 1
    geometries = root.findall("c:library_geometries/c:geometry", NS)
    assert len(geometries) == len(VARIANTS), "one geometry per complete visible variant"

    pieces, transforms = import_geometry(MODEL)
    assert set(pieces) == {f"container{i}" for i in range(1,len(VARIANTS)+1)}
    assert np.allclose(transforms["center"], np.eye(4)), "mount adapter assumes an identity center basis"
    manifest = json.loads((ROOT/"tools/truck_service_payloads/manifest.json").read_text())
    assert manifest["model"] == "objects3d/truckPayloadService.dae"
    assert manifest["sha256"] == hashlib.sha256(MODEL.read_bytes()).hexdigest()
    records = manifest["variants"]
    assert len(records) == len(VARIANTS)
    records = {r["piece"]:r for r in records}
    atlas_rectangles = list(manifest["atlas_rectangles_top_left"].values())
    sidecar = (ROOT/"objects3d/truckPayloadService.dae.lua").read_text()
    assert re.search(r'tex1\s*=\s*"house_asian_diffuse\.dds"', sidecar)
    assert re.search(r'tex2\s*=\s*"house_asian_selfilu_reflection\.png"', sidecar)
    assert "house_arab" not in sidecar
    radius = float(re.search(r"radius\s*=\s*([\d.]+)", sidecar).group(1))
    height = float(re.search(r"height\s*=\s*([\d.]+)", sidecar).group(1))
    mid = np.asarray([float(x) for x in re.search(r"midpos\s*=\s*\{([^}]+)\}",sidecar).group(1).split(",")])
    for texture in ("house_asian_diffuse.dds", "house_asian_selfilu_reflection.png", "house_asian_normal.dds"):
        assert (ROOT/"unittextures"/texture).is_file(), f"missing existing atlas: {texture}"

    carrier_data = {}
    for carrier, offset in mounts.items():
        geom, nodes = import_geometry(ROOT/"objects3d"/(carrier+".dae"))
        assert "attachPoint" in nodes and "body" in geom
        attachment = nodes["attachPoint"][:3,3]
        triangles = geom["body"][:,:3].reshape(-1,3,3) - attachment
        carrier_data[carrier] = triangles

    total_triangles = 0
    for index in range(1,len(VARIANTS)+1):
        name = f"container{index}"
        data = pieces[name]
        assert np.isfinite(data).all(), f"nonfinite coordinates/attributes: {name}"
        xyz, normals, uv = data[:,:3], data[:,3:6], data[:,6:8]
        triangles = data.reshape(-1,3,8)
        assert 200 <= len(triangles) <= 3000, f"unexpected visible geometry budget: {name}"
        total_triangles += len(triangles)
        assert len(triangles) == records[name]["triangles"]
        lo, hi = xyz.min(0), xyz.max(0)
        assert np.allclose([lo,hi], records[name]["bounds"], atol=1e-4)
        assert np.allclose(np.linalg.norm(normals,axis=1), 1, atol=1e-5)
        face_cross = np.cross(triangles[:,1,:3]-triangles[:,0,:3],triangles[:,2,:3]-triangles[:,0,:3])
        twice_area = np.linalg.norm(face_cross,axis=1)
        assert (twice_area > 1e-6).all(), f"degenerate triangle: {name}"
        agreement = (face_cross*triangles[:,0,3:6]).sum(1)/twice_area
        assert (agreement > .99).all(), f"incorrect normals/winding: {name}"
        assert (uv >= -1e-6).all() and (uv <= 1+1e-6).all(), f"unbounded UVs: {name}"
        assert (np.ptp(uv,axis=0) > .1).all(), f"collapsed atlas mapping: {name}"
        contained = np.zeros(len(triangles),dtype=bool)
        tuv = triangles[:,:,6:8]
        for u0,v0,u1,v1 in atlas_rectangles:
            contained |= ((tuv[:,:,0]>=u0-1e-5)&(tuv[:,:,0]<=u1+1e-5)
                &(tuv[:,:,1]>=1-v1-1e-5)&(tuv[:,:,1]<=1-v0+1e-5)).all(1)
        assert contained.all(), f"triangle spans unrelated atlas islands: {name}"
        assert np.linalg.norm(xyz-mid,axis=1).max() <= radius+.01, f"model radius clips geometry: {name}"
        assert hi[1] <= height+.01 and lo[1] >= 2.09, f"bad payload height or underside: {name}"
        assert (hi-lo > [20,15,35]).all(), f"incorrect export scale: {name}"
        for carrier, offset in mounts.items():
            mounted_lo, mounted_hi = lo+offset, hi+offset
            # Script-driven center moves do not enlarge the static sidecar.
            # Its culling bounds must contain every mounted variant as well
            # as the unshifted model imported above.
            mounted_radius = np.linalg.norm(xyz+offset-mid, axis=1).max()
            assert mounted_radius <= radius+.01, f"{name} on {carrier}: animated center exceeds model radius ({mounted_radius:.4f}>{radius})"
            assert mounted_hi[1] <= height+.01, f"{name} on {carrier}: animated center exceeds model height ({mounted_hi[1]:.4f}>{height})"
            surface = carrier_surface_under(carrier_data[carrier], mounted_lo, mounted_hi)
            # This checks the full triangle surface crossing the footprint,
            # including slopes whose original vertices lie outside the box.
            gap = mounted_lo[1]-surface[:,1].max()
            assert .01 <= gap <= .8, f"{name} on {carrier}: intersects or floats above bed/cab, gap={gap:.4f}"
            body = carrier_data[carrier].reshape(-1,3)
            assert mounted_lo[2] >= body[:,2].min()-.1, f"{name} overhangs {carrier} rear edge"
            assert mounted_lo[0] >= body[:,0].min()-.1 and mounted_hi[0] <= body[:,0].max()+.1, f"{name} exceeds {carrier} width"
        print(f"PASS: {name} {records[name]['title']} — {len(triangles)} triangles; native import, UVs, winding, all three carriers")
    assert total_triangles <= 30000, "bundle geometry budget exceeded"
    verify_stack(pieces["container13"], records["container13"])
    print(f"PASS: single unit / one bundle / {len(VARIANTS)} complete pieces / {total_triangles:,} total resident triangles")


if __name__ == "__main__":
    main()
