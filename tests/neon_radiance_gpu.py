"""Headless shader tests. Dependencies: numpy, moderngl; Mesa EGL compatibility.
Run from repo root: MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/neon_radiance_gpu.py
"""
import ctypes
from pathlib import Path
import numpy as np
import moderngl

ctx=moderngl.create_standalone_context(backend='egl',require=330)
print('OpenGL:', ctx.info['GL_VENDOR'], '|', ctx.info['GL_RENDERER'], '|', ctx.info['GL_VERSION'], flush=True)
root=Path(__file__).resolve().parents[1]/'luaui/widgets_mosaic/shaders/radiancecascade'

def check_gl(stage):
 error=ctx.error
 if error!='GL_NO_ERROR':
  raise RuntimeError(f'{stage}: {error}')
gl=ctypes.CDLL('libGL.so.1')
gl.glGetIntegerv.argtypes=[ctypes.c_uint,ctypes.POINTER(ctypes.c_int)]
profile=ctypes.c_int()
gl.glGetIntegerv(0x9126,ctypes.byref(profile)) # GL_CONTEXT_PROFILE_MASK
check_gl('Context profile query')
if not profile.value & 0x00000002: # GL_CONTEXT_COMPATIBILITY_PROFILE_BIT
 raise RuntimeError('This test uses compatibility OpenGL draw calls, but EGL created a core context. '
                    'On Mesa run with MESA_GL_VERSION_OVERRIDE=3.3COMPAT. '
                    'That override does not configure non-Mesa drivers.')

vertex='#version 150 compatibility\nvoid main(){gl_Position=gl_Vertex;gl_TexCoord[0]=gl_MultiTexCoord0;}'
shader=(root/'propagate.frag').read_text().replace('#version 150 compatibility',
 '#version 150 compatibility\n#define BASE_PROBES 16\n#define CASCADE_COUNT 4\n#define MAX_TRACE_STEPS 256')
program=ctx.program(vertex_shader=vertex,fragment_shader=shader)
resolve=ctx.program(vertex_shader=vertex,fragment_shader=(root/'resolve.frag').read_text())
emission_program=ctx.program(vertex_shader=(root/'emission_slice.vert').read_text(),fragment_shader=(root/'emission_slice.frag').read_text())
# Also compile the production constants, not only the smaller numerical fixture.
ctx.program(vertex_shader=vertex,fragment_shader=shader.replace('BASE_PROBES 16','BASE_PROBES 128'))
for name,args in {'glUseProgram':[ctypes.c_uint],'glBegin':[ctypes.c_uint],
 'glTexCoord2f':[ctypes.c_float,ctypes.c_float],'glVertex2f':[ctypes.c_float,ctypes.c_float],
 'glVertex3f':[ctypes.c_float,ctypes.c_float,ctypes.c_float],
 'glMatrixMode':[ctypes.c_uint], 'glColor4f':[ctypes.c_float]*4}.items():
 getattr(gl,name).argtypes=args

def quad(p):
 check_gl('Before drawing program '+str(p.glo))
 gl.glUseProgram(p.glo);gl.glBegin(7)
 for x,y,u,v in [(-1,-1,0,0),(1,-1,1,0),(1,1,1,1),(-1,1,0,1)]:
  gl.glTexCoord2f(u,v);gl.glVertex2f(x,y)
 gl.glEnd();gl.glUseProgram(0)
 check_gl('Drawing program '+str(p.glo))

def texture(data):
 t=ctx.texture((data.shape[1],data.shape[0]),data.shape[2],data.astype('f4').tobytes(),dtype='f4')
 t.filter=(moderngl.NEAREST,moderngl.NEAREST);t.repeat_x=t.repeat_y=False
 return t

N=128
emitted=np.zeros((N,N,4),np.float32);emitted[56:72,92:108,:3]=1
empty=np.zeros((N,N,1),np.float32)
e=texture(emitted);occ=texture(empty)
cascades=[ctx.texture((32,32),4,dtype='f4') for _ in range(4)]
for t in cascades:t.filter=(moderngl.NEAREST,moderngl.NEAREST)
out=ctx.texture((N,N),4,dtype='f4');out.filter=(moderngl.NEAREST,moderngl.NEAREST)
program['emissionTex']=0;program['occupancyTex']=1;program['parentTex']=2
program['mapSize']=(128,128);program['baseInterval']=2
resolve['cascadeTex']=0;resolve['occupancyTex']=1;resolve['emissionTex']=2

def render(mask,intensity=1):
 occ.write(mask.astype('f4').tobytes());e.use(0);occ.use(1)
 for i in range(3,-1,-1):
  (cascades[i+1] if i<3 else e).use(2)
  ctx.framebuffer([cascades[i]]).use();ctx.viewport=(0,0,32,32)
  program['cascadeIndex']=i;program['hasParent']=int(i<3);quad(program)
 cascades[0].use(0);occ.use(1);e.use(2)
 ctx.framebuffer([out]).use();ctx.viewport=(0,0,N,N);resolve['intensity']=intensity;quad(resolve)
 return np.frombuffer(out.read(),dtype='f4').reshape(N,N,4).copy()

open_light=render(empty)
source_sum=float(emitted[:,:,:3].sum())
output_sum=float(open_light[:,:,:3].sum())
print('Source RGB sum:',source_sum,'| Resolved RGB sum:',output_sum, flush=True)
for i,t in enumerate(cascades):
 data=np.frombuffer(t.read(),dtype='f4').reshape(32,32,4)
 print(f'Cascade {i}: RGB sum={data[:,:,:3].sum()}, alpha range={data[:,:,3].min()}..{data[:,:,3].max()}', flush=True)
check_gl('Reading propagation results')
assert output_sum>source_sum, f'No propagated energy beyond emitter: source={source_sum}, resolved={output_sum}'
wall=empty.copy();wall[:,60:68]=1
blocked=render(wall)
assert blocked[:,:56,:3].sum()<open_light[:,:56,:3].sum()*0.000001, 'Wall failed to reduce propagation'
assert np.max(blocked[:,60:68,:3])==0, 'Occupied receivers lit'
assert np.isfinite(blocked).all() and np.min(blocked)>=0
night=render(wall,0.25)
assert np.allclose(night[:,:,:3],blocked[:,:,:3]*0.25,atol=1e-6), 'Intensity applied more than once'
zero=render(wall,0)
assert np.max(zero[:,:,:3])==0, 'Daylight should zero final neon result'
# Explicit near-blocker/far-radiance merge: alpha zero must stop the parent.
parent=texture(np.ones((32,32,4),np.float32))
e.write(np.zeros_like(emitted).tobytes());occ.write(np.ones_like(empty).tobytes())
e.use(0);occ.use(1);parent.use(2);ctx.framebuffer([cascades[0]]).use();ctx.viewport=(0,0,32,32)
program['cascadeIndex']=0;program['hasParent']=1;quad(program)
r=np.frombuffer(cascades[0].read(),dtype='f4').reshape(32,32,4)
assert np.max(r)==0, 'Opaque near interval admitted parent radiance'
# Full rebuild must clear removed sources, not preserve previous-frame energy.
assert np.max(render(empty)[:,:,:3])==0, 'Removed emitter left persistent light'
# Actual emission vertex+fragment: height clipping is half-open and uses -view Z.
ctx.framebuffer([out]).use();ctx.viewport=(0,0,N,N)
gl.glMatrixMode(0x1701);gl.glLoadIdentity();gl.glMatrixMode(0x1700);gl.glLoadIdentity()
gl.glColor4f(1,1,1,1);emission_program['heightRange']=(0,0.5)
for z,expected in [(-0.25,True),(0.25,False),(-0.75,False)]:
 ctx.clear(0,0,0,0);gl.glUseProgram(emission_program.glo);gl.glBegin(7)
 for x,y in [(-1,-1),(1,-1),(1,1),(-1,1)]:gl.glVertex3f(x,y,z)
 gl.glEnd();gl.glUseProgram(0)
 data=np.frombuffer(out.read(),dtype='f4')
 assert (data.max()>0)==expected, 'Emission height-band filtering failed'
assert ctx.error=='GL_NO_ERROR'
print('PASS: production shaders compile; emission spreads; wall blocks; parent visibility; night scaling; source removal; emission height bands')
print('Behind-wall radiance ratio:',float(blocked[:,:56,:3].sum()/open_light[:,:56,:3].sum()))
