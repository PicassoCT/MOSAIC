"""Render and sample the production electric shader with the live Lua preset.

MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/graphene_arcs_gpu.py
Requires moderngl, numpy and lupa (Lua 5.1). Optional --preview /absolute/path.png.
This is a shader diagnostic, not an in-game screenshot.
"""
import ctypes
from pathlib import Path
import sys

from lupa.lua51 import LuaRuntime
import moderngl
import numpy as np

repo = Path(__file__).resolve().parents[1]
shader_dir = repo / 'luarules/gadgets/shaders'
lua = LuaRuntime(unpack_returned_tuples=True)
options = lua.execute((repo / 'scripts/lib_graphene_arc.lua').read_text())['Options'](19)
ctx = moderngl.create_standalone_context(backend='egl', require=330)
vertex = (shader_dir / 'smokeRibbon.vert').read_text()
p = ctx.program(vertex_shader=vertex, fragment_shader=(shader_dir / 'smokeRibbon.frag').read_text())
gl = ctypes.CDLL('libGL.so.1')
gl.glUseProgram.argtypes = [ctypes.c_uint]
gl.glBegin.argtypes = [ctypes.c_uint]
gl.glVertex3f.argtypes = [ctypes.c_float] * 3
gl.glEnd.argtypes = []
w, h = 384, 512
out = ctx.texture((w,h),4,dtype='f4')
fbo = ctx.framebuffer([out]); fbo.use()
ctx.enable(moderngl.BLEND)
ctx.blend_func = (moderngl.ONE,moderngl.ONE_MINUS_SRC_ALPHA)
scale = 1.7/options['length']
parameters = dict(origin=(0,-0.88,0), direction=(0,1,0), cameraPosition=(0,0,5),
    effectTime=1.0*options['speed'], plumeLength=options['length']*scale,
    plumeWidth=options['width']*scale, curl=options['curl'], seed=options['seed'],
    electricMode=1, hairMode=0, landingMode=0,
    ambient=(0.8,0.8,0.8), strandOpacity=1.6/options['strands'],
    strandCount=options['strands'], directionalDrift=(0,0,0))
for name in ('colorStart','colorEnd','sourceGlow','emission'):
    parameters[name] = tuple(options[name][i] for i in range(1,len(options[name])+1))
for name,value in parameters.items():
    p[name].value = value

def render():
    fbo.clear(); gl.glUseProgram(p.glo)
    for strand in range(int(options['strands'])):
        gl.glBegin(5)
        for i in range(49):
            gl.glVertex3f(i/48,-1,strand)
            gl.glVertex3f(i/48,1,strand)
        gl.glEnd()
    gl.glUseProgram(0)
    assert ctx.error == 'GL_NO_ERROR', ctx.error
    result = np.frombuffer(out.read(),dtype='f4').reshape(h,w,4).copy()
    assert np.isfinite(result).all(), 'electric shader produced NaN/Inf'
    return result

day = render()
assert day[...,3].sum() > 20, 'live electrical preset is invisible'
assert np.array_equal(day,render()), 'electric arcs move while game time is paused'
p['ambient'].value = (0.015,0.015,0.015)
assert np.array_equal(day,render()), 'electrical arcs depend on external lighting'
bright = day[...,2] > 0.6
assert bright.sum() > 20, 'electric arcs have no readable hot core'
assert np.median(day[...,0][bright]/day[...,2][bright]) > 0.9, 'electric core is not near white'
halo = (day[...,2] > 0.003) & (day[...,2] < 0.05) & (day[...,3] > 0.003)
assert halo.sum() > 50, 'white core lost its coloured halo'
assert np.median(day[...,0][halo]/day[...,2][halo]) < 0.9, 'original cyan/blue halo washed out'
p['electricMode'].value = 0
smoke = render()
assert np.abs(day-smoke).sum() > 30, 'electric mode is still the generic smoke ribbon'
p['electricMode'].value = 1
p['effectTime'].value = 2.0*options['speed']
assert np.abs(day-render()).sum() > 10, 'electrical curling/pulses are frozen'
p['effectTime'].value = parameters['effectTime']
for name in ('colorStart','colorEnd'):
    p[name].value = parameters[name][:3]+(0,)
assert render().max() == 0, 'zero-alpha electric discharge still glows'
for name in ('colorStart','colorEnd'):
    p[name].value = parameters[name]
p['cameraPosition'].value = (0,5,0)
render()  # Collinear camera fallback must remain finite.

# Sample the actual GLSL centre() paths; no second CPU curve implementation.
flight = ctx.program(vertex_shader=vertex.split('void main() {')[0]+'''
in vec2 samplePoint;
out vec3 samplePosition;
void main() {
    vec3 helper = abs(direction.y)<0.9 ? vec3(0,1,0) : vec3(1,0,0);
    vec3 u = normalize(cross(direction,helper));
    samplePosition = centre(samplePoint.x,samplePoint.y,u,cross(direction,u));
}
''', varyings=['samplePosition'])
for name,value in parameters.items():
    if name in flight:
        flight[name].value = value
flight['origin'].value = (0,0,0)
samples = np.array([(t,s) for s in range(4) for t in np.linspace(0,1,129)],dtype='f4')
vbo = ctx.buffer(samples.tobytes())
capture = ctx.buffer(reserve=len(samples)*12)
vao = ctx.vertex_array(flight,[(vbo,'2f','samplePoint')])
vao.transform(capture,vertices=len(samples))
paths = np.frombuffer(capture.read(),dtype='f4').reshape(4,129,3)
assert np.isfinite(paths).all(), 'electric paths produced NaN/Inf'
assert np.allclose(paths[:,0,:],0), 'electric roots wandered off their attachments'
assert paths[:,:,1].min() >= 0 and paths[:,-1,1].min() > 1.5, 'electric arcs fail to rise upward'
tips = paths[:,-32,:][:,[0,2]]
for i in range(4):
    for j in range(i):
        assert np.linalg.norm(tips[i]-tips[j]) > .04, 'filaments collapse into one overlapping plume'
if '--preview' in sys.argv:
    from PIL import Image
    rgb = day[...,:3]+np.array([.025,.035,.05])*(1-day[...,3:4])
    Image.fromarray((np.clip(rgb[::-1],0,1)**(1/2.2)*255).astype('uint8')).save(sys.argv[sys.argv.index('--preview')+1])
print('PASS: live Lua electrical preset on production GLSL, white cores, cyan halo, self-illumination, pause, animation, alpha, camera fallback, pinned roots and separated upward filaments')
print('Renderer:',ctx.info['GL_RENDERER'])
