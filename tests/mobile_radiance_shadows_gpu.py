"""Production mobile-shadow GLSL and height-provenance integration.

MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/mobile_radiance_shadows_gpu.py
Requires numpy, moderngl and Mesa EGL. Uses geometric fixtures with explicit
expected outcomes; no substitute CPU intersection implementation is tested.
"""
from pathlib import Path
import ctypes

import moderngl
import numpy as np


ROOT = Path(__file__).resolve().parents[1]
SHADERS = ROOT / "luaui/widgets_mosaic/shaders/radiancecascade"
ctx = moderngl.create_standalone_context(backend="egl", require=330)
gl = ctypes.CDLL("libGL.so.1")
for name, arguments in {
    "glUseProgram": [ctypes.c_uint],
    "glBegin": [ctypes.c_uint],
    "glVertex2f": [ctypes.c_float] * 2,
    "glVertex3f": [ctypes.c_float] * 3,
    "glTexCoord2f": [ctypes.c_float] * 2,
    "glMatrixMode": [ctypes.c_uint],
    "glOrtho": [ctypes.c_double] * 6,
    "glRotatef": [ctypes.c_float] * 4,
    "glColor4f": [ctypes.c_float] * 4,
}.items():
    getattr(gl, name).argtypes = arguments

VERTEX = """#version 150 compatibility
void main(){gl_Position=gl_Vertex;gl_TexCoord[0]=gl_MultiTexCoord0;}
"""
helper = (SHADERS / "mobile_shadow.glsl").read_text()


def source(name, defines="", inject=False):
    text = (SHADERS / name).read_text()
    if defines:
        text = text.replace("#version 150 compatibility",
                            "#version 150 compatibility\n" + defines, 1)
    if inject:
        assert "// MOBILE_SHADOWS" in text, "production mobile-shadow injection point missing"
        text = text.replace("#version 150 compatibility", "#version 150 compatibility\n#define MOBILE_SHADOWS_ENABLED 1", 1)
        text = text.replace("// MOBILE_SHADOWS", helper, 1)
    return text


def quad(program):
    gl.glUseProgram(program.glo)
    gl.glBegin(7)
    for x, y, u, v in [(-1, -1, 0, 0), (1, -1, 1, 0),
                        (1, 1, 1, 1), (-1, 1, 0, 1)]:
        gl.glTexCoord2f(u, v)
        gl.glVertex2f(x, y)
    gl.glEnd()
    gl.glUseProgram(0)
    assert ctx.error == "GL_NO_ERROR"


def texture(data):
    data = np.asarray(data, dtype="f4")
    result = ctx.texture((data.shape[1], data.shape[0]), data.shape[2],
                         data.tobytes(), dtype="f4")
    result.filter = (moderngl.NEAREST, moderngl.NEAREST)
    result.repeat_x = result.repeat_y = False
    return result


def read(target):
    result = np.frombuffer(target.read(), dtype="f4").reshape(
        target.height, target.width, target.components).copy()
    assert np.isfinite(result).all(), "shadow/provenance output contains non-finite values"
    return result


def proxy(center, half, shape=1, unit_id=73, axes=None):
    return dict(center=np.array(center, dtype=float), half=np.array(half, dtype=float),
                shape=shape, unit_id=unit_id,
                axes=np.eye(3) if axes is None else np.array(axes, dtype=float))


class MobileData:
    """Encode the public 256x32 record/grid contract without a CPU ray solver."""

    def __init__(self):
        self.tex = texture(np.zeros((32, 256, 4), "f4"))
        self.set([])

    def set(self, records, origin=(0, 0), span=256):
        assert len(records) <= 128
        self.origin, self.span, self.count = origin, span, len(records)
        image = np.zeros((32, 256, 4), "f4")
        flat = image.reshape(-1, 4)
        cells = [[] for _ in range(32 * 32)]
        heights = []
        for slot, record in enumerate(records):
            center, axes, half = record["center"], record["axes"], record["half"]
            flat[slot * 5] = [*center, record["shape"]]
            for axis in range(3):
                flat[slot * 5 + 1 + axis] = [*axes[axis], half[axis]]
            flat[slot * 5 + 4, 0] = record["unit_id"]
            scaled = axes * half[:, None]
            extent = (np.abs(scaled).sum(axis=0) if record["shape"] == 1
                      else np.sqrt((scaled * scaled).sum(axis=0)))
            heights.extend((center[1] - extent[1], center[1] + extent[1]))
            lower = np.floor((center[[0, 2]] - extent[[0, 2]] - origin) * 32 / span).astype(int)
            upper = np.floor((center[[0, 2]] + extent[[0, 2]] - origin) * 32 / span).astype(int)
            for z in range(max(0, lower[1]), min(31, upper[1]) + 1):
                for x in range(max(0, lower[0]), min(31, upper[0]) + 1):
                    cells[z * 32 + x].append(slot + 1)
        for cell, entries in enumerate(cells):
            assert len(entries) <= 16, "fixture exceeds the stated per-cell budget"
            start = 1280 + cell * 4
            flat[start:start + 4].reshape(-1)[:len(entries)] = entries
        self.tex.write(image.tobytes())
        self.height = (min(heights), max(heights)) if heights else (0, 0)

    def bind(self, program, unit=15, active=True):
        self.tex.use(unit)
        for name, value in dict(mobileShadowData=unit,
                                mobileShadowOrigin=self.origin,
                                mobileShadowSpan=self.span,
                                mobileShadowCount=self.count,
                                mobileShadowActive=int(active),
                                mobileShadowHeight=self.height).items():
            program[name].value = value


data = MobileData()
ray_program = ctx.program(vertex_shader=VERTEX, fragment_shader="""#version 150 compatibility
""" + helper + """
uniform vec3 testSource;
uniform vec3 testReceiver;
uniform float testOwner;
void main(){gl_FragColor=vec4(mobileVisibility(testSource,testReceiver,testOwner));}
""")
ray_out = ctx.texture((1, 1), 4, dtype="f4")
ray_target = ctx.framebuffer([ray_out])


def ray(start, end, expected, label, owner=0, active=True):
    ray_target.use()
    ray_target.clear()
    data.bind(ray_program, active=active)
    ray_program["testSource"].value = start
    ray_program["testReceiver"].value = end
    ray_program["testOwner"].value = owner
    quad(ray_program)
    actual = float(read(ray_out)[0, 0, 0])
    assert abs(actual - expected) < 1e-5, f"{label}: visibility {actual}, expected {expected}"


# The same XZ ray has different outcomes below, through, and above the body.
car = proxy((128, 15, 128), (12, 10, 20))
data.set([car])
ray((32, 15, 128), (224, 15, 128), 0, "ray through vehicle body")
ray((32, 1, 128), (224, 1, 128), 1, "ray below chassis")
ray((32, 40, 128), (224, 40, 128), 1, "ray above vehicle roof")
ray((128, 40, 128), (128, 0, 128), 0, "vertical ray with zero XZ displacement")
ray((128, 40, 128), (128, 40, 128), 1, "zero-length clear ray")

# Height must vary along a slanted ray, not be copied from either endpoint or
# replaced by a fixed 128-elmo occupancy-band height.
ray((32, 60, 128), (224, 1, 128), 1, "descending ray clears nearer car")
data.set([proxy((176, 15, 128), (12, 10, 20))])
ray((32, 60, 128), (224, 1, 128), 0, "same descending ray meets car nearer receiver")

# A stretched sphere narrows near the head; a bounding box would fail this.
pedestrian = proxy((128, 12, 128), (4, 12, 4), shape=2)
data.set([pedestrian])
ray((32, 12, 131), (224, 12, 131), 0, "pedestrian torso blocks")
ray((32, 23, 131), (224, 23, 131), 1, "rounded pedestrian head clears offset ray")
ray((-16000, 12, 131), (300, 12, 131), 0, "far lateral source hits thin ellipsoid")
ray((-16000, 23, 131), (300, 23, 131), 1, "far lateral source clears rounded head")
data.set([proxy((128, 12, 128), (4, 12, 4))])
ray((32, 23, 131), (224, 23, 131), 0, "equivalent box has square head profile")

# Heading changes the car silhouette; pitch must rotate the full three axes.
data.set([proxy((128, 12, 128), (6, 8, 20))])
ray((32, 12, 140), (224, 12, 140), 0, "long vehicle along Z")
data.set([proxy((128, 12, 128), (6, 8, 20),
                axes=((0, 0, -1), (0, 1, 0), (1, 0, 0)))])
ray((32, 12, 140), (224, 12, 140), 1, "same vehicle turned ninety degrees")
q = 2 ** -.5
data.set([proxy((128, 30, 128), (20, 4, 4),
                axes=((q, q, 0), (-q, q, 0), (0, 0, 1)))])
ray((96, 46, 128), (160, 46, 128), 0, "pitched vehicle raises one end")
ray((96, 54, 128), (160, 54, 128), 1, "ray above pitched extent")

# Exact owner IDs clear only their own containing proxy. Neighboring vehicles
# still cast, including with consecutive IDs above half-float integer precision.
host = proxy((40, 12, 128), (12, 10, 8), unit_id=32765)
data.set([host])
ray((40, 12, 128), (224, 12, 128), 1, "emitter clears own body", owner=32765)
ray((40, 12, 128), (224, 12, 128), 0, "unowned emitter is inside obstruction")
ray((20, 12, 128), (224, 12, 128), 0, "owner exemption requires source containment", owner=32765)
data.set([host, proxy((64, 12, 128), (8, 10, 8), unit_id=32766)])
ray((40, 12, 128), (224, 12, 128), 0, "adjacent car survives owner clearance", owner=32765)

# End-point containment avoids a receiver shadowing itself, without making a
# radius around that receiver transparent to a neighboring obstacle.
receiver_body = proxy((224, 12, 128), (12, 10, 8))
data.set([receiver_body])
ray((32, 12, 128), (224, 12, 128), 1, "receiver body exemption")
data.set([receiver_body, proxy((176, 12, 128), (8, 10, 8), unit_id=74)])
ray((32, 12, 128), (224, 12, 128), 0, "neighbor before receiver still shadows")
data.set([proxy((192, 12, 128), (8, 10, 8))])
ray((32, 12, 128), (201, 12, 128), 0, "receiver clearance creates no surrounding hole")

# A coarse/far source outside the local patch must still encounter blockers
# inside it. Rebuilding after domain movement must use world coordinates.
data.set([car])
ray((-40, 15, 128), (224, 15, 128), 0, "source outside grid, receiver inside")
ray((-40, 15, 128), (300, 15, 128), 0, "segment crossing the entire grid")
ray((-40, 15, 300), (300, 15, 300), 1, "segment outside grid stays clear")
data.set([car], origin=(64, 64))
ray((32, 15, 128), (224, 15, 128), 0, "camera domain shift preserves world blocker")
data.set([proxy((8192 + 128, 15, 4096 + 128), (12, 10, 20))],
         origin=(8192, 4096))
ray((8224, 15, 4224), (8416, 15, 4224), 0, "full-float distant world coordinates")
data.set([car])
ray((32, 15, 128), (224, 15, 128), 1, "disabled shadow provider", active=False)
data.set([])
ray((32, 15, 128), (224, 15, 128), 1, "removed proxy clears old shadow")
print("PASS: production mobile rays, chassis/roof clearance, slanted heights, ellipsoids, full box orientation, exact owner exclusion, receiver exclusion, domain clipping and clearing")


# Use the real mesh capture, including its geometry expansion, to create the
# emission height moment consumed by the actual MRT propagation/resolve pair.
N = 128
LUMA = np.array((.2126, .7152, .0722), dtype="f4")
emission_program = ctx.program(vertex_shader=source("emission_slice.vert"),
                               geometry_shader=source("emission_slice.geom"),
                               fragment_shader=source("emission_slice.frag"))
emission_output = texture(np.zeros((N, N, 4), "f4"))
emission_target = ctx.framebuffer([emission_output])
for name, value in dict(heightRange=(0, 128), atlasSize=(N, N), textured=0,
                        materialMasked=0, emissionStrength=1).items():
    emission_program[name].value = value


def capture(vertices, *, band=(0, 128), projected=False):
    emission_target.use()
    emission_target.clear()
    gl.glMatrixMode(0x1701)
    gl.glLoadIdentity()
    gl.glOrtho(-1, 1, -1, 1, -10000, 10000)
    gl.glMatrixMode(0x1700)
    gl.glLoadIdentity()
    gl.glColor4f(1, .3, .1, 1)
    emission_program["heightRange"].value = band
    emission_program["projectToBand"].value = int(projected)
    gl.glUseProgram(emission_program.glo)
    gl.glBegin(4)
    for x, y, z in vertices:
        # The production top-down model-view stores world Y in minus view Z.
        gl.glVertex3f(x / 64 - 1, z / 64 - 1, -y)
    gl.glEnd()
    gl.glUseProgram(0)
    assert ctx.error == "GL_NO_ERROR"
    return read(emission_output)


def source_patch(height):
    return capture([(92, height, 56), (108, height, 56), (108, height, 72),
                    (92, height, 56), (108, height, 72), (92, height, 72)])


def heights_of(emitted):
    energy = emitted[:, :, :3] @ LUMA
    valid = energy > 1e-6
    return emitted[:, :, 3][valid] * 2048 / energy[valid], valid


high_emission = source_patch(64)
low_emission = source_patch(14)
for emitted, height in ((high_emission, 64), (low_emission, 14)):
    actual, valid = heights_of(emitted)
    assert valid.sum() == 16 * 16
    assert np.allclose(actual, height, atol=1e-4), "mesh capture lost actual source height"
    assert np.allclose(emitted[valid, :3], (1, .3, .1), atol=1e-6), "height moment changed emission RGB"
sloped = capture([(92, 20, 56), (108, 52, 56), (108, 52, 72),
                  (92, 20, 56), (108, 52, 72), (92, 20, 72)])
sloped_heights, sloped_valid = heights_of(sloped)
expected_height = np.broadcast_to(20 + (np.arange(N) + .5 - 92) * 2, (N, N))
assert np.allclose(sloped_heights, expected_height[sloped_valid], atol=1e-4), "sloped face used one band/triangle height"
thin = capture([(32, 12, 64), (96, 12, 64), (96, 60, 64)], band=(20, 40))
thin_heights, thin_valid = heights_of(thin)
assert thin_valid.any() and np.all((thin_heights >= 20) & (thin_heights <= 40)), "thin-face height escaped clipped geometry"
elevated = capture([(92, 512, 56), (108, 512, 56), (108, 512, 72)], projected=True)
assert np.allclose(heights_of(elevated)[0], 512, atol=1e-4), "projected objective lost its actual elevated source height"

DEFINES = "#define BASE_PROBES 16\n#define CASCADE_COUNT 4\n#define MAX_TRACE_STEPS 256"
emission = texture(np.zeros((N, N, 4), "f4"))
occupancy = texture(np.zeros((N, N, 1), "f4"))
zero = texture(np.zeros((1, 1, 4), "f4"))


class Cascades:
    def __init__(self, height_aware):
        self.height_aware = height_aware
        mode = "#define HEIGHT_AWARE 1\n" if height_aware else ""
        self.propagate = ctx.program(vertex_shader=VERTEX,
                                     fragment_shader=source("propagate.frag", mode + DEFINES))
        self.resolve = ctx.program(vertex_shader=VERTEX,
                                   fragment_shader=source("resolve.frag", mode))
        self.colors = [texture(np.zeros((32, 32, 4), "f4")) for _ in range(4)]
        self.sources = [texture(np.zeros((32, 32, 4), "f4")) for _ in range(4)]
        self.targets = [ctx.framebuffer([self.colors[i], self.sources[i]] if height_aware
                                       else [self.colors[i]]) for i in range(4)]
        self.output = texture(np.zeros((N, N, 4), "f4"))
        self.source_output = texture(np.zeros((N, N, 4), "f4"))
        self.target = ctx.framebuffer([self.output, self.source_output] if height_aware
                                      else [self.output])
        for name, value in dict(emissionTex=0, occupancyTex=1, parentTex=2,
                                coarseEmissionTex=3, coarseOccupancyTex=4,
                                mapSize=(N, N), baseInterval=2, localField=1,
                                worldSize=(16384, 8192)).items():
            self.propagate[name].value = value
        for name, value in dict(cascadeTex=0, occupancyTex=1, emissionTex=2,
                                intensity=1).items():
            self.resolve[name].value = value
        if height_aware:
            self.propagate["parentSourceTex"].value = 5
            self.resolve["cascadeSourceTex"].value = 3
            self.resolve["mapSize"].value = (N, N)

    def render(self, emitted, mask=None, origin=(0, 0)):
        emission.write(emitted.tobytes())
        occupancy.write((np.zeros((N, N, 1), "f4") if mask is None else mask).tobytes())
        self.propagate["domainOrigin"].value = origin
        emission.use(0)
        occupancy.use(1)
        zero.use(3)
        zero.use(4)
        for index in range(3, -1, -1):
            (self.colors[index + 1] if index < 3 else zero).use(2)
            if self.height_aware:
                (self.sources[index + 1] if index < 3 else zero).use(5)
            self.targets[index].use()
            self.targets[index].clear()
            self.propagate["cascadeIndex"].value = index
            self.propagate["hasParent"].value = int(index < 3)
            quad(self.propagate)
        self.colors[0].use(0)
        occupancy.use(1)
        emission.use(2)
        if self.height_aware:
            self.sources[0].use(3)
            self.resolve["domainOrigin"].value = origin
        self.target.use()
        self.target.clear()
        quad(self.resolve)
        return read(self.output), read(self.source_output) if self.height_aware else None


legacy = Cascades(False)
height_aware = Cascades(True)
baseline, _ = legacy.render(high_emission)
high_light, high_source = height_aware.render(high_emission)
assert np.allclose(high_light, baseline, atol=1e-7), "height-aware provenance altered legacy radiance or transmittance"
assert high_light[:, :56, :3].sum() > 1, "fixture has no propagated light beyond emitter"
for index, target in enumerate(height_aware.sources):
    actual = read(target)
    valid = actual[:, :, 3] > 0
    assert valid.any(), f"cascade {index} lost all provenance"
    assert np.allclose(actual[:, :, 1][valid], 64, atol=1e-4), f"cascade {index} lost elevated source height"
    assert np.all((actual[:, :, 0][valid] >= 92) & (actual[:, :, 0][valid] <= 108))
    assert np.all((actual[:, :, 2][valid] >= 56) & (actual[:, :, 2][valid] <= 72))
valid = high_source[:, :, 3] > 0
assert valid[:, :56].any(), "height provenance never left the emitter's own texels"
assert np.allclose(high_source[:, :, 1][valid], 64, atol=1e-4), "resolve flattened actual source height"
low_light, low_source = height_aware.render(low_emission)
assert np.allclose(low_light, high_light, atol=1e-7), "source height prematurely shadowed the cascade carrier"
assert np.allclose(low_source[:, :, 1][low_source[:, :, 3] > 0], 14, atol=1e-4)
shifted_light, shifted_source = height_aware.render(high_emission, origin=(8192, 4096))
assert np.allclose(shifted_light, high_light, atol=1e-7), "world-domain movement changed unchanged local light"
assert np.allclose(shifted_source[valid, :3] - high_source[valid, :3], (8192, 0, 4096), atol=.002), "source provenance failed to follow world domain"
wall = np.zeros((N, N, 1), "f4")
wall[:, 60:68] = 1
wall_light, wall_sources = height_aware.render(high_emission, wall)
assert wall_light[:, :56, :3].sum() < high_light[:, :56, :3].sum() * 1e-6, "static wall stopped blocking with height provenance"
assert wall_sources[:, :56, 3].max() == 0, "static wall left a visible source behind it"
cleared_light, cleared_sources = height_aware.render(np.zeros_like(high_emission))
assert cleared_light[:, :, :3].max() == 0 and cleared_sources.max() == 0, "removed emitter retained cascade light or source coordinates"
print("PASS: actual mesh-height moment, clipped/sloped/elevated emission, paired MRT cascades and resolve, unchanged RGB, full-world provenance, wall visibility and source removal")


# Finally execute the actual scene sink. The radiance fields below are the
# production MRT results above, and the receiver comes from actual depth
# reconstruction. A shadow at road height must leave a higher surface lit.
scene = ctx.program(vertex_shader=VERTEX, fragment_shader=source("scene.frag", inject=True))
sampler_names = ("radianceTex", "occupancyTex", "mapDepthTex", "modelDepthTex",
                 "mapNormalTex", "modelNormalTex", "mapDiffuseTex", "modelDiffuseTex",
                 "localRadianceTex", "localOccupancyTex", "headlightTex", "headlightLocalTex",
                 "windowTex", "windowGroundTex", "mobileSourceAtlas", "mobileShadowData")
active_samplers = [name for name in scene if getattr(scene[name], "gl_type", None) == 0x8B5E]
assert len(active_samplers) <= 16, f"scene exceeds sixteen fragment samplers: {active_samplers}"
assert set(active_samplers) == set(sampler_names), "production scene sampler contract changed"
for slot, name in enumerate(sampler_names):
    scene[name].value = slot
for name, value in dict(mapSize=(N, N), heightRange=(0, 128), clipZeroToOne=0,
                        deferred=1, strength=2, nightIntensity=1, headlightIntensity=1,
                        smoothing=0, localActive=1, localOrigin=(0, 0), localSpan=N,
                        headlightActive=0, headlightLocalActive=1,
                        headlightOrigin=(0, 0), headlightSpan=N,
                        mobileCascadeSourceActive=1, mobileDirectSourceActive=1,
                        windowActive=0, objectiveLightCount=0).items():
    scene[name].value = value
scene["inverseView"].write(np.eye(4, dtype="f4").T.tobytes())
road_depth = texture(np.full((1, 1, 1), .5, "f4"))
model_depth = texture(np.ones((1, 1, 1), "f4"))
normal = texture(np.array([[[.5, 1, .5]]], "f4"))
albedo = texture(np.ones((1, 1, 3), "f4"))
scene_field = texture(high_light)
direct_field = texture(np.full((N, N, 3), (.4, .1, .03), "f4"))
atlas = texture(np.zeros((512, 1024, 4), "f4"))
scene_output = texture(np.zeros((N, N, 4), "f4"))
scene_target = ctx.framebuffer([scene_output])


def set_source_atlas(cascade=None, direct=None):
    image = np.zeros((512, 1024, 4), "f4")
    if cascade is not None:
        image[:, :512] = np.repeat(np.repeat(cascade, 4, axis=0), 4, axis=1)
    if direct is not None:
        image[:, 512:] = direct
    atlas.write(image.tobytes())


def scene_render(receiver_height, active=True, clip=0):
    # Pixel centers reconstruct world X/Z exactly. Changing receiver height
    # preserves the same screen pixel and the same radiance texture lookup.
    projection = np.array([[64, 0, 0, 64],
                           [0, 0, 128, receiver_height - (64 if clip else 0)],
                           [0, 64, 0, 64], [0, 0, 0, 1]], "f4")
    scene["inverseProjection"].write(projection.T.tobytes())
    scene["clipZeroToOne"].value = clip
    inputs = (zero, occupancy, road_depth, model_depth, normal, normal, albedo,
              albedo, scene_field, occupancy, direct_field, direct_field, zero, zero, atlas)
    for unit, tex in enumerate(inputs):
        tex.use(unit)
    data.bind(scene, active=active)
    scene_target.use()
    scene_target.clear()
    quad(scene)
    return read(scene_output)


ROI = np.s_[62:66, 26:32, :3]
road_car = proxy((64, 12, 64), (8, 10, 20), unit_id=80)
data.set([road_car], span=N)
set_source_atlas(high_source)
high_open = scene_render(1, active=False)
high_clear = scene_render(1)
assert high_open[ROI].sum() > .01, "scene fixture has no light at its receiver"
assert np.allclose(high_clear[ROI], high_open[ROI], atol=1e-6), "descending light that clears the car roof was flattened into a ground shadow"
set_source_atlas(low_source)
low_blocked = scene_render(1)
assert low_blocked[ROI].sum() < high_open[ROI].sum() * 1e-5, "actual scene did not shadow light passing through vehicle body"
elevated_receiver = scene_render(50)
assert np.allclose(elevated_receiver[ROI], high_open[ROI], atol=1e-6), "road shadow removed light from the elevated receiver"
assert np.allclose(scene_render(50, clip=1), elevated_receiver, atol=1e-6), "zero-to-one depth convention changed mobile shadow height"
scene["mobileCascadeSourceActive"].value = 0
assert np.allclose(scene_render(1), high_open, atol=1e-6), "unavailable provenance did not preserve the existing scene path"
scene["mobileCascadeSourceActive"].value = 1
data.set([], span=N)
assert np.allclose(scene_render(1), high_open, atol=1e-6), "removed vehicle left stale scene shadows"

# Direct lamps use the atlas's other half and retain exact unitID+1 metadata.
# The lamp may be in its own car; a car beside it must still shadow the road.
scene["localActive"].value = 0
scene["headlightActive"].value = 1
host = proxy((100, 12, 64), (10, 10, 10), unit_id=32765)
set_source_atlas(direct=(100, 14, 64, 32766))
data.set([host], span=N)
direct_open = scene_render(1, active=False)
assert np.allclose(scene_render(1)[ROI], direct_open[ROI], atol=1e-6), "direct field lost owner clearance or decoded owner ID incorrectly"
set_source_atlas(direct=(100, 14, 64, .5))
assert scene_render(1)[ROI].sum() < direct_open[ROI].sum() * 1e-5, "unowned direct source incorrectly bypassed containing vehicle"
set_source_atlas(direct=(100, 14, 64, 32766))
data.set([host, road_car], span=N)
assert scene_render(1)[ROI].sum() < direct_open[ROI].sum() * 1e-5, "clearing lamp owner also cleared the neighboring car"
scene["mobileDirectSourceActive"].value = 0
assert np.allclose(scene_render(1), direct_open, atol=1e-6), "unavailable direct provenance left a stale shadow"
scene["mobileDirectSourceActive"].value = 1
scene["nightIntensity"].value = 0
assert scene_render(1)[:, :, :3].max() == 0, "mobile visibility bypassed existing scene day/night gain"
print("PASS: actual scene receiver-height shadows, elevated surfaces, both depth conventions, direct source-owner metadata, neighbor shadows, disabled/removed fallback; all sixteen samplers compile")
print("Renderer:", ctx.info["GL_RENDERER"])
