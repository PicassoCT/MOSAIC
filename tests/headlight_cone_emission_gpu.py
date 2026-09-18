"""MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/headlight_cone_emission_gpu.py
Requires numpy, moderngl and Mesa EGL. Render the production emission geometry
with the same world-to-atlas matrices as the radiance capture callback.
"""
from pathlib import Path
import ctypes
import moderngl
import numpy as np
root=Path(__file__).resolve().parents[1]/'luaui/widgets_mosaic/shaders/headlights'
c=moderngl.create_standalone_context(backend='egl',require=330)
p=c.program(vertex_shader=(root/'cone_emission.vert').read_text(),fragment_shader=(root/'cone_emission.frag').read_text())
gl=ctypes.CDLL('libGL.so.1')
for name,args in {'glUseProgram':[ctypes.c_uint],'glMatrixMode':[ctypes.c_uint],
 'glOrtho':[ctypes.c_double]*6,'glRotatef':[ctypes.c_float]*4,
 'glVertex3f':[ctypes.c_float]*3,'glBegin':[ctypes.c_uint]}.items():getattr(gl,name).argtypes=args
out=c.texture((256,256),4,dtype='f4');fbo=c.framebuffer([out]);fbo.use()
occ=c.texture((128,128),1,np.zeros((128,128),'f4').tobytes(),dtype='f4');occ.filter=(moderngl.NEAREST,moderngl.NEAREST);occ.use(0)
for key,value in dict(buildingOccupancy=0,mapSize=(512,512),lamp=(256,16,64),forward=(0,1),lightRange=245,strength=1,hasOccupancy=1).items():p[key].value=value

def render(domain=(0,512,0,512),origin=(256,64),direction=(0,1)):
 fbo.clear();gl.glMatrixMode(0x1701);gl.glLoadIdentity();gl.glOrtho(*domain,-100000,100000)
 gl.glMatrixMode(0x1700);gl.glLoadIdentity();gl.glRotatef(-90,1,0,0)
 p['lamp'].value=(origin[0],16,origin[1]);p['forward'].value=direction
 gl.glUseProgram(p.glo);gl.glBegin(7)
 x,z=origin;fx,fz=direction;reach=245;w=3+reach*.42
 for vx,vz in [(x-fz*3,z+fx*3),(x+fz*3,z-fx*3),(x+fx*reach+fz*w,z+fz*reach-fx*w),(x+fx*reach-fz*w,z+fz*reach+fx*w)]:gl.glVertex3f(vx,1,vz)
 gl.glEnd();gl.glUseProgram(0)
 assert c.error=='GL_NO_ERROR'
 return np.frombuffer(out.read(),dtype='f4').reshape(256,256,4)[...,:3].copy()
base=render();assert np.isfinite(base).all() and base.sum()>100
assert base[:32].max()==0 and base[156:].max()==0,'behind source or beyond range'
assert base[70,128,0]>base[70,155,0],'soft cone falloff'
wall=np.zeros((128,128),'f4');wall[37:42,:]=1;occ.write(wall.tobytes())
blocked=render();assert blocked[85:].max()==0,'emission appeared behind wall'
assert blocked[:65].sum()>.9*base[:65].sum(),'wall erased light in front'
p['hasOccupancy'].value=0;assert np.allclose(render(),base)
p['strength'].value=0;assert render().max()==0
p['strength'].value=1
zoom=render((128,384,0,256));assert zoom.sum()>base.sum(),'local capture did not include cone'
turned=render(origin=(64,256),direction=(1,0));assert turned[:, :32].max()==0 and turned[:,156:].max()==0
assert np.isclose(turned.sum(),base.sum(),rtol=.02),'rotated cone changed emission'
print('PASS: world and local atlas capture, direction, finite range, soft edges, pre-emission wall clipping, disabled source, missing atlas, rotation')
print('Emission RGB sum:',float(base.sum()),'renderer:',c.info['GL_RENDERER'])
