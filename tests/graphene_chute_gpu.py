"""Render the live smoky graphene canopy with the production FlamePainter GLSL.

MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/graphene_chute_gpu.py
Requires moderngl, numpy and lupa. Optional --preview /absolute/path.png,
or --views-preview /absolute/path.png for front, oblique and overhead views.
The engine fixture uses air_parachut.dae's actual step bounds/imported basis;
this is a shader diagnostic, not an in-game screenshot.
"""
import argparse
import ctypes
from pathlib import Path

from lupa.lua51 import LuaRuntime
import moderngl
import numpy as np

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--preview', type=Path)
parser.add_argument('--views-preview', type=Path)
args = parser.parse_args()

repo = Path(__file__).resolve().parents[1]
lua = LuaRuntime(unpack_returned_tuples=True)
lua.globals().repo = str(repo)
lua.execute("""
VFS={Include=function(path)return dofile(repo..'/'..path)end}
Spring={
    GetUnitPieceInfo=function()return {min={-85.832451,-82.309372,68.273422},
        max={91.686882,96.216965,288.091553}}end,
    GetUnitPieceMatrix=function()return .0254,0,0,0, 0,0,-.0254,0, 0,.0254,0,0,
        .0240321084,34.4081509194,-.6740445244,1 end,
    GetUnitVectors=function()return {0,0,1},{0,1,0},{-1,0,0}end,
    GetUnitPosition=function()return 0,0,0 end,
    GetUnitPiecePosDir=function()return .04717199,36.1921519,-.28818393 end,
    ValidUnitID=function()return true end,GetUnitIsDead=function()return false end,
    GetUnitPieceMap=function()return {step=1}end,
}
""")
presets = lua.execute("return VFS.Include('scripts/lib_graphene_chute.lua')")
normalize = lua.execute("return VFS.Include('luarules/gadgets/include/smoke_ribbon_config.lua').Normalize")
layout = presets['Layout'](7, 1)


def array(table):
    return np.array([table[i] for i in range(1, len(table)+1)], dtype='f4')


# The renderer applies this same imported basis to local offsets/directions.
basis = np.array([[.0254, 0, 0], [0, 0, .0254], [0, -.0254, 0]], dtype='f4')
emitter = np.array([.04717199, 36.1921519, -.28818393], dtype='f4')
canopy_records, arc_records = [], []
for option, roots, entries in (
        ('RibbonOptions', layout['roots'], canopy_records),
        ('ArcOptions', layout['arcRoots'], arc_records)):
    for index in range(1, len(roots)+1):
        record = normalize(7, 1, presets[option](layout, index))
        direction = array(record['direction'])
        if record['directionSpace'] == 'piece':
            direction = basis @ direction
        entries.append(dict(record=record, origin=emitter+basis@array(record['rootOffset']),
                            direction=direction/np.linalg.norm(direction)))
records = canopy_records + arc_records

ctx = moderngl.create_standalone_context(backend='egl', require=330)
shader_dir = repo / 'luarules/gadgets/shaders'
vertex = (shader_dir / 'smokeRibbon.vert').read_text()
program = ctx.program(vertex_shader=vertex, fragment_shader=(shader_dir / 'smokeRibbon.frag').read_text())
gl = ctypes.CDLL('libGL.so.1')
gl.glUseProgram.argtypes = [ctypes.c_uint]
gl.glBegin.argtypes = [ctypes.c_uint]
gl.glVertex3f.argtypes = [ctypes.c_float]*3
gl.glEnd.argtypes = []
gl.glMatrixMode.argtypes = [ctypes.c_uint]
gl.glLoadMatrixf.argtypes = [ctypes.POINTER(ctypes.c_float)]
size = 512
out = ctx.texture((size, size), 4, dtype='f4')
fbo = ctx.framebuffer([out]); fbo.use()
ctx.enable(moderngl.BLEND)
ctx.blend_func = (moderngl.ONE, moderngl.ONE_MINUS_SRC_ALPHA)
# Preserve the old diagnostic's viewing angle while allowing the enlarged
# canopy and its electrical tips to fit. Report projected world-space coverage
# below so the image remains comparable to the former half-span of 65.
half_span = 115
projection = np.diag([1/half_span, 1/half_span, -2/500, 1]).astype('f4')
projection[2, 3] = -1
views = {
    'front': ((0, 82, 240), (0, 82, 0), (0, 1, 0)),
    'oblique': ((110, 145, 160), (0, 82, 0), (0, 1, 0)),
    'overhead': ((0, 280, 0), (0, 82, 0), (0, 0, -1)),
}


def set_view(name):
    global eye
    position, target, up_axis = views[name]
    eye = np.array(position, dtype='f4')
    target = np.array(target, dtype='f4')
    forward = (target-eye)/np.linalg.norm(target-eye)
    right = np.cross(forward, up_axis); right /= np.linalg.norm(right)
    up = np.cross(right, forward)
    view = np.eye(4, dtype='f4'); view[:3, :3] = [right, up, -forward]
    view[:3, 3] = -view[:3, :3] @ eye
    for mode, matrix in ((0x1701, projection), (0x1700, view)):
        gl.glMatrixMode(mode)
        gl.glLoadMatrixf((ctypes.c_float*16)(*matrix.T.ravel()))


set_view('oblique')


def parameters(entry, time=1, drift=(0, 0, 0)):
    r = entry['record']
    values = dict(origin=tuple(entry['origin']), direction=tuple(entry['direction']),
                  cameraPosition=tuple(eye), plumeLength=r['length'], plumeWidth=r['width'],
                  effectTime=time*r['speed'], curl=r['curl'], seed=r['seed'],
                  stiffness=r['stiffness'], gravity=r['gravity'],
                  hairMode={'hair': 1, 'canopy': 2, 'canopy_arc': 2}.get(r['mode'], 0),
                  electricMode={'electric': 1, 'canopy_arc': 2}.get(r['mode'], 0), landingMode=0,
                  strandCount=r['strands'],
                  strandOpacity=(np.sqrt(2/r['strands']) if r['mode']=='canopy'
                      else 1 if r['mode']=='hair' else 1.6/r['strands']),
                  ambient=(.8, .8, .8), directionalDrift=drift)
    for name in ('colorStart', 'colorEnd', 'emission', 'sourceGlow'):
        values[name] = tuple(array(r[name]))
    return values


def render(entries, time=1, drift=(0, 0, 0), overrides=None):
    fbo.clear(); gl.glUseProgram(program.glo)
    def draw_key(entry):
        midpoint = entry['origin']+(entry['direction']*entry['record']['length']+np.array(drift))*.5
        distance_squared = np.dot(eye-midpoint, eye-midpoint)
        # Match the production renderer's reverse traversal: equal-distance
        # material draws before its embedded glow, with nearer clouds still
        # able to attenuate both. This is not an all-glow-on-top composite.
        return distance_squared, 0 if entry['record']['mode']=='canopy_arc' else 1
    for entry in sorted(entries, key=draw_key, reverse=True):
        values = parameters(entry, time, drift)
        values.update(overrides or {})
        for name, value in values.items():
            program[name].value = value
        for strand in range(int(entry['record']['strands'])):
            gl.glBegin(5)
            for step in range(49):
                gl.glVertex3f(step/48, -1, strand); gl.glVertex3f(step/48, 1, strand)
            gl.glEnd()
    gl.glUseProgram(0)
    assert ctx.error == 'GL_NO_ERROR', ctx.error
    result = np.frombuffer(out.read(), dtype='f4').reshape(size, size, 4).copy()
    assert np.isfinite(result).all(), 'chute shader produced NaN/Inf'
    return result


black = render(canopy_records)
combined = render(records)
if args.preview:
    from PIL import Image
    background = np.array([.22, .30, .36])
    panels = []
    for rendered in (black, combined):
        rgb = rendered[..., :3] + background*(1-rendered[..., 3:4])
        panels.append((np.clip(rgb[::-1], 0, 1)**(1/2.2)*255).astype('uint8'))
    Image.fromarray(np.concatenate(panels, axis=1)).save(args.preview)

if args.views_preview:
    from PIL import Image, ImageDraw, ImageFont
    background = np.array([.22, .30, .36])
    panel_header, footer = 46, 36
    sheet = Image.new('RGB', (size*len(views), size+panel_header+footer), (31, 38, 45))
    draw = ImageDraw.Draw(sheet)
    try:
        title_font = ImageFont.truetype('DejaVuSans.ttf', 20)
        note_font = ImageFont.truetype('DejaVuSans.ttf', 15)
    except OSError:
        title_font = note_font = ImageFont.load_default()
    for index, name in enumerate(views):
        set_view(name)
        rendered = render(records)
        rgb = rendered[..., :3] + background*(1-rendered[..., 3:4])
        panel = Image.fromarray((np.clip(rgb[::-1], 0, 1)**(1/2.2)*255).astype('uint8'))
        sheet.paste(panel, (index*size, panel_header))
        draw.text((index*size+18, 13), name.title(), fill=(235, 240, 245), font=title_font)
    draw.text((18, size+panel_header+10),
              'Production shader diagnostic | common scale: 230 world units per panel | no game scene or postprocessing',
              fill=(201, 213, 223), font=note_font)
    sheet.save(args.views_preview)
    set_view('oblique')

alpha = black[..., 3]
visible = alpha > .02
assert alpha.sum() > 1000, 'smoky graphene veil has no readable scene attenuation'
assert (alpha > .25).sum() > 1000, 'dense graphene mist faded into an invisible effect'
# The material should have broad soft density, rather than individually opaque
# stripes. Most of the visible veil must still transmit its background.
soft_fraction = ((alpha > .02) & (alpha < .90)).sum()/visible.sum()
assert soft_fraction > .80, f'graphene reverted to opaque striped fabric: soft fraction {soft_fraction:.3f}'
# A separable binomial filter measures pixel-scale contrast without imposing a
# particular noise implementation. The former clearly separated stripes gave
# 0.230 at a closer camera; a dense, filtered fibre field must be smoother.
smoothed = alpha.copy()
for axis in (0, 1):
    smoothed = sum(weight*np.roll(smoothed, offset, axis)
                   for offset, weight in zip(range(-2, 3), (1, 4, 6, 4, 1)))/16
fine_contrast = np.abs(alpha-smoothed).sum()/alpha.sum()
assert fine_contrast < .20, f'canopy resolves as sharp individual bands: fine contrast {fine_contrast:.3f}'
assert combined[:2].max() == 0 and combined[-2:].max() == 0, 'diagnostic clips electrical or canopy tips'
assert combined[:, :2].max() == 0 and combined[:, -2:].max() == 0, 'diagnostic clips canopy edges'
energy = black[..., :3]
# The cloud carries only a faint charge tint. Strong emission is confined to
# sparse attached arcs; requiring the old broad bright tips would restore the
# saturated violet cap this change intentionally removes.
signal = energy[..., 2] > .001
assert signal.sum() > 100, 'graphene cloud lost its faint violet-blue charge tint'
assert energy.max() < .10, 'broad cloud emission returned as a bright violet cap'
assert energy[..., 2][signal].sum() > energy[..., 0][signal].sum()*2, 'tips lost electric blue'
assert energy[..., 0][signal].sum() > energy[..., 1][signal].sum(), 'tips lost violet halo'
assert ((alpha > .25) & (energy.max(axis=2) < .01)).sum() > 1000, 'tip glow coloured the black graphene body'
assert np.array_equal(black, render(canopy_records)), 'paused canopy changed'
night = render(canopy_records, overrides={'ambient': (.01, .01, .01)})
assert np.array_equal(alpha, night[..., 3]), 'night changed graphene coverage'
assert night[..., 2].sum() > energy[..., 2].sum()*.20, 'faint cloud charge disappears at night'
arc_day = render(arc_records)
arc_night = render(arc_records, overrides={'ambient': (.01, .01, .01)})
assert np.array_equal(arc_day, arc_night), 'attached electrical arcs depend on external lighting'
unlit = render(canopy_records, overrides={'colorEnd': (0, 0, 0, 1), 'emission': (0, 0)})
assert unlit[..., :3].max() == 0, 'unlit black graphene gained emission'
assert np.array_equal(alpha, unlit[..., 3]), 'tip lighting changed material coverage'
for entry in canopy_records:
    assert render([entry])[..., 3].sum() > 40, 'one canopy sector is invisible from the scene camera'
assert render(canopy_records, overrides={'colorStart': (0, 0, 0, 0),
    'colorEnd': (0, 0, 0, 0)}).max() == 0, 'zero-alpha fabric still occludes the scene'
calm_later = render(canopy_records, 3)
assert np.abs(black-calm_later).sum() > alpha.sum()*.05, 'canopy billowing is frozen in calm air'
wind = (8, 0, 2)
wind_a, wind_b = render(canopy_records, 1, wind), render(canopy_records, 3, wind)
assert np.abs(wind_a-wind_b).sum() > alpha.sum()*.05, 'wind cannot animate the fixed-length canopy'
assert (combined[..., 2] > .2).sum() > 100, 'retained electric arcs lost their visible cores'
black_pixels = (combined[..., 3] > .25) & (combined[..., :3].max(axis=2) < .01)
assert black_pixels.sum() > 1000, 'electric sources obscured the entire black canopy'

# Inspect actual GLSL paths, without reimplementing the hair centre curve.
flight = ctx.program(vertex_shader=vertex.split('void main() {')[0]+'''
in vec2 samplePoint;
out vec3 samplePosition;
void main() {
    vec3 helper=abs(direction.y)<0.9 ? vec3(0,1,0) : vec3(1,0,0);
    vec3 u=normalize(cross(direction,helper));
    samplePosition=centre(samplePoint.x,samplePoint.y,u,cross(direction,u));
}
''', varyings=['samplePosition'])
paths, curve_ratios, calm_motion = [], [], []
support_center = np.mean([entry['origin'] for entry in canopy_records], axis=0)
for entry in canopy_records:
    strands = int(entry['record']['strands'])
    samples = np.array([(t, strand) for strand in range(strands)
                        for t in np.linspace(0, 1, 129)], dtype='f4')
    vbo = ctx.buffer(samples.tobytes()); capture = ctx.buffer(reserve=len(samples)*12)
    vao = ctx.vertex_array(flight, [(vbo, '2f', 'samplePoint')])
    roots, calm_paths = [], []
    for time, drift in ((1, (0, 0, 0)), (3, (0, 0, 0)), (1, wind), (3, wind)):
        for name, value in parameters(entry, time, drift).items():
            if name in flight:
                flight[name].value = value
        vao.transform(capture, vertices=len(samples))
        path = np.frombuffer(capture.read(), dtype='f4').reshape(strands, 129, 3).copy()
        assert np.isfinite(path).all()
        assert path[..., 1].min() > 34.4, 'canopy droops below its upper support toward the passenger'
        assert (np.linalg.norm(path[:, 0]-entry['origin'], axis=1).max() < entry['record']['width']*.23), (
            'black ribbon root detached from its harness attachment')
        root_radius = np.linalg.norm(path[:, 0][:, [0, 2]]-support_center[[0, 2]], axis=1)
        tip_radius = np.linalg.norm(path[:, -1][:, [0, 2]]-support_center[[0, 2]], axis=1)
        assert root_radius.max() < layout['span']*.75, 'canopy roots escaped the physical support cluster'
        assert (tip_radius > root_radius+layout['radius']*.5).all(), (
            'canopy no longer spreads outward from the harness into a broad crown')
        assert (path[:, -1, 1]-path[:, 0, 1] > entry['record']['length']*.4).all(), (
            'canopy crown stopped rising above the passenger')
        arc_length = np.linalg.norm(np.diff(path, axis=1), axis=2).sum(axis=1)
        assert (arc_length.max() < entry['record']['length']*1.03), (
            'wind stretches the canopy material')
        roots.append(path[:, 0]); paths.extend(path)
        if drift == (0, 0, 0):
            calm_paths.append(path)
            curve_ratios.extend(arc_length/np.linalg.norm(path[:, -1]-path[:, 0], axis=1))
    assert all(np.array_equal(roots[0], root) for root in roots[1:]), 'billowing unpinned a canopy harness attachment'
    calm_motion.append(np.linalg.norm(calm_paths[1]-calm_paths[0], axis=2).mean()/entry['record']['length'])
    vao.release(); capture.release(); vbo.release()
# Capture all geometric strands, not just one representative centreline. The
# original canopy's length/chord ratio was only 1.0036 (almost straight).
assert np.mean(curve_ratios) > 1.015, f'canopy curves are still almost straight: ratio {np.mean(curve_ratios):.4f}'
assert np.mean(calm_motion) > .01, f'calm motion only changes opacity, not canopy shape: {np.mean(calm_motion):.4f}'


def capture_paths(entry, positions, time=1, drift=(0, 0, 0)):
    strands = int(entry['record']['strands'])
    samples = np.array([(t, strand) for strand in range(strands) for t in positions], dtype='f4')
    vbo = ctx.buffer(samples.tobytes()); capture = ctx.buffer(reserve=len(samples)*12)
    vao = ctx.vertex_array(flight, [(vbo, '2f', 'samplePoint')])
    for name, value in parameters(entry, time, drift).items():
        if name in flight:
            flight[name].value = value
    vao.transform(capture, vertices=len(samples))
    result = np.frombuffer(capture.read(), dtype='f4').reshape(strands, len(positions), 3).copy()
    vao.release(); capture.release(); vbo.release()
    assert np.isfinite(result).all(), 'electrical attachment path produced NaN/Inf'
    return result


# Sample the production centre() in both material modes, using each record's
# own normalized geometry and phase. Electricity must follow a real moving
# section of its associated veil, rather than a separately anchored plume.
arc_positions = np.linspace(0, .72, 65)
material_positions = .48+(.84-.48)*arc_positions/.72
for index, arc in enumerate(arc_records, start=1):
    bundle_index = int(layout['arcIndices'][index])-1
    bundle = canopy_records[bundle_index]
    for time, drift in ((1, (0, 0, 0)), (3, (0, 0, 0)), (1, wind), (3, wind)):
        electrical_path = capture_paths(arc, arc_positions, time, drift)
        material_path = capture_paths(bundle, material_positions, time, drift)
        assert np.allclose(electrical_path, material_path, rtol=1e-6, atol=1e-4), (
            'cyan-violet discharge detached from its moving graphene fibres')
        release = capture_paths(arc, (.71999, .72, .72001, 1), time, drift)
        assert (np.linalg.norm(release[:, 2]-release[:, 0], axis=1)
                < arc['record']['length']*.001).all(), 'electrical release jumps away from the material'
        assert (release[:, -1, 1] > release[:, 1, 1]).all(), 'free electrical tips do not rise upward'
        assert (np.linalg.norm(release[:, -1]-release[:, 1], axis=1)
                < arc['record']['length']*.5).all(), 'free electricity dominates the canopy scale'

y, x = np.nonzero(visible)
world_per_pixel = 2*half_span/size
print('Canopy metrics: alpha sum=%.1f, projected coverage=%.1f square world units, '
      'projected bounds=%.1f x %.1f world units, soft fraction=%.3f, fine contrast=%.3f, '
      'mean curve/chord=%.4f, calm shape motion=%.4f of material length' % (
          alpha.sum(), visible.sum()*world_per_pixel**2,
          (x.max()-x.min()+1)*world_per_pixel, (y.max()-y.min()+1)*world_per_pixel,
          soft_fraction, fine_contrast, np.mean(curve_ratios), np.mean(calm_motion)))
print('PASS: live Lua chute layout on production GLSL, smoky black canopy, soft filtered density, '
      'faint violet-blue tint and self-lit arcs, deterministic pause, calm-air billowing, wind, all-strand curvature and fixed length, '
      'pinned harness roots, upward spreading crown and electricity following the animated material')
print('Renderer:', ctx.info['GL_RENDERER'])
