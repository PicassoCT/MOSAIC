"""MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/luxor_waterfalls_gpu.py
Headless production-shader checks (moderngl/numpy/Mesa EGL).
Optional --preview /absolute/path.png writes a surface swatch for visual QA.
"""
import ctypes
from pathlib import Path
import sys
import moderngl
import numpy as np

ctx = moderngl.create_standalone_context(backend='egl', require=330)
root = Path(__file__).resolve().parents[1] / 'luarules/gadgets/shaders'
p = ctx.program(vertex_shader=(root/'luxorWaterfall.vert').read_text(),
                fragment_shader=(root/'luxorWaterfall.frag').read_text())
gl = ctypes.CDLL('libGL.so.1')
for name, args in {'glUseProgram': [ctypes.c_uint], 'glBegin': [ctypes.c_uint],
                   'glMatrixMode': [ctypes.c_uint],
                   'glVertex3f': [ctypes.c_float]*3, 'glNormal3f': [ctypes.c_float]*3,
                   'glOrtho': [ctypes.c_double]*6}.items():
    getattr(gl, name).argtypes = args
w, h = 256, 512
out = ctx.texture((w,h), 4, dtype='f4')
depth = ctx.depth_texture((w,h))
fbo = ctx.framebuffer([out], depth); fbo.use()
ctx.enable(moderngl.DEPTH_TEST); ctx.disable(moderngl.BLEND)
ctx.depth_func = '<='
gl.glMatrixMode(0x1701); gl.glLoadIdentity(); gl.glOrtho(-18,18,-70,70,-10,10)
gl.glMatrixMode(0x1700); gl.glLoadIdentity()
p['viewInverse'].write(np.eye(4, dtype='f4').tobytes())
for name, value in dict(diffuseTex=0, materialTex=1, effectTime=0, seed=3,
                        cameraPosition=(0,0,100000), ambient=(.6,.6,.6)).items():
    p[name].value = value
source = ctx.texture((1,1),4,np.array([.12,.42,.5,0],dtype='f4').tobytes(),dtype='f4')
material = ctx.texture((1,1),4,np.array([.8,0,0,0],dtype='f4').tobytes(),dtype='f4')
source.use(0); material.use(1)

def quad(z=0):
    gl.glBegin(7)
    for x,y in [(-18,-70),(18,-70),(18,70),(-18,70)]: gl.glVertex3f(x,y,z)
    gl.glEnd()

def render(normal=(0,0,1)):
    fbo.clear(.9,.1,.5,.1)
    gl.glUseProgram(p.glo); gl.glNormal3f(*normal); quad(); gl.glUseProgram(0)
    assert ctx.error == 'GL_NO_ERROR', ctx.error
    result = np.frombuffer(out.read(),dtype='f4').reshape(h,w,4).copy()
    assert np.isfinite(result).all()
    assert np.all(result[...,3] == 1), 'water became transparent'
    return result

still = render()
assert np.array_equal(still,render()), 'paused water changes'
assert still[...,:3].std() > .05, 'no surface detail'
# A chosen time step moves every flowing feature down by exactly eight pixels.
p['effectTime'].value = 8 * (140/h) / (2.2/.18)
moving = render()
assert np.abs(moving-still).mean() > .003, 'water does not move'
assert np.abs(moving[:-8]-still[8:]).mean() < .0001, 'flow is not downward'
p['seed'].value = 23
assert np.abs(render()-moving).mean() > .005, 'buildings share identical patterns'
p['seed'].value = 3
p['ambient'].value = (0,0,0)
night = render()
assert night[...,:3].mean() > .15, 'illuminated water disappears at night'
source.write(np.array([.12,.42,.5,1],dtype='f4').tobytes())
material.write(np.array([.8,0,0,1],dtype='f4').tobytes())
assert np.array_equal(night,render()), 'atlas alpha changes waterfall opacity'
back = render((0,0,-1))
assert np.allclose(back,night), 'back face has different opacity or flow'
# An opaque red surface behind the waterfall must fail the depth test.
solid = ctx.program(vertex_shader='#version 150 compatibility\nvoid main(){gl_Position=gl_ModelViewProjectionMatrix*gl_Vertex;}',
                    fragment_shader='#version 150 compatibility\nvoid main(){gl_FragColor=vec4(1,0,0,1);}')
gl.glUseProgram(solid.glo); quad(-2); gl.glUseProgram(0)
assert np.array_equal(np.frombuffer(out.read(),dtype='f4').reshape(h,w,4),back), 'water does not occlude geometry behind it'
if '--preview' in sys.argv:
    from PIL import Image
    Image.fromarray((np.clip(still[::-1,:,:3],0,1)**(1/2.2)*255).astype('uint8')).save(sys.argv[sys.argv.index('--preview')+1])
print('PASS: production GLSL compile/render, opaque alpha, downward flow, paused determinism, varied buildings, night illumination, double-sided surface, depth occlusion')
print('GPU:', ctx.info['GL_RENDERER'])
