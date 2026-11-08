"""MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/tank_camouflage_gpu.py

Compile the shipping shader and check projection, pixel blocks, darkness,
viewport origins and foreground occlusion in a real offscreen GL context.
"""
from pathlib import Path
import ctypes
import moderngl
import numpy as np

root = Path(__file__).resolve().parents[1] / 'luarules/gadgets/shaders'
ctx = moderngl.create_standalone_context(backend='egl', require=330)
shader = ctx.program(
    vertex_shader=(root / 'tankCamouflage.vert').read_text(),
    fragment_shader=(root / 'tankCamouflage.frag').read_text())
solid = ctx.program(
    vertex_shader='#version 150 compatibility\nvoid main(){gl_Position=gl_Vertex;}',
    fragment_shader='#version 150 compatibility\nuniform vec3 color; out vec4 frag; void main(){frag=vec4(color,1);}')
w, h = 192, 144
ox, oy = 17, 23
target = ctx.texture((w + ox, h + oy), 4, dtype='f4')
depth = ctx.depth_texture(target.size)
fbo = ctx.framebuffer([target], depth)
fbo.use()
ctx.viewport = (ox, oy, w, h)
ctx.enable(moderngl.DEPTH_TEST)
ctx.depth_func = '<='
y, x = np.mgrid[0:h, 0:w]
terrain = np.stack([.1 + .7*x/w, .1 + .7*y/h, .2 + .25*((x//24+y//24) % 2)], axis=-1).astype('f4')
texture = ctx.texture((w, h), 3, terrain.tobytes(), dtype='f4')
texture.filter = (moderngl.NEAREST, moderngl.NEAREST)
texture.use(0)
shader['terrainTex'].value = 0
shader['viewport'].value = (ox, oy, w, h)
shader['effectTime'].value = 2
shader['seed'].value = 1.73
shader['pixelSize'].value = 6

gl = ctypes.CDLL('libGL.so.1')
for name, args in {
    'glUseProgram': [ctypes.c_uint], 'glBegin': [ctypes.c_uint],
    'glVertex3f': [ctypes.c_float]*3,
}.items():
    getattr(gl, name).argtypes = args

def quad(program, left=-1, bottom=-1, right=1, top=1, z=0):
    gl.glUseProgram(program.glo)
    gl.glBegin(7)
    for a, b in [(left, bottom), (right, bottom), (right, top), (left, top)]:
        gl.glVertex3f(a, b, z)
    gl.glEnd()
    gl.glUseProgram(0)

def read():
    assert ctx.error == 'GL_NO_ERROR', ctx.error
    image = np.frombuffer(target.read(), 'f4').reshape(h + oy, w + ox, 4)
    assert np.isfinite(image).all()
    return image[oy:, ox:].copy()

fbo.clear(depth=1)
quad(shader)
image = read()
assert np.all(image[..., 3] == 1), 'camouflage has transparent holes'
# Most cells must repeat a single ground sample, not merely tint the tank mesh.
blocks = image[..., :3].reshape(h//6, 6, w//6, 6, 3).transpose(0, 2, 1, 3, 4)
assert np.max(np.ptp(blocks, axis=(2, 3))) < 1e-5, 'pixel blocks interpolate'
sx = np.minimum((x//6)*6 + 3, w-1)
sy = np.minimum((y//6)*6 + 3, h-1)
expected = terrain[sy, sx]
assert np.mean(np.abs(image[..., :3] - expected)) < .025, 'projection misaligned or defects overpower terrain'
assert np.mean(np.abs(image[..., :3] - expected) > .12) < .02, 'too many large faults'
shader['effectTime'].value = 2.3
quad(shader)
later = read()
changed = np.any(abs(later - image) > 1e-5, axis=-1)
assert 0 < changed.mean() < .1, 'faults static or whole canopy flickers'

# An opaque wall in front must survive; no pixels beyond the canopy may change.
fbo.clear(.08, .08, .08, 1, depth=1)
solid['color'].value = (1, 0, 0)
quad(solid, left=-.15, right=.15, z=-.5)
quad(shader, left=-.75, bottom=-.75, right=.75, top=.75)
occluded = read()
assert np.allclose(occluded[h//2, w//2], [1, 0, 0, 1]), 'foreground wall overwritten'
assert np.allclose(occluded[0, 0], [.08, .08, .08, 1]), 'effect leaks beyond panel'
assert np.mean(occluded[h//3:2*h//3, w//4, :3]) > .1, 'panel did not render beside wall'

texture.write(np.zeros_like(terrain).tobytes())
fbo.clear(depth=1)
quad(shader)
assert np.max(read()[..., :3]) == 0, 'defects add light at night'
print('PASS GPU: shader compile/link, aligned ground, opaque 6px cells, sparse animated faults, foreground depth, panel bounds, dark night and offset viewport')
