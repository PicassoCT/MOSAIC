"""Headless: MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/vehicle_headlights_gpu.py
Requires numpy and moderngl; exercises the production GLSL in a compatibility context.
"""
import ctypes
from pathlib import Path
import moderngl
import numpy as np

ctx = moderngl.create_standalone_context(backend='egl', require=330)
root = Path(__file__).resolve().parents[1] / 'luaui/widgets_mosaic/shaders/headlights'
vertex = '#version 150 compatibility\nvoid main(){gl_Position=gl_Vertex;gl_TexCoord[0]=gl_MultiTexCoord0;gl_FrontColor=gl_Color;}'
program = ctx.program(vertex_shader=vertex, fragment_shader=(root/'spotlight.frag').read_text())
ctx.program(vertex_shader=vertex, fragment_shader=(root/'glow.frag').read_text())
gl = ctypes.CDLL('libGL.so.1')
gl.glUseProgram.argtypes = [ctypes.c_uint]
gl.glBegin.argtypes = [ctypes.c_uint]
gl.glVertex2f.argtypes = [ctypes.c_float, ctypes.c_float]
gl.glEnd.argtypes = []
w = h = 128
out = ctx.texture((w,h), 4, dtype='f4')
fbo = ctx.framebuffer([out]); fbo.use()
depth = ctx.texture((w,h), 1, np.full((h,w),.5,'f4').tobytes(), dtype='f4')
depth.filter = (moderngl.NEAREST, moderngl.NEAREST); depth.use(0)
occupancy = ctx.texture((128,128),1, np.zeros((128,128),'f4').tobytes(), dtype='f4')
occupancy.filter = (moderngl.NEAREST, moderngl.NEAREST); occupancy.use(1)
projection = np.array([[100,0,0,0],[0,0,100,-200],[0,160,0,0],[0,0,0,1]],'f4')
view = np.eye(4,dtype='f4'); view[:3,3] = [256,200,184]
program['inverseProjection'].write(projection.T.tobytes())
program['inverseView'].write(view.T.tobytes())
for name,value in dict(depthTex=0,occupancyTex=1,viewport=(w,h),viewportOrigin=(0,0),mapSize=(512,512),
    lampLeft=(244,16,64),lampRight=(268,16,64),forward=(0,0,1),right=(1,0,0),up=(0,1,0),
    lightRange=245,intensity=1,wetness=0,clipZeroToOne=0,occlusionActive=0,occlusionHeight=(0,128)).items():
    program[name].value = value

def render():
    fbo.clear(); gl.glUseProgram(program.glo)
    gl.glBegin(7)
    for x,y in [(-1,-1),(1,-1),(1,1),(-1,1)]: gl.glVertex2f(x,y)
    gl.glEnd(); gl.glUseProgram(0)
    assert ctx.error == 'GL_NO_ERROR'
    return np.frombuffer(out.read(),dtype='f4').reshape(h,w,4)[...,:3].copy()

z = 24+(np.arange(h)+.5)*320/h
lit = render()
assert np.isfinite(lit).all() and lit.sum()>20, lit.sum()
assert lit[z<64].max()==0, 'light behind the vehicle'
assert lit[z>310].max()==0, 'light beyond range'
program['intensity'].value = 0
assert render().max()==0, 'daytime must be dark'
program['intensity'].value = .5
assert np.allclose(render(),lit*.5,atol=1e-6), 'intensity applied more than once'
program['intensity'].value = 1
wall=np.zeros((128,128),'f4'); wall[37:42,:]=1
occupancy.write(wall.tobytes()); program['occlusionActive'].value=1
blocked=render()
assert blocked[z>180].sum()<lit[z>180].sum()*.01, 'wall failed to block'
assert blocked[z<130].sum()>lit[z<130].sum()*.9, 'wall shadow in front of wall'
program['occlusionActive'].value=0
assert np.allclose(render(),lit), 'missing atlas fallback'
program['wetness'].value=1
wet=render()
assert np.isfinite(wet).all() and wet.sum()>=lit.sum(), 'wet surface highlight'
program['glitterTime'].value=0.7
assert abs(render()-wet).max()>1e-7, 'wet highlights did not shimmer'
program['wetness'].value=0
# Equivalent zero-to-one depth convention.
projection[1,2]=200; projection[1,3]=-300
program['inverseProjection'].write(projection.T.tobytes()); program['clipZeroToOne'].value=1
assert np.allclose(render(),lit,atol=1e-5), 'clip depth convention mismatch'
depth.write(np.ones((h,w),'f4').tobytes())
assert render().max()==0, 'sky must not receive light'
print('PASS: shader compilation, paired road light, direction, range, dawn fade, building shadow, atlas fallback, wetness, both depth conventions, sky rejection')
print('Renderer:',ctx.info['GL_RENDERER'],'unoccluded RGB sum:',float(lit.sum()))

