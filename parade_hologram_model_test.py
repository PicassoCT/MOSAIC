#!/usr/bin/env python3
"""Validate baked native pixel pieces against the runtime Lua artwork.

Requires Lua, NumPy and Pillow. Reads exported Collada independently of the
mesh writer, including indexed positions, normals, UVs and scene bindings.
"""
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
NS = {'c': 'http://www.collada.org/2005/11/COLLADASchema'}
source = '''
local art=dofile('luarules/configs/parade_hologram_decorations.lua')
for name,part in pairs(dofile('luarules/configs/parade_ghost_parts.lua').parts) do art.glyphs[name]=part end
print('SIZE',dofile('luarules/configs/parade_hologram_spawning.lua').pixelSize)
for name,g in pairs(art.glyphs) do
 local o=g.origin or {0,0,0}; print('ORIGIN',name,o[1],o[2],o[3])
 for i,frame in ipairs(g.frames) do print('FRAME',name..'_'..i,table.concat(frame,'/')) end
 for symbol,p in pairs(g.palette) do print('COLOR',name,symbol,p[1],p[2],p[3],p[4] or 1) end
end
local b=dofile('objects3d/paradeHologram.dae.lua')
print('BOUNDS',b.radius,b.height,b.midpos[1],b.midpos[2],b.midpos[3])
'''
rows = subprocess.check_output(['lua', '-'], input=source, text=True, cwd=ROOT)
frames, colors, origins = {}, {}, {}
for line in rows.splitlines():
    f = line.split('\t')
    if f[0] == 'SIZE': size = float(f[1])
    elif f[0] == 'ORIGIN': origins[f[1]] = np.array(list(map(float, f[2:])))
    elif f[0] == 'FRAME': frames[f[1]] = f[2].split('/')
    elif f[0] == 'COLOR': colors[(f[1], f[2])] = np.array(list(map(float, f[3:])))
    elif f[0] == 'BOUNDS': radius, height, *mid = map(float, f[1:])
root = ET.parse(ROOT / 'objects3d/paradeHologram.dae').getroot()
assert root.find('c:asset/c:up_axis', NS).text == 'Y_UP'
assert float(root.find('c:asset/c:unit', NS).get('meter')) == 1
center = root.find('.//c:visual_scene/c:node', NS)
assert center.get('name') == 'center' and not center.findall('c:instance_geometry', NS)
assert {n.get('name') for n in center.findall('c:node', NS)} == set(frames)
texture_path = root.find('.//c:library_images/c:image/c:init_from', NS).text
palette = np.array(Image.open(ROOT / 'objects3d' / texture_path).convert('RGB'))
triangles_total = 0
for geo in root.findall('.//c:library_geometries/c:geometry', NS):
    name = geo.get('name')
    glyph = name.rsplit('_', 1)[0]
    frame = frames[name]
    mesh = geo.find('c:mesh', NS)
    sources = {}
    for src in mesh.findall('c:source', NS):
        stride = int(src.find('.//c:accessor', NS).get('stride'))
        sources['#' + src.get('id')] = np.fromstring(src.find('c:float_array', NS).text, sep=' ').reshape(-1, stride)
    verts = {"#" + v.get('id'): v.find('c:input', NS).get('source') for v in mesh.findall('c:vertices', NS)}
    faces = mesh.find('c:triangles', NS)
    inputs = faces.findall('c:input', NS)
    indices = np.fromstring(faces.find('c:p', NS).text, sep=' ', dtype=int).reshape(-1, len(inputs))
    data = {}
    for inp in inputs:
        ref = inp.get('source')
        data[inp.get('semantic')] = sources[verts.get(ref, ref)][indices[:, int(inp.get('offset'))]]
    xyz, normal, uv = data['VERTEX'], data['NORMAL'], data['TEXCOORD']
    triangles = xyz.reshape(-1, 3, 3)
    triangles_total += len(triangles)
    assert np.isfinite(xyz).all() and np.isfinite(uv).all()
    assert np.allclose(np.linalg.norm(normal, axis=1), 1)
    cross = np.cross(triangles[:, 1] - triangles[:, 0], triangles[:, 2] - triangles[:, 0])
    assert (np.einsum('ij,ij->i', cross, normal[::3]) > 0).all(), 'inward or degenerate face'
    assert (np.linalg.norm(xyz - mid, axis=1) <= radius).all()
    assert xyz[:, 1].max() <= height
    assert ((uv > 0) & (uv < 1)).all()
    rgb = palette[((1 - uv[:, 1]) * palette.shape[0]).astype(int), (uv[:, 0] * palette.shape[1]).astype(int)]
    blocks = xyz.reshape(-1, 36, 3)
    expected = [(row, col, symbol) for row, line in enumerate(frame) for col, symbol in enumerate(line) if symbol != '.']
    assert len(blocks) == len(expected)
    for i, (row, col, symbol) in enumerate(expected):
        cube_center = blocks[i].mean(0)
        assert np.allclose(cube_center, np.array([(col + .5 - len(frame[0]) / 2), (len(frame) - row - .5), 0]) * size + origins[glyph]*size)
        assert np.allclose(np.ptp(blocks[i], axis=0), size * .8)
        color = colors[(glyph, symbol)]
        assert np.array_equal(rgb[i * 36:(i + 1) * 36], np.tile(np.rint(255 * color[:3] * color[3]), (36, 1)))
    # Positive top-facing area ensures the native geometry can contribute to
    # the cascade's orthographic emission capture at every authored frame.
    assert cross[cross[:, 1] > 0, 1].sum() > 0
assert len(frames) == 33 and triangles_total == 14232
print('PASS: 33 native frames match ornament/ghost pixels, colors and attachment offsets; scene pieces, bounds, normals, UVs and emission area are valid')
