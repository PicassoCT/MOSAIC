"""Shader tests (Linux): numpy, moderngl, glfw.
Desktop/NVIDIA: python3 tests/neon_radiance_gpu.py
Headless Mesa: MESA_GL_VERSION_OVERRIDE=3.3COMPAT python3 tests/neon_radiance_gpu.py --context egl
GLFW requests a real compatibility context in a hidden window; EGL mode is for Mesa CI.
"""
import atexit
import argparse
import ctypes
from pathlib import Path
import numpy as np
import moderngl

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--context',choices=('glfw','egl'),default='glfw')
args=parser.parse_args()
if args.context=='egl':
 ctx=moderngl.create_standalone_context(backend='egl',require=330)
else:
 try:
  import glfw
 except ImportError:
  raise SystemExit('Desktop tests need GLFW: python3 -m pip install glfw')
 if not glfw.init():
  raise RuntimeError('GLFW initialization failed. Run from your graphical desktop; '
                     'headless Mesa CI can use --context egl with MESA_GL_VERSION_OVERRIDE=3.3COMPAT.')
 atexit.register(glfw.terminate)
 glfw.window_hint(glfw.VISIBLE,glfw.FALSE)
 glfw.window_hint(glfw.CONTEXT_VERSION_MAJOR,3)
 glfw.window_hint(glfw.CONTEXT_VERSION_MINOR,3)
 glfw.window_hint(glfw.OPENGL_PROFILE,glfw.OPENGL_COMPAT_PROFILE)
 glfw.window_hint(glfw.OPENGL_FORWARD_COMPAT,glfw.FALSE)
 window=glfw.create_window(32,32,'Neon radiance shader test',None,None)
 if not window:
  raise RuntimeError('Could not create an OpenGL 3.3 compatibility context: '+str(glfw.get_error()))
 atexit.register(glfw.destroy_window,window)
 glfw.make_context_current(window)
 ctx=moderngl.create_context(require=330)
atexit.register(ctx.release)
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
 raise RuntimeError('This test requires compatibility OpenGL, but the driver created a core context. '
                    'Use the default GLFW desktop mode on NVIDIA; for --context egl on Mesa use MESA_GL_VERSION_OVERRIDE=3.3COMPAT. '
                    'That override does not configure non-Mesa drivers.')

vertex='#version 150 compatibility\nvoid main(){gl_Position=gl_Vertex;gl_TexCoord[0]=gl_MultiTexCoord0;}'
shader=(root/'propagate.frag').read_text().replace('#version 150 compatibility',
 '#version 150 compatibility\n#define BASE_PROBES 16\n#define CASCADE_COUNT 4\n#define MAX_TRACE_STEPS 256')
program=ctx.program(vertex_shader=vertex,fragment_shader=shader)
resolve=ctx.program(vertex_shader=vertex,fragment_shader=(root/'resolve.frag').read_text())
emission_program=ctx.program(vertex_shader=(root/'emission_slice.vert').read_text(),geometry_shader=(root/'emission_slice.geom').read_text(),fragment_shader=(root/'emission_slice.frag').read_text())
preview_program=ctx.program(vertex_shader=vertex,fragment_shader=(root/'preview.frag').read_text())
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
emission_program['atlasSize']=(N,N)
for z,expected in [(-0.25,True),(0.25,False),(-0.75,False)]:
 ctx.clear(0,0,0,0);gl.glUseProgram(emission_program.glo);gl.glBegin(4)
 for x,y in [(-1,-1),(1,-1),(1,1),(-1,-1),(1,1),(-1,1)]:gl.glVertex3f(x,y,z)
 gl.glEnd();gl.glUseProgram(0)
 data=np.frombuffer(out.read(),dtype='f4')
 assert (data.max()>0)==expected, 'Emission height-band filtering failed'
# A truly edge-on vertical face previously rasterized zero fragments.
def capture_triangle(vertices, band):
 emission_program['heightRange']=band
 ctx.clear(0,0,0,0);gl.glUseProgram(emission_program.glo);gl.glBegin(4)
 for v in vertices: gl.glVertex3f(*v)
 gl.glEnd();gl.glUseProgram(0);check_gl('Footprint capture')
 return np.frombuffer(out.read(),dtype='f4').reshape(N,N,4).copy()
vertical=[(-0.5,0,-0.1),(0.5,0,-0.1),(0.5,0,-0.9)]
footprint=capture_triangle(vertical,(0,0.5))
assert footprint[:,:,:3].sum()>0, 'Edge-on emitter vanished'
rows=np.where(footprint[:,:,0].max(axis=1)>0)[0]
assert len(rows)<=3, 'Minimum footprint grew beyond a narrow ribbon'
assert footprint[:,:,0].max()==1, 'Footprint changed source intensity'
e.write(footprint.tobytes())
vertical_light=render(empty)
assert vertical_light[:,:,:3][footprint[:,:,0]==0].sum()>0, 'Captured edge-on source failed to propagate'
assert capture_triangle(vertical,(1,2))[:,:,:3].max()==0, 'Footprint escaped its height band'
assert capture_triangle([(x,y,-0.5) for x,y,z in vertical],(0,0.5))[:,:,:3].max()==0, 'Upper band boundary included'
# A sloping thin triangle must only expand the segment inside the band.
clipped=capture_triangle([(-0.8,0,0),(0.8,0,-1),(0.8,0.001,-1)],(0.25,0.5))
cols=np.where(clipped[:,:,0].max(axis=0)>0)[0]
assert len(cols)>0 and cols.min()>=36 and cols.max()<=65, 'Expanded before height clipping'
# Preview exposure is monotonic and never writes into the propagation texture.
source_before=e.read();e.use(0);preview_program['previewTex']=0
values=[]
e.write(np.full_like(emitted,0.1).tobytes())
for exposure in (1,4):
 preview_program['exposure']=exposure;quad(preview_program)
 values.append(np.frombuffer(out.read(),dtype='f4').reshape(N,N,4)[:,:,:3].mean())
assert values[1]>values[0]>0
assert np.allclose(np.frombuffer(e.read(),dtype='f4'),0.1), 'Preview modified emission'
e.write(source_before)
assert ctx.error=='GL_NO_ERROR' 
print('PASS: production shaders compile; emission spreads; wall blocks; parent visibility; night scaling; source removal; emission height bands; edge-on footprints; preview exposure')
print('Behind-wall radiance ratio:',float(blocked[:,:56,:3].sum()/open_light[:,:56,:3].sum()))

# Textured emission: retain source hue for broad and edge-on geometry.
source_data=np.zeros((8,8,3),np.float32);source_data[:]=[0.1,0.6,0.9]
source_tex=texture(source_data);source_tex.use(0)
emission_program['sourceTex']=0;emission_program['textured']=1
colored=capture_triangle(vertical,(0,0.5))
active=colored[:,:,2]>0
assert active.any() and np.allclose(colored[:,:,:3][active],[0.1,0.6,0.9],atol=1e-6)
back_colored=capture_triangle(list(reversed(vertical)),(0,0.5))
assert np.allclose(back_colored,colored), 'Back-facing emitter lost colour'
e.write(colored.tobytes());colored_light=render(empty)
assert np.allclose(colored_light[:,:,0]*9,colored_light[:,:,2],atol=1e-5)
source_tex.write(np.zeros_like(source_data).tobytes());source_tex.use(0)
assert capture_triangle(vertical,(0,0.5))[:,:,:3].max()==0, 'Black source texels emitted light'
emission_program['textured']=0

# Actual scene shader: world reconstruction in both depth conventions,
# nearest opaque receiver, height bounds, colour, gain and day/night once.
scene_program=ctx.program(vertex_shader=vertex,fragment_shader=(root/'scene.frag').read_text())
scene_inputs=[texture(np.full((N,N,3),[0.2,0.05,0.1],np.float32)),texture(empty),
 texture(np.full((N,N,1),0.25,np.float32)),texture(np.ones((N,N,1),np.float32)),
 texture(np.full((N,N,3),[0.5,1,0.5],np.float32)),texture(np.full((N,N,3),[0.5,1,0.5],np.float32)),
 texture(np.full((N,N,3),0.5,np.float32)),texture(np.full((N,N,3),0.5,np.float32))]
for i,name in enumerate(('radianceTex','occupancyTex','mapDepthTex','modelDepthTex','mapNormalTex','modelNormalTex','mapDiffuseTex','modelDiffuseTex')):
 scene_program[name]=i
scene_program['mapSize']=(128,128);scene_program['heightRange']=(0,128)
scene_program['strength']=2;scene_program['nightIntensity']=0.25;scene_program['deferred']=1
scene_program['inverseView'].write(np.eye(4,dtype='f4').T.tobytes())
def scene_render(clip=0):
 projection=np.array([[64,0,0,64],[0,0,128 if clip else 64,0 if clip else 64],[0,64,0,64],[0,0,0,1]],dtype='f4')
 scene_program['inverseProjection'].write(projection.T.tobytes());scene_program['clipZeroToOne']=clip
 for i,t in enumerate(scene_inputs):t.use(i)
 ctx.framebuffer([out]).use();ctx.viewport=(0,0,N,N);ctx.clear(0,0,0,0);quad(scene_program)
 return np.frombuffer(out.read(),dtype='f4').reshape(N,N,4).copy()
scene_light=scene_render()
expected=(1-np.exp(-np.array([0.2,0.05,0.1])*2))*0.25*0.5
assert np.allclose(scene_light[:,:,:3],expected,atol=1e-6), 'Scene colour/gain/intensity mismatch'
assert np.allclose(scene_light,scene_render(1),atol=1e-6), 'Clip-depth convention shifted lighting'
scene_program['nightIntensity']=0
assert scene_render()[:,:,:3].max()==0, 'Scene lit in daytime'
scene_program['nightIntensity']=0.25;scene_program['heightRange']=(40,128)
assert scene_render()[:,:,:3].max()==0, 'Light painted outside height band'
scene_program['heightRange']=(16,64)
scene_inputs[3].write(np.full((N,N,1),0.1,np.float32).tobytes())
assert scene_render()[:,:,:3].max()==0, 'Lit terrain painted through closer model outside band'
scene_inputs[3].write(np.ones((N,N,1),np.float32).tobytes())
scene_inputs[2].write(np.ones((N,N,1),np.float32).tobytes())
assert scene_render()[:,:,:3].max()==0, 'Sky lit'
scene_inputs[2].write(np.full((N,N,1),0.25,np.float32).tobytes())
scene_inputs[1].write(np.ones_like(empty).tobytes())
assert scene_render()[:,:,:3].max()==0, 'Occupied receiver lit'
scene_inputs[1].write(empty.tobytes());scene_program['deferred']=0
assert np.allclose(scene_render()[:,:,:3],expected,atol=1e-6), 'Depth-copy fallback failed'
assert ctx.error=='GL_NO_ERROR'
print('PASS: textured coloured capture, RGB propagation, scene depth/height/sky/occlusion, day/night, both clip conventions and depth fallback')

# Local rays retain sources beyond the fine capture by reading coarse inputs.
program['coarseEmissionTex']=3;program['coarseOccupancyTex']=4
program['localField']=1;program['domainOrigin']=(32,32);program['worldSize']=(128,128)
program['mapSize']=(64,64)
outside=np.zeros_like(emitted);outside[56:72,104:120,:3]=1
coarse_e=texture(outside);coarse_o=texture(empty);coarse_e.use(3);coarse_o.use(4)
e.write(np.zeros_like(emitted).tobytes())
local_open=render(empty)
assert local_open[:,:,:3].sum()>0, 'Local solve lost an emitter outside its capture'
coarse_wall=empty.copy();coarse_wall[:,98:102]=1
coarse_o.write(coarse_wall.tobytes());coarse_o.use(4)
local_blocked=render(empty)
assert local_blocked[:,:,:3].sum()<local_open[:,:,:3].sum()*1e-6, 'Outside-patch wall leaked into fine field'
program['localField']=0;program['mapSize']=(128,128)

# Bilinear reconstruction must not average through a thin occupancy wall.
step_field=np.zeros((16,16,3),np.float32);step_field[:,8:]=1
scene_inputs[0]=texture(step_field)
scene_wall=empty.copy();scene_wall[:,63:65]=1
scene_inputs[1].write(scene_wall.tobytes());scene_program['smoothing']=1
smoothed=scene_render()
assert smoothed[:,:63,:3].max()==0, 'Smoothing crossed the wall'
assert smoothed[:,63:65,:3].max()==0, 'Smoothing lit an occupied receiver'
# With no wall, the step is interpolated smoothly between its sample centres.
scene_inputs[1].write(empty.tobytes());smoothed=scene_render()
assert 0<smoothed[64,63,0]<smoothed[64,72,0]
scene_program['smoothing']=0
nearest=scene_render()
assert nearest[64,63,0]==0

# Fine field replaces the centre and fades to the coarse field at its boundary.
scene_program['smoothing']=1
scene_inputs[0]=texture(np.full((N,N,3),[0.2,0.05,0.1],np.float32))
fine=texture(np.full((N,N,3),[0.6,0.2,0.05],np.float32));fine_occ=texture(empty)
scene_program['localRadianceTex']=8;scene_program['localOccupancyTex']=9
scene_program['localActive']=1;scene_program['localOrigin']=(32,32);scene_program['localSpan']=64
fine.use(8);fine_occ.use(9)
detail=scene_render()
fine_expected=(1-np.exp(-np.array([0.6,0.2,0.05])*2))*0.25*0.5
assert np.allclose(detail[64,64,:3],fine_expected,atol=1e-6)
assert np.allclose(detail[16,16,:3],expected,atol=1e-6)
# The first interior sample should still be predominantly coarse.
assert np.linalg.norm(detail[64,32,:3]-expected)<np.linalg.norm(fine_expected-expected)*0.02
scene_program['localActive']=0
assert np.allclose(scene_render()[:,:,:3],expected,atol=1e-6)
assert ctx.error=='GL_NO_ERROR'
print('PASS: camera-local external sources/walls, wall-aware smoothing, local centre/border and coarse fallback')
