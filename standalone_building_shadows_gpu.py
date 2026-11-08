"""Actual Lua 5.1 standalone columns, occupancy drawing and production shaders.

Run from the repository root with numpy, lupa, moderngl and Mesa EGL:
  MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/standalone_building_shadows_gpu.py

The static building path uses 128-elmo height bands. This tests its real band
boundaries, not the finer analytic ray intersections used for mobile units.
"""
import ctypes as C
import os
from pathlib import Path

os.environ.setdefault("MESA_GL_VERSION_OVERRIDE", "3.3COMPAT")
import moderngl
import numpy as np
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
os.chdir(ROOT)
ctx = moderngl.create_standalone_context(backend="egl", require=330)
gl = C.CDLL("libGL.so.1")
for name, args in {
    "glUseProgram": [C.c_uint], "glBegin": [C.c_uint],
    "glMatrixMode": [C.c_uint], "glOrtho": [C.c_double] * 6,
    "glRotatef": [C.c_float] * 4, "glVertex3f": [C.c_float] * 3,
    "glTexCoord2f": [C.c_float] * 2, "glColor4f": [C.c_float] * 4,
    "glClearColor": [C.c_float] * 4, "glClear": [C.c_uint],
    "glDisable": [C.c_uint], "glDepthMask": [C.c_ubyte],
    "glActiveTexture": [C.c_uint], "glBindTexture": [C.c_uint, C.c_uint],
}.items():
    getattr(gl, name).argtypes = args


def begin_end(kind, callback, *args):
    gl.glBegin(int(kind))
    callback(*args)
    gl.glEnd()


def clear(mask, r, g, b, a):
    gl.glClearColor(r, g, b, a)
    gl.glClear(mask)


def unbind_texture(value):
    assert value is False
    gl.glActiveTexture(0x84C0)
    gl.glBindTexture(0x0DE1, 0)
    gl.glDisable(0x0DE1)


lua = LuaRuntime(unpack_returned_tuples=True)
fixture = lua.execute((ROOT / "tests/standalone_building_shadows.lua").read_text())
fixture["setGL"](lua.table_from({
    "Vertex": gl.glVertex3f, "BeginEnd": begin_end, "Clear": clear,
    "DepthTest": lambda _: gl.glDisable(0x0B71), "DepthMask": gl.glDepthMask,
    "Blending": lambda _: gl.glDisable(0x0BE2), "Culling": lambda _: gl.glDisable(0x0B44),
    "Texture": unbind_texture, "Color": gl.glColor4f,
    "MatrixMode": gl.glMatrixMode, "PushMatrix": gl.glPushMatrix,
    "PopMatrix": gl.glPopMatrix, "LoadIdentity": gl.glLoadIdentity, "Ortho": gl.glOrtho,
}))
assert fixture["count"]() == 1
occupancy = ctx.texture((512, 512), 4, dtype="f4")
occupancy.filter = (moderngl.NEAREST, moderngl.NEAREST)
occupancy.repeat_x = occupancy.repeat_y = False
occupancy_fbo = ctx.framebuffer([occupancy])
output = ctx.texture((256, 256), 4, dtype="f4")
output_fbo = ctx.framebuffer([output])


def pixels(texture):
    image = np.frombuffer(texture.read(), "f4").reshape(texture.height, texture.width, 4).copy()
    assert np.isfinite(image).all()
    assert ctx.error == "GL_NO_ERROR"
    return image


def capture(layer):
    occupancy_fbo.use()
    gl.glUseProgram(0)
    fixture["layer"](layer)
    return pixels(occupancy)[..., 0]


shader_root = ROOT / "luaui/widgets_mosaic/shaders"
cone = ctx.program(vertex_shader=(shader_root / "headlights/cone_emission.vert").read_text(),
                   fragment_shader=(shader_root / "headlights/cone_emission.frag").read_text())
for key, value in {"buildingOccupancy": 0, "mapSize": (512, 512),
                   "lightRange": 245, "strength": 1}.items():
    cone[key].value = value


def headlight(origin=(272, 64), direction=(0, 1), height=16, blocked=True,
              domain=(0, 512, 0, 512)):
    output_fbo.use()
    output_fbo.clear()
    occupancy.use(0)
    cone["lamp"].value = (origin[0], height, origin[1])
    cone["forward"].value = direction
    cone["hasOccupancy"].value = int(blocked)
    gl.glMatrixMode(0x1701)
    gl.glLoadIdentity()
    gl.glOrtho(*domain, -100000, 100000)
    gl.glMatrixMode(0x1700)
    gl.glLoadIdentity()
    gl.glRotatef(-90, 1, 0, 0)
    gl.glUseProgram(cone.glo)
    gl.glBegin(7)
    x, z = origin
    fx, fz = direction
    reach, width = 245, 3 + 245 * .42
    for vx, vz in ((x - fz * 3, z + fx * 3), (x + fz * 3, z - fx * 3),
                   (x + fx * reach + fz * width, z + fz * reach - fx * width),
                   (x + fx * reach - fz * width, z + fz * reach + fx * width)):
        gl.glVertex3f(vx, height, vz)
    gl.glEnd()
    gl.glUseProgram(0)
    return pixels(output)[..., :3]


mask = capture(0)
expected = np.zeros((512, 512), "f4")
expected[124:172, 240:304] = 1
assert np.array_equal(mask, expected), "actual occupancy lost piece offset, importer basis or world translation"
baseline = headlight(blocked=False)
blocked = headlight()
assert baseline[90:].sum() > 10 and blocked[90:].max() == 0, "headlight emission crossed the selected solid body"
assert np.allclose(blocked[:57], baseline[:57]), "solid body erased the light in front"

# Use the same actual column texture in the production cascade/resolve pair.
vertex = "#version 150 compatibility\nvoid main(){gl_Position=gl_Vertex;gl_TexCoord[0]=gl_MultiTexCoord0;}"
propagate_source = (shader_root / "radiancecascade/propagate.frag").read_text().replace(
    "#version 150 compatibility", "#version 150 compatibility\n#define BASE_PROBES 32\n#define CASCADE_COUNT 4\n#define MAX_TRACE_STEPS 256")
propagate = ctx.program(vertex_shader=vertex, fragment_shader=propagate_source)
resolve = ctx.program(vertex_shader=vertex, fragment_shader=(shader_root / "radiancecascade/resolve.frag").read_text())
emission_data = np.zeros((256, 256, 4), "f4")
emission_data[36:44, 132:140, :3] = (1, .2, .05)
emission = ctx.texture((256, 256), 4, emission_data.tobytes(), dtype="f4")
emission.filter = (moderngl.NEAREST, moderngl.NEAREST)
emission.repeat_x = emission.repeat_y = False
cascades = [ctx.texture((64, 64), 4, dtype="f4") for _ in range(4)]
cascade_fbos = [ctx.framebuffer([texture]) for texture in cascades]
for texture in cascades:
    texture.filter = (moderngl.NEAREST, moderngl.NEAREST)
for key, value in {"emissionTex": 0, "occupancyTex": 1, "parentTex": 2,
                   "mapSize": (512, 512), "baseInterval": 8}.items():
    propagate[key].value = value
for key, value in {"cascadeTex": 0, "occupancyTex": 1, "emissionTex": 2, "intensity": 1}.items():
    resolve[key].value = value


def quad(program):
    gl.glUseProgram(program.glo)
    gl.glBegin(7)
    for x, y, u, v in ((-1, -1, 0, 0), (1, -1, 1, 0), (1, 1, 1, 1), (-1, 1, 0, 1)):
        gl.glTexCoord2f(u, v)
        gl.glVertex3f(x, y, 0)
    gl.glEnd()
    gl.glUseProgram(0)


def radiance():
    emission.use(0)
    occupancy.use(1)
    for index in range(3, -1, -1):
        (cascades[index + 1] if index < 3 else emission).use(2)
        cascade_fbos[index].use()
        propagate["cascadeIndex"].value = index
        propagate["hasParent"].value = int(index < 3)
        quad(propagate)
    cascades[0].use(0)
    occupancy.use(1)
    emission.use(2)
    output_fbo.use()
    quad(resolve)
    return pixels(output)[..., :3]


shadowed_radiance = radiance()
assert shadowed_radiance[62:86, 120:152].max() == 0, "occupied standalone receivers accepted radiance"
assert capture(1).max() == 0, "the 128..256 band retained a body whose top is 88"
upper_radiance = radiance()
behind = np.s_[96:112, 128:144]
assert upper_radiance[behind].sum() > .001, "control source failed to propagate behind the future blocker"
ratio = float(shadowed_radiance[behind].sum() / upper_radiance[behind].sum())
assert ratio < .1, f"actual standalone occupancy failed to shadow the cascade: {ratio}"
assert np.allclose(headlight(height=160), baseline), "an overhead band inherited the low building's shadow"

# Rotation uses the same negative-right model basis as the unit renderer.
fixture["pose"](True)
turned_mask = capture(0)
expected.fill(0)
expected[64:128, 204:252] = 1
assert np.array_equal(turned_mask, expected), "rotated offset body was mirrored or recentred on the unit"
turned_base = headlight(origin=(144, 96), direction=(1, 0), blocked=False)
turned = headlight(origin=(144, 96), direction=(1, 0))
assert turned_base[:, 135:].sum() > 10 and turned[:, 135:].max() == 0
assert np.allclose(turned[:, :98], turned_base[:, :98]), "rotated body shadow reached in front of its face"
fixture["pose"](False, 160)
assert capture(0).max() == 0 and capture(1).sum() > 0, "world base height was omitted"
capture(0)
assert np.allclose(headlight(), baseline), "raised structure blocked the lower clear band"

fixture["pose"](False)
capture(0)
local_capture = headlight(domain=(144, 400, 32, 288))
assert local_capture[:84].sum() > 0 and local_capture[148:].max() == 0, "camera-local capture detached the blocker from world space"
fixture["hide"]()
assert np.array_equal(capture(0), mask), "raid presentation toggle removed the physical blocker"
fixture["show"]()
assert np.array_equal(capture(0), mask)
fixture["destroy"]()
assert fixture["count"]() == 0 and capture(0).max() == 0, "destroyed body survived in the occupancy target"
assert np.allclose(headlight(), baseline), "destroyed body left a headlight shadow"
assert np.allclose(radiance(), upper_radiance), "destroyed body left a cascade shadow"
print("PASS: actual Lua 5.1 selected geometry -> gadget -> occupancy -> headlight/cascade pixels; rotation, imported offset, height bands, camera capture, raid toggle and destruction")
print("Behind-body cascade radiance ratio:", ratio, "| Renderer:", ctx.info["GL_RENDERER"])
