"""MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/rain_light_glitter_gpu.py
Requires moderngl, numpy and Mesa EGL. Compiles production shaders, then renders
production rain-glitter functions against synthetic radiance and occupancy.
"""
import ctypes
from pathlib import Path
import moderngl
import numpy as np
root=Path(__file__).resolve().parents[1]/'luaui/widgets_mosaic/shaders'
ctx=moderngl.create_standalone_context(backend='egl',require=330)
helper=(root/'rainLightGlitter.glsl').read_text()
ctx.program(vertex_shader=(root/'rainShader.vert').read_text(),fragment_shader=
    (root/'rainShader.frag').read_text().replace('// RAIN_LIGHT_GLITTER',helper)
    .replace('// WORLD_RAIN',(root/'worldRain.glsl').read_text()))
vertex='#version 150 compatibility\nvoid main(){gl_Position=gl_Vertex;}'
ctx.program(vertex_shader=vertex,fragment_shader=(root/'headlights/spotlight.frag').read_text())
program=ctx.program(vertex_shader=vertex,fragment_shader='''#version 150 compatibility
uniform vec3 eyePos;
uniform vec3 surface;
uniform float mask;
'''+helper+'''
void main(){gl_FragColor=vec4(rainDropGlitter(surface,mask,16.0),1);}
''')
gl=ctypes.CDLL('libGL.so.1')
gl.glUseProgram.argtypes=[ctypes.c_uint]; gl.glBegin.argtypes=[ctypes.c_uint]
gl.glVertex2f.argtypes=[ctypes.c_float,ctypes.c_float]
out=ctx.texture((8,8),4,dtype='f4'); fbo=ctx.framebuffer([out]); fbo.use()
def texture(data,components,unit):
    a=np.array(data,'f4'); t=ctx.texture((1,1),components,a.tobytes(),dtype='f4')
    t.use(unit); return t
red=texture([1,0,0],3,0); empty=texture([0],1,1)
green=texture([0,1,0],3,2); local_empty=texture([0],1,3)
for key,value in dict(rainRadianceTex=0,rainOccupancyTex=1,rainLocalRadianceTex=2,
    rainLocalOccupancyTex=3,rainLightActive=1,rainLocalActive=0,rainMapSize=(512,512),
    rainLightHeight=(0,128),rainLocalOrigin=(0,0),rainLocalSpan=512,rainLightIntensity=1,
    rainLightStrength=2,glitterTime=0,eyePos=(256,100,256),surface=(256,0,256),mask=1).items():
    program[key].value=value

def render():
    fbo.clear(); gl.glUseProgram(program.glo); gl.glBegin(7)
    for x,y in [(-1,-1),(1,-1),(1,1),(-1,1)]: gl.glVertex2f(x,y)
    gl.glEnd(); gl.glUseProgram(0)
    assert ctx.error=='GL_NO_ERROR'
    rgb=np.frombuffer(out.read(),dtype='f4').reshape(8,8,4)[0,0,:3]
    assert np.isfinite(rgb).all()
    return rgb.copy()
base=render(); assert base[0]>0 and base[1]==0 and base[2]==0,'radiance colour'
animated=[]
for t in [0.2,0.4,0.6,0.8,1.0]:
    program['glitterTime'].value=t; animated.append(render()[0])
assert max(animated)-min(animated)>.01,'glitter animation'
program['glitterTime'].value=0
for key in ['rainLightActive','mask','rainLightIntensity']:
    program[key].value=0; assert render().max()==0,key
    program[key].value=1
program['rainLightIntensity'].value=.5
assert np.allclose(render(),base*.5),'night strength applied twice'
program['rainLightIntensity'].value=1
empty.write(np.ones(1,'f4').tobytes()); assert render().max()==0,'building occupancy'
empty.write(np.zeros(1,'f4').tobytes())
program['surface'].value=(256,200,256); assert render().max()==0,'wrong height band'
program['surface'].value=(-100,0,256); assert render().max()==0,'outside map'
program['surface'].value=(256,0,256); program['rainLocalActive'].value=1
local=render(); assert local[1]>0 and local[0]==0,'local detail field'
local_empty.write(np.ones(1,'f4').tobytes()); assert render().max()==0,'local occupancy'
program['surface'].value=(20,0,20)
assert render()[0]>0,'local edge coarse fallback'
print('PASS: production shader compilation; coloured glints, animation, missing field, drop mask, night scaling, occupancy, height, map bounds, local detail and fallback')
print('GPU:',ctx.info['GL_RENDERER'])
