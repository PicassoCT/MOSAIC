"""MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/headlight_live_scene_gpu.py
Requires moderngl, numpy and Mesa EGL. Actual cone shader -> live texture ->
actual scene shader, with the slow radiance texture held constant throughout.
"""
import ctypes
from pathlib import Path
import numpy as np
import moderngl
root=Path(__file__).resolve().parents[1]/'luaui/widgets_mosaic/shaders'
c=moderngl.create_standalone_context(backend='egl',require=330)
cone=c.program(vertex_shader=(root/'headlights/cone_emission.vert').read_text(),fragment_shader=(root/'headlights/cone_emission.frag').read_text())
scene=c.program(vertex_shader='#version 150 compatibility\nvoid main(){gl_Position=gl_Vertex;gl_TexCoord[0]=gl_MultiTexCoord0;}',fragment_shader=(root/'radiancecascade/scene.frag').read_text())
gl=ctypes.CDLL('libGL.so.1')
for name,args in {'glUseProgram':[ctypes.c_uint],'glMatrixMode':[ctypes.c_uint],'glOrtho':[ctypes.c_double]*6,'glRotatef':[ctypes.c_float]*4,'glVertex3f':[ctypes.c_float]*3,'glVertex2f':[ctypes.c_float]*2,'glTexCoord2f':[ctypes.c_float]*2,'glBegin':[ctypes.c_uint]}.items():getattr(gl,name).argtypes=args
live=c.texture((256,256),4,dtype='f4');live.filter=(moderngl.LINEAR,moderngl.LINEAR);target=c.framebuffer([live])
out=c.texture((256,256),4,dtype='f4');screen=c.framebuffer([out])
def tex(data,n):return c.texture((1,1),n,np.array(data,'f4').tobytes(),dtype='f4')
occupancy=tex([0],1);indirect=tex([0,0,0],3);depth=tex([.5],1)
for k,v in dict(buildingOccupancy=0,mapSize=(512,512),lamp=(128,16,64),forward=(0,1),lightRange=180,strength=1,hasOccupancy=1).items():cone[k].value=v

def draw_cone(x,z=64,fx=0,fz=1):
 target.use();target.clear();occupancy.use(0)
 gl.glMatrixMode(0x1701);gl.glLoadIdentity();gl.glOrtho(0,512,0,512,-100000,100000)
 gl.glMatrixMode(0x1700);gl.glLoadIdentity();gl.glRotatef(-90,1,0,0)
 cone['lamp'].value=(x,16,z);cone['forward'].value=(fx,fz)
 gl.glUseProgram(cone.glo);gl.glBegin(7);r=180;w=3+r*.42
 for a,b in [(x-fz*3,z+fx*3),(x+fz*3,z-fx*3),(x+fx*r+fz*w,z+fz*r-fx*w),(x+fx*r-fz*w,z+fz*r+fx*w)]:gl.glVertex3f(a,1,b)
 gl.glEnd();gl.glUseProgram(0)

proj=np.array([[256,0,0,0],[0,0,100,-200],[0,256,0,0],[0,0,0,1]],'f4')
view=np.eye(4,dtype='f4');view[:3,3]=[256,200,256]
scene['inverseProjection'].write(proj.T.tobytes());scene['inverseView'].write(view.T.tobytes())
for k,v in dict(radianceTex=0,occupancyTex=1,mapDepthTex=2,modelDepthTex=2,mapNormalTex=2,modelNormalTex=2,mapDiffuseTex=2,modelDiffuseTex=2,localRadianceTex=0,localOccupancyTex=1,headlightTex=10,headlightLocalTex=11,mapSize=(512,512),heightRange=(0,128),clipZeroToOne=0,deferred=0,strength=2,nightIntensity=1,smoothing=0,localActive=0,localOrigin=(0,0),localSpan=512,headlightActive=1,headlightLocalActive=0,headlightOrigin=(0,0),headlightSpan=512).items():scene[k].value=v

def render():
 screen.use();screen.clear();indirect.use(0);occupancy.use(1);depth.use(2);live.use(10);live.use(11)
 gl.glUseProgram(scene.glo);gl.glBegin(7)
 for x,y,u,v in [(-1,-1,0,0),(1,-1,1,0),(1,1,1,1),(-1,1,0,1)]:gl.glTexCoord2f(u,v);gl.glVertex2f(x,y)
 gl.glEnd();gl.glUseProgram(0);assert c.error=='GL_NO_ERROR'
 a=np.frombuffer(out.read(),dtype='f4').reshape(256,256,4)[...,:3].copy()
 assert np.isfinite(a).all();return a

def centroid(a):
 weights=a.sum(axis=2);return (weights*np.arange(256)[None,:]).sum()/weights.sum(),(weights*np.arange(256)[:,None]).sum()/weights.sum()
draw_cone(128);first=render();assert first.sum()>10
draw_cone(256);second=render()
assert centroid(second)[0]-centroid(first)[0]>60,'translation waited for slow field'
draw_cone(256,64,1,0);turned=render()
assert centroid(turned)[0]>centroid(second)[0]+15 and centroid(turned)[1]<centroid(second)[1]-15,'rotation lagged'
scene['headlightLocalActive'].value=1
assert np.allclose(render(),turned,atol=.001),'local/global composition mismatch'
# Same direct energy in the slow field must not double scene brightness.
scene['localRadianceTex'].value=10;scene['radianceTex'].value=10
assert np.allclose(render(),turned,atol=.001),'direct counted twice'
scene['radianceTex'].value=0;scene['localRadianceTex'].value=0
# A fresh near field overrides a deliberately empty/stale coarse field.
scene['headlightLocalActive'].value=0
draw_cone(256,160);near_reference=render()
scene['headlightLocalActive'].value=1;scene['headlightTex'].value=0
near=render()
assert np.allclose(near[90:150,100:160],near_reference[90:150,100:160],atol=.001),'local update waited for coarse refresh'
scene['headlightTex'].value=10
scene['headlightActive'].value=0;assert render().max()==0,'stale light after disabling'
scene['headlightActive'].value=1;scene['nightIntensity'].value=0;assert render().max()==0,'daytime light'
scene['nightIntensity'].value=1
target.use();target.clear();assert render().max()==0,'old footprint survived clear'
print('PASS: actual cone-to-scene translation and rotation between cascade updates, local composition, no double brightness, off/daytime and source clearing')
print('Renderer:',c.info['GL_RENDERER'])
