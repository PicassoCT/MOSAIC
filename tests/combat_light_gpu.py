"""MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/combat_light_gpu.py
Render the production radial emitter in the same world/local atlas transforms
as the car-light captures. Requires moderngl, numpy and Mesa EGL.
"""
from pathlib import Path
import ctypes
import moderngl
import numpy as np

root = Path(__file__).resolve().parents[1] / 'luaui/widgets_mosaic/shaders/radiancecascade'
ctx = moderngl.create_standalone_context(backend='egl', require=330)
program = ctx.program(vertex_shader=(root/'combat_emission.vert').read_text(),
                      fragment_shader=(root/'combat_emission.frag').read_text())
gl = ctypes.CDLL('libGL.so.1')
for name, args in {'glUseProgram':[ctypes.c_uint], 'glMatrixMode':[ctypes.c_uint],
                   'glOrtho':[ctypes.c_double]*6, 'glRotatef':[ctypes.c_float]*4,
                   'glVertex3f':[ctypes.c_float]*3, 'glBegin':[ctypes.c_uint]}.items():
    getattr(gl, name).argtypes = args
out = ctx.texture((256,256), 4, dtype='f4')
fbo = ctx.framebuffer([out]); fbo.use()
occupancy = ctx.texture((128,128), 1, np.zeros((128,128),'f4').tobytes(), dtype='f4')
occupancy.filter = (moderngl.NEAREST, moderngl.NEAREST); occupancy.use(0)
for name,value in dict(buildingOccupancy=0,mapSize=(512,512),heightRange=(0,128),
                       lamp=(256,8,256),radius=120,color=(1,.3,.04),strength=1,hasOccupancy=1).items():
    program[name].value = value

def render(domain=(0,512,0,512), x=256, y=8, z=256):
    fbo.clear()
    gl.glMatrixMode(0x1701); gl.glLoadIdentity(); gl.glOrtho(*domain,-100000,100000)
    gl.glMatrixMode(0x1700); gl.glLoadIdentity(); gl.glRotatef(-90,1,0,0)
    program['lamp'].value=(x,y,z)
    gl.glUseProgram(program.glo); gl.glBegin(7)
    for vx,vz in ((x-120,z-120),(x+120,z-120),(x+120,z+120),(x-120,z+120)):
        gl.glVertex3f(vx,1,vz)
    gl.glEnd(); gl.glUseProgram(0)
    assert ctx.error == 'GL_NO_ERROR'
    return np.frombuffer(out.read(),dtype='f4').reshape(256,256,4)[...,:3].copy()

base=render()
assert np.isfinite(base).all() and base.sum()>100
assert base[128,128,0] > base[128,150,0] > base[128,180,0]
assert base[:60].max()==0 and base[195:].max()==0
assert np.isclose(base[...,1].sum()/base[...,0].sum(),.3,rtol=.001)
wall=np.zeros((128,128),'f4');wall[:,75:78]=1;occupancy.write(wall.tobytes())
blocked=render()
assert blocked[:,156:].max()==0,'combat light leaked through building'
assert np.allclose(blocked[:,:145],base[:,:145]),'wall erased light in front'
program['hasOccupancy'].value=0
assert np.allclose(render(),base),'missing occupancy fallback'
program['strength'].value=0;assert render().max()==0,'disabled weapon flash persisted'
program['strength'].value=.08
assert np.allclose(render(),base*.08,atol=1e-6),'cascade spill gain mismatch'
program['strength'].value=1
assert render(y=300).max()==0,'high projectile lit distant ground'
program['radius'].value=45
assert render(y=47).max()==0,'tracer above its reach lit the ground'
assert render(y=20).sum()>0,'low tracer failed to illuminate ground'
program['radius'].value=120
assert render((128,384,128,384)).sum()>base.sum()*3.5,'near atlas registration'

# Compile/render the production night-tracer shader, including the exact
# daylight-zero guarantee. Draw its UV profile in a clip-space quad.
tracer=ctx.program(vertex_shader=(root/'tracer.vert').read_text(),
                   fragment_shader=(root/'tracer.frag').read_text())
gl.glTexCoord2f.argtypes=[ctypes.c_float]*2
gl.glColor4f.argtypes=[ctypes.c_float]*4
def render_tracer(night):
    fbo.clear();tracer['nightIntensity'].value=night
    gl.glMatrixMode(0x1701);gl.glLoadIdentity()
    gl.glMatrixMode(0x1700);gl.glLoadIdentity()
    gl.glUseProgram(tracer.glo);gl.glColor4f(1,.5,.1,1);gl.glBegin(7)
    for x,y,u,v in [(-1,-1,0,0),(1,-1,1,0),(1,1,1,1),(-1,1,0,1)]:
        gl.glTexCoord2f(u,v);gl.glVertex3f(x,y,0)
    gl.glEnd();gl.glUseProgram(0)
    assert ctx.error=='GL_NO_ERROR'
    return np.frombuffer(out.read(),dtype='f4').reshape(256,256,4)[...,:3].copy()
assert render_tracer(0).max()==0,'daylight tracer glow'
night=render_tracer(1)
assert np.isfinite(night).all() and night.sum()>100
assert night[128,128,0]>night[80,128,0],'missing luminous tracer core'
assert np.allclose(render_tracer(.5),night*.5,atol=1e-6),'dusk fade mismatch'
print('PASS: combat shader compile, radial falloff, color, wall clipping, gain, height and near-field capture')
print('PASS: tracer shader compile, daylight zero, night core/halo and dusk fade; low/high tracer ground reach')
print('Renderer:',ctx.info['GL_RENDERER'])
