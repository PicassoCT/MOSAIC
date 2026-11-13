#!/usr/bin/env python3
"""Render geometry proofs from the exported parade scenery COLLADA file.

This deliberately reads the actual POSITION/NORMAL/TEXCOORD index buffers. It
does not import the authoring recipes or the voxel exporter, and does not apply
COLLADA node matrices: the parade renderer uses the same raw gl.UnitPiece mesh
coordinates. The standalone DAE uses metre=1 and identity nodes as well.
Requires NumPy and Pillow. No Blender or game installation is necessary.
Writes PNG proofs and self-contained SVGs embedding the same PNG bytes.
"""
from __future__ import annotations

import argparse
from functools import lru_cache
import base64
from dataclasses import dataclass
from html import escape
from io import BytesIO
import json
import math
from pathlib import Path
import re
import xml.etree.ElementTree as ET

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
NS = {"c": "http://www.collada.org/2005/11/COLLADASchema"}
FIGURE_CATEGORIES = ("civilian", "dead", "ai", "helper")
FIGURE_NAMES = tuple(f"parade{category}{i}" for category in FIGURE_CATEGORIES for i in range(1, 5))
PROP_NAMES = ("candle", "lantern", "moon", "envelope", "money", "koi", "lotus", "leaf", "star")
BG = (15, 22, 31)
PANEL = (20, 29, 39)
INK = (234, 232, 220)
MUTED = (149, 169, 182)
ACCENT = (205, 170, 106)


@dataclass
class Piece:
    name: str
    positions: np.ndarray  # triangles x corners x XYZ
    normals: np.ndarray
    uvs: np.ndarray
    geometry_ids: tuple[str, ...]

    @property
    def bounds(self):
        return np.stack((self.positions.min(axis=(0, 1)), self.positions.max(axis=(0, 1))))


def local_tag(element):
    return element.tag.rsplit("}", 1)[-1]


def _source_array(source):
    array = source.find("c:float_array", NS)
    accessor = source.find("c:technique_common/c:accessor", NS)
    if array is None or accessor is None:
        raise ValueError(f"Missing float-array/accessor in {source.get('id')}")
    values = np.fromstring(array.text or "", sep=" ", dtype=np.float64)
    if len(values) != int(array.get("count", -1)):
        raise ValueError(f"Array length mismatch: {array.get('id')}")
    stride = int(accessor.get("stride", "1"))
    offset = int(accessor.get("offset", "0"))
    count = int(accessor.get("count", "0"))
    if stride < 1 or count < 1 or offset + count * stride > len(values):
        raise ValueError(f"Invalid accessor: {source.get('id')}")
    return values[offset:offset + count * stride].reshape(count, stride)


def read_geometry(geometry):
    """Resolve independent COLLADA indices; reject silently incomplete meshes."""
    mesh = geometry.find("c:mesh", NS)
    if mesh is None:
        raise ValueError(f"No mesh: {geometry.get('id')}")
    sources = {source.get("id"): _source_array(source) for source in mesh.findall("c:source", NS)}
    vertices = {}
    for vertex in mesh.findall("c:vertices", NS):
        vertices[vertex.get("id")] = {
            item.get("semantic"): item.get("source", "").removeprefix("#")
            for item in vertex.findall("c:input", NS)
        }
    output = {"POSITION": [], "NORMAL": [], "TEXCOORD": []}
    primitives = [p for p in mesh if local_tag(p) in ("triangles", "polylist", "polygons", "lines", "trifans", "tristrips")]
    for primitive in primitives:
        kind = local_tag(primitive)
        if kind not in ("triangles", "polylist"):
            raise ValueError(f"Unsupported non-triangle primitive {kind}: {geometry.get('id')}")
        inputs = primitive.findall("c:input", NS)
        stride = 1 + max(int(item.get("offset", "0")) for item in inputs)
        p = primitive.find("c:p", NS)
        if p is None:
            raise ValueError(f"Missing indices: {geometry.get('id')}")
        indices = np.fromstring(p.text or "", sep=" ", dtype=np.int64)
        if len(indices) % stride:
            raise ValueError(f"Incomplete index record: {geometry.get('id')}")
        indices = indices.reshape(-1, stride)
        if kind == "triangles":
            if len(indices) != int(primitive.get("count", "0")) * 3:
                raise ValueError(f"Triangle count mismatch: {geometry.get('id')}")
            triangle_indices = indices.reshape(-1, 3, stride)
        else:
            counts = np.fromstring(primitive.findtext("c:vcount", "", NS), sep=" ", dtype=np.int64)
            if len(counts) != int(primitive.get("count", "0")) or counts.sum() != len(indices) or np.any(counts < 3):
                raise ValueError(f"Invalid polylist: {geometry.get('id')}")
            rows, start = [], 0
            for count in counts:
                polygon = indices[start:start + count]
                rows.extend(np.stack((polygon[0], polygon[j], polygon[j + 1])) for j in range(1, count - 1))
                start += count
            triangle_indices = np.array(rows)
        resolved = {}
        for item in inputs:
            semantic = item.get("semantic")
            source_id = item.get("source", "").removeprefix("#")
            offset = int(item.get("offset", "0"))
            if semantic == "VERTEX":
                for attached_semantic, attached_source in vertices[source_id].items():
                    resolved[attached_semantic] = (attached_source, offset)
            elif semantic != "TEXCOORD" or item.get("set", "0") == "0":
                resolved[semantic] = (source_id, offset)
        for semantic, dimensions in (("POSITION", 3), ("NORMAL", 3), ("TEXCOORD", 2)):
            if semantic not in resolved:
                raise ValueError(f"Missing {semantic}: {geometry.get('id')}")
            source_id, offset = resolved[semantic]
            array = sources[source_id]
            selection = triangle_indices[:, :, offset]
            if array.shape[1] < dimensions or selection.min(initial=0) < 0 or selection.max(initial=0) >= len(array):
                raise ValueError(f"Invalid {semantic} indices: {geometry.get('id')}")
            output[semantic].append(array[selection, :dimensions])
    if not output["POSITION"]:
        raise ValueError(f"Empty mesh: {geometry.get('id')}")
    return tuple(np.concatenate(output[key], axis=0) for key in ("POSITION", "NORMAL", "TEXCOORD"))


def load_export(path):
    """Read every generated mesh under its exact engine piece name."""
    tree = ET.parse(path)
    document = tree.getroot()
    geometries = {g.get("id"): g for g in document.findall("c:library_geometries/c:geometry", NS)}
    pieces, nodes, geometry_cache = {}, {}, {}
    for node in document.findall("c:library_visual_scenes/c:visual_scene//c:node", NS):
        name = node.get("name") or node.get("id")
        if not name or not name.startswith("parade"):
            continue
        if name in nodes:
            raise ValueError(f"Duplicate generated node name: {name}")
        nodes[name] = node
        instances = node.findall("c:instance_geometry", NS)
        if not instances:
            continue
        buffers = []
        geometry_ids = []
        for instance in instances:
            geometry_id = instance.get("url", "").removeprefix("#")
            if geometry_id not in geometries:
                raise ValueError(f"Dangling geometry reference in {name}: {geometry_id}")
            if geometry_id not in geometry_cache:
                geometry_cache[geometry_id] = read_geometry(geometries[geometry_id])
            buffers.append(geometry_cache[geometry_id])
            geometry_ids.append(geometry_id)
        pieces[name] = Piece(name, *(np.concatenate([buffer[k] for buffer in buffers], axis=0) for k in range(3)), tuple(geometry_ids))
    return document, nodes, pieces


def load_palette(root=ROOT):
    return json.loads((root / "tools/parade_holograms/palette.json").read_text())["patches"]


def palette_indices(uvs, palette, strict=True):
    """Each exported face must stay wholly inside one verified atlas island."""
    found = np.full(len(uvs), -1, dtype=np.int32)
    for i, patch in enumerate(palette.values()):
        u0, v0, u1, v1 = patch["uv_rect"]
        matched = ((uvs[:, :, 0] >= u0 - 2e-7) & (uvs[:, :, 0] <= u1 + 2e-7)
                   & (uvs[:, :, 1] >= v0 - 2e-7) & (uvs[:, :, 1] <= v1 + 2e-7)).all(axis=1)
        found[matched] = i
    if strict and np.any(found < 0):
        raise ValueError(f"{int(np.count_nonzero(found < 0))} triangles have UVs outside the verified atlas swatches")
    return found


def figure_piece_names(name):
    return tuple(name + role for role in ("body", "head", "mask"))


def combine_pieces(pieces, names):
    selected = [pieces[name] for name in names]
    return Piece("combined", *(np.concatenate([getattr(piece, attr) for piece in selected])
                                for attr in ("positions", "normals", "uvs")), ())


def font(size, bold=False):
    for path in (Path("/usr/share/fonts/truetype/dejavu") / ("DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"),
                 Path("/usr/share/fonts/truetype/liberation2") / ("LiberationSans-Bold.ttf" if bold else "LiberationSans-Regular.ttf")):
        if path.exists():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default(size=size)


@lru_cache(maxsize=1)
def atlas_textures():
    atlas = np.asarray(Image.open(ROOT / "unittextures/house_asian_diffuse.dds").convert("RGB"), dtype=np.float32) / 255
    material = np.asarray(Image.open(ROOT / "unittextures/house_asian_selfilu_reflection.png").convert("RGBA"), dtype=np.float32) / 255
    return atlas, material


def rasterize(screen, depths, width, height, uvs):
    atlas, material = atlas_textures()
    pixels = np.zeros((height, width, 4), dtype=np.uint8)
    depth_buffer = np.full((height, width), -np.inf, dtype=np.float64)
    for triangle, depth, uv in zip(screen, depths, uvs):
        x0 = max(0, math.floor(triangle[:, 0].min()))
        x1 = min(width - 1, math.ceil(triangle[:, 0].max()))
        y0 = max(0, math.floor(triangle[:, 1].min()))
        y1 = min(height - 1, math.ceil(triangle[:, 1].max()))
        if x0 > x1 or y0 > y1:
            continue
        a, b, c = triangle
        denominator = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
        if abs(denominator) < 1e-9:
            continue
        xx = np.arange(x0, x1 + 1, dtype=np.float64)[None, :] + .5
        yy = np.arange(y0, y1 + 1, dtype=np.float64)[:, None] + .5
        wa = ((b[1] - c[1]) * (xx - c[0]) + (c[0] - b[0]) * (yy - c[1])) / denominator
        wb = ((c[1] - a[1]) * (xx - c[0]) + (a[0] - c[0]) * (yy - c[1])) / denominator
        wc = 1 - wa - wb
        z = wa * depth[0] + wb * depth[1] + wc * depth[2]
        target = depth_buffer[y0:y1 + 1, x0:x1 + 1]
        # Strict physical depth; double precision avoids quantizing close
        # surfaces into ties. Actual coincident role faces are a model error
        # checked separately by the exported-model validator.
        visible = (wa >= -1e-6) & (wb >= -1e-6) & (wc >= -1e-6) & (z > target)
        if visible.any():
            target[visible] = z[visible]
            sample = wa[..., None]*uv[0]+wb[..., None]*uv[1]+wc[..., None]*uv[2]
            tx=np.clip((sample[...,0]*4096).astype(int),0,4095); ty=np.clip(((1-sample[...,1])*4096).astype(int),0,4095)
            rgb=atlas[ty,tx]*(0.30+0.70*material[ty,tx,0,None])
            pixels[y0:y1 + 1, x0:x1 + 1][visible, :3] = np.clip(np.rint(rgb[visible] * 255), 0, 255).astype(np.uint8)
            pixels[y0:y1 + 1, x0:x1 + 1][visible, 3] = np.rint(material[ty,tx,3][visible] * 255).astype(np.uint8)
    return Image.fromarray(pixels)


def render_piece(piece, palette, size, camera=(.72, .28, 1.3), padding=15, frame_bounds=None):
    width, height = size
    camera = np.array(camera, dtype=float)
    camera /= np.linalg.norm(camera)
    right = np.cross([0, 1, 0], camera)
    right /= np.linalg.norm(right)
    up = np.cross(camera, right)
    positions = piece.positions
    projected = np.stack((positions @ right, positions @ up), axis=-1)
    low, high = frame_bounds if frame_bounds is not None else (projected.min(axis=(0, 1)), projected.max(axis=(0, 1)))
    scale = min((width - 2 * padding) / max(high[0] - low[0], .01),
                (height - 2 * padding) / max(high[1] - low[1], .01))
    screen = (projected - (low + high) / 2) * [scale, -scale] + [width / 2, height / 2]
    normals = np.cross(positions[:, 1] - positions[:, 0], positions[:, 2] - positions[:, 0])
    front_facing = (normals @ camera) > 1e-7
    return rasterize(screen[front_facing], (positions @ camera)[front_facing], width, height, piece.uvs[front_facing])


def _read_labels(root):
    path = root / "tools/parade_holograms/manifest.json"
    if not path.exists():
        return {}
    data = json.loads(path.read_text())
    labels = {}
    def collect(value):
        if isinstance(value, dict):
            key = value.get("slug") or value.get("name") or value.get("piece")
            label = value.get("label") or value.get("title")
            if key and label:
                labels[key] = label
            for k, v in value.items():
                if isinstance(v, dict) and k.startswith("parade"):
                    labels[k] = v.get("label") or v.get("title") or k
                collect(v)
        elif isinstance(value, list):
            for item in value:
                collect(item)
    collect(data)
    return labels


def render_figure_sheet(pieces, palette, output, labels):
    cell_w, cell_h = 480, 460
    margin, header, footer = 42, 145, 78
    width, height = margin * 2 + cell_w * 4, header + cell_h * 4 + footer
    image = Image.new("RGB", (width, height), BG)
    draw = ImageDraw.Draw(image)
    draw.text((margin, 28), "MOSAIC / PARADE HOLOGRAMS", font=font(31, True), fill=INK)
    draw.text((margin, 77), "16 low-poly cage-surface figures · front and three-quarter views", font=font(21), fill=MUTED)
    draw.text((margin, 108), "Actual DAE index buffers and Asian-house atlas colours. Each panel fits its model; world heights are stated.", font=font(15), fill=MUTED)
    for index, name in enumerate(FIGURE_NAMES):
        row, col = divmod(index, 4)
        x, y = margin + col * cell_w, header + row * cell_h
        draw.rounded_rectangle((x + 4, y + 4, x + cell_w - 9, y + cell_h - 9), 9, fill=PANEL, outline=(43, 56, 67))
        piece = combine_pieces(pieces, figure_piece_names(name))
        category = FIGURE_CATEGORIES[row]
        title = labels.get(name, "Null Lux" if name == "paradeai1" else f"{category.capitalize()} {col + 1}")
        title = re.sub(r"\s+", " ", title)
        if len(title) > 33:
            title = title[:30] + "…"
        draw.text((x + 19, y + 17), title, font=font(22, True), fill=INK)
        model_height = piece.bounds[1, 1] - piece.bounds[0, 1]
        triangles = len(piece.positions)
        draw.text((x + 19, y + 50), f"{category.upper()}  ·  {model_height:.2f} units  ·  {triangles:,} triangles", font=font(13), fill=MUTED)
        # Two deliberately distinct cameras; these are not duplicated images.
        for camera, region, label in (((.72, .28, 1.3), (277, 335), "THREE-QUARTER"), ((0, 0, 1), (159, 294), "FRONT")):
            first = label == "THREE-QUARTER"
            px, py = x + (13 if first else 303), y + (80 if first else 113)
            preview = render_piece(piece, palette, region, camera=camera)
            image.paste(preview, (px, py), preview)
            draw.text((px + region[0] / 2, y + 426), label, font=font(11, True), fill=MUTED, anchor="mt")
    draw.line((margin, height - 59, width - margin, height - 59), fill=(58, 73, 85), width=1)
    draw.text((margin, height - 44), "Body, head and mask are independently named native pieces. This is a mesh proof, not an in-engine lighting capture.", font=font(17), fill=MUTED)
    image.save(output)
    return output


def render_props_sheet(pieces, palette, output):
    catalog = json.loads((ROOT / "tools/parade_holograms/import_manifest.json").read_text())["catalog"]
    prop_names = []
    assembled = {}
    for key, definition in catalog["props"].items():
        for index, choice in enumerate(definition["variants"], 1):
            name = definition["label"] + (f" {index}" if len(definition["variants"]) > 1 else "")
            members = [choice["piece"]] + [w["piece"] for w in choice.get("wings", [])]
            assembled[name] = combine_pieces(pieces, members)
            prop_names.append(name)
    cols = min(5, len(prop_names))
    rows = math.ceil(len(prop_names) / cols)
    cell_w, cell_h, margin, header = 370, 390, 36, 128
    width, height = margin * 2 + cols * cell_w, header + rows * cell_h + 58
    image = Image.new("RGB", (width, height), BG)
    draw = ImageDraw.Draw(image)
    draw.text((margin, 27), "MOSAIC / HOLOGRAPHIC SCENERY", font=font(29, True), fill=INK)
    draw.text((margin, 75), "Low-poly cage surfaces and atlas gradients · ground candles and airborne decorations", font=font(19), fill=MUTED)
    for index, prop in enumerate(prop_names):
        row, col = divmod(index, cols)
        x, y = margin + col * cell_w, header + row * cell_h
        draw.rounded_rectangle((x + 3, y + 3, x + cell_w - 8, y + cell_h - 8), 9, fill=PANEL, outline=(43, 56, 67))
        piece = assembled[prop]
        draw.text((x + 17, y + 16), prop.upper(), font=font(22, True), fill=INK)
        extents = piece.bounds[1] - piece.bounds[0]
        draw.text((x + 17, y + 48), f"{len(piece.positions):,} triangles  ·  {extents[1]:.2f} units high", font=font(14), fill=MUTED)
        preview = render_piece(piece, palette, (cell_w - 34, cell_h - 116), camera=(.52, .45, 1.35))
        image.paste(preview, (x + 13, y + 80), preview)
    draw.text((margin, height - 39), "Parsed directly from paradeHologramSceneryRuntime.dae. Atlas colours; no generated-image reconstruction.", font=font(16), fill=MUTED)
    image.save(output)
    return output


def write_svg_wrapper(png_path, output=None):
    """Embed the exact PNG bytes in a portable SVG without re-encoding pixels."""
    png_path = Path(png_path)
    output = Path(output) if output is not None else png_path.with_suffix(".svg")
    png_bytes = png_path.read_bytes()
    with Image.open(BytesIO(png_bytes)) as proof:
        if proof.format != "PNG":
            raise ValueError(f"Expected a PNG proof: {png_path}")
        width, height = proof.size
    encoded = base64.b64encode(png_bytes).decode("ascii")
    title = escape(f"MOSAIC parade hologram {png_path.stem} — exported mesh proof")
    output.write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<svg xmlns="http://www.w3.org/2000/svg" '
        'xmlns:xlink="http://www.w3.org/1999/xlink" '
        f'width="{width}" height="{height}" viewBox="0 0 {width} {height}" '
        'role="img" aria-labelledby="title description">\n'
        f'  <title id="title">{title}</title>\n'
        '  <desc id="description">Actual exported DAE geometry and atlas colours. '
        'The embedded PNG is preserved byte for byte.</desc>\n'
        f'  <image width="{width}" height="{height}" '
        f'xlink:href="data:image/png;base64,{encoded}"/>\n'
        '</svg>\n',
        encoding="utf-8",
    )
    return output


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--model", type=Path)
    parser.add_argument("--output-dir", type=Path)
    args = parser.parse_args()
    model = args.model or args.root / "objects3d/paradeHologramSceneryRuntime.dae"
    output_dir = args.output_dir or args.root / "docs/images/parade-holograms"
    if not output_dir.is_absolute():
        output_dir = args.root / output_dir
    _, _, pieces = load_export(model)
    missing = {piece for figure in FIGURE_NAMES for piece in figure_piece_names(figure)} - pieces.keys()
    if missing:
        raise SystemExit("Missing expected exported pieces: " + ", ".join(sorted(missing)))
    output_dir.mkdir(parents=True, exist_ok=True)
    palette = load_palette(args.root)
    labels = _read_labels(args.root)
    figure_proof = render_figure_sheet(pieces, palette, output_dir / "figures.png", labels)
    prop_proof = render_props_sheet(pieces, palette, output_dir / "props.png")
    for proof in (figure_proof, prop_proof):
        print(proof)
        print(write_svg_wrapper(proof))


if __name__ == "__main__":
    main()
