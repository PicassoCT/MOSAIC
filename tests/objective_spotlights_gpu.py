"""Actual scene GLSL: moving searchlight, palace facade, range and occlusion.
Run with Python, moderngl/numpy and Mesa EGL; no game process required.
"""
import os
os.environ.setdefault('MESA_GL_VERSION_OVERRIDE', '3.3COMPAT')
import ctypes
from pathlib import Path
import moderngl
import numpy as np

ctx=moderngl.create_standalone_context(backend='egl',require=330)
shader=ctx.program(vertex_shader='''#version 150 compatibility
void main(){gl_Position=gl_Vertex;gl_TexCoord[0]=gl_MultiTexCoord0;}''',
    fragment_shader=Path('luaui/widgets_mosaic/shaders/radiancecascade/scene.frag').read_text())
gl=ctypes.CDLL('libGL.so.1')
for name,args in {'glUseProgram':[ctypes.c_uint],'glBegin':[ctypes.c_uint],
                 'glVertex2f':[ctypes.c_float]*2,'glTexCoord2f':[ctypes.c_float]*2}.items():
    getattr(gl,name).argtypes=args
N=128
out=ctx.texture((N,N),4,dtype='f4');target=ctx.framebuffer([out])
def texture(data):
    a=np.array(data,dtype='f4')
    if a.ndim==1:a=a.reshape(1,1,-1)
    t=ctx.texture((a.shape[1],a.shape[0]),a.shape[2],a.tobytes(),dtype='f4')
    t.filter=(moderngl.NEAREST,moderngl.NEAREST);return t
black=texture([0,0,0]);occupancy=texture(np.zeros((128,128,1)))
ground=texture([.5]);model=texture([1]);normal=texture([.5,1,.5]);albedo=texture([.5,.5,.5])
for name,slot in {'radianceTex':0,'occupancyTex':1,'mapDepthTex':2,'modelDepthTex':3,
                 'mapNormalTex':4,'modelNormalTex':4,'mapDiffuseTex':5,'modelDiffuseTex':5}.items():shader[name]=slot
for name,value in {'mapSize':(512,512),'heightRange':(0,128),'strength':2,'nightIntensity':1,
                   'clipZeroToOne':0,'deferred':1,'objectiveLightCount':1}.items():shader[name]=value
shader['inverseView'].write(np.eye(4,dtype='f4').T.tobytes())
projection=np.array([[256,0,0,256],[0,0,100,0],[0,256,0,256],[0,0,0,1]],'f4')
shader['inverseProjection'].write(projection.T.tobytes())
def light(position,direction,reach=400,angle=12,color=(1,.91,.75),gain=5):
    direction=np.array(direction,dtype='f4');direction/=np.linalg.norm(direction)
    for key,value in {'objectivePosRange':[*position,reach],
                      'objectiveDirCos':[*direction,np.cos(np.deg2rad(angle))],
                      'objectiveColorGain':[*color,gain]}.items():
        data=np.zeros((24,4),'f4');data[0]=value;shader[key].write(data.tobytes())
def render():
    target.use();target.clear()
    for slot,t in enumerate([black,occupancy,ground,model,normal,albedo]):t.use(slot)
    gl.glUseProgram(shader.glo);gl.glBegin(7)
    for x,y,u,v in [(-1,-1,0,0),(1,-1,1,0),(1,1,1,1),(-1,1,0,1)]:
        gl.glTexCoord2f(u,v);gl.glVertex2f(x,y)
    gl.glEnd();gl.glUseProgram(0)
    assert ctx.error=='GL_NO_ERROR'
    a=np.frombuffer(out.read(),dtype='f4').reshape(N,N,4)[...,:3].copy()
    assert np.isfinite(a).all();return a
def centroid(a):
    w=a.sum(2);return (w*np.arange(N)[None,:]).sum()/w.sum()

light((192,80,96),(0,-.5,1));first=render()
assert first.sum()>10,'searchlight did not reach the road'
assert np.count_nonzero(first[:,:,0]>.02)<N*N*.12,'searchlight became an all-around pool'
light((192,80,96),(.65,-.5,1));turned=render()
assert centroid(turned)>centroid(first)+15,'searchlight did not sweep with fresh direction'
assert turned[first[:,:,0]>.1].sum()<first[first[:,:,0]>.1].sum()*.25,'previous pool remained lit'
light((192,80,96),(0,-.5,1),reach=70);assert render().max()==0,'light exceeded its range'
light((192,80,96),(0,-.5,1))
wall=np.zeros((128,128,1),'f4');wall[40:45]=1
occupancy.write(wall.tobytes());blocked=render()
assert blocked.sum()<first.sum()*.01,'searchlight passed through occupancy wall'
occupancy.write(np.zeros_like(wall).tobytes())

# Palace wall above the cascade receiver band must still receive the uplight.
ground.write(np.array([1],'f4').tobytes());model.write(np.array([.5],'f4').tobytes())
normal.write(np.array([.5,.5,0],'f4').tobytes())
projection=np.array([[128,0,0,256],[0,64,0,192],[0,0,100,256],[0,0,0,1]],'f4')
shader['inverseProjection'].write(projection.T.tobytes())
light((256,130,208),(0,1,1),reach=180,angle=48,color=(1,.76,.44),gain=3)
facade=render();assert facade.sum()>20,'palace wall above ground band stayed dark'
assert facade[:,:,0].sum()>facade[:,:,2].sum()*1.3,'palace uplight lost its warm color'
normal.write(np.array([.5,.5,1],'f4').tobytes());assert render().max()==0,'uplight painted the back of the wall'
normal.write(np.array([.5,.5,0],'f4').tobytes())
shader['objectiveLightCount']=0;assert render().max()==0,'removed source kept illuminating the palace'
shader['objectiveLightCount']=1;model.write(np.array([1],'f4').tobytes())
assert render().max()==0,'objective light painted the sky'
print('PASS: narrow moving searchlight, no stale pool, range, occlusion, warm elevated facade, backface, removal and sky')
print('Renderer:',ctx.info['GL_RENDERER'])
