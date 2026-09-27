"""MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/fog_radiance_heights_gpu.py"""
from pathlib import Path
import ctypes
import numpy as np
import moderngl
root=Path(__file__).resolve().parents[1]/'luaui/widgets_mosaic/shaders/radiancecascade'
ctx=moderngl.create_standalone_context(backend='egl',require=330)
p=ctx.program(vertex_shader=(root/'fog_heights.vert').read_text(),fragment_shader=(root/'fog_heights.frag').read_text())
size=128
out=ctx.texture((size,size),4,dtype='f4');depth=ctx.depth_texture((size,size))
fbo=ctx.framebuffer([out],depth);fbo.use();ctx.enable(moderngl.DEPTH_TEST);ctx.depth_func='<'
gl=ctypes.CDLL('libGL.so.1')
for name,args in {'glUseProgram':[ctypes.c_uint],'glBegin':[ctypes.c_uint],
    'glTexCoord2f':[ctypes.c_float]*2,'glVertex2f':[ctypes.c_float]*2}.items():getattr(gl,name).argtypes=args

def source(x,y,bottom,top,fade=32,radius=40,reach=180):
    p['sourceXZ'].value=(x,y);p['sourceY'].value=(bottom,top);p['sourceShape'].value=(radius,reach,fade)
    gl.glUseProgram(p.glo);gl.glBegin(7)
    for a,b in [(-1,-1),(1,-1),(1,1),(-1,1)]:
        gl.glTexCoord2f((a+1)*256,(b+1)*256);gl.glVertex2f(a,b)
    gl.glEnd();gl.glUseProgram(0)

def image():
    assert ctx.error=='GL_NO_ERROR',ctx.error
    a=np.frombuffer(out.read(),dtype='f4').reshape(size,size,4).copy()
    assert np.isfinite(a).all()
    return a
fbo.clear(depth=1);source(160,256,5,25);source(350,256,300,420,fade=64)
a=image();occupied=a[...,3]>0
assert occupied.any() and (~occupied).any(),'unbounded horizontal field'
assert set(np.unique(a[...,0][occupied]))=={5,300},'averaged heights invented a source between floors'
assert np.all(a[...,1][a[...,0]==5]==25) and np.all(a[...,1][a[...,0]==300]==420)
assert tuple(a[64,40,:2])==(5,25) and tuple(a[64,87,:2])==(300,420),'nearest source lost'
assert a[64,0,2]<32,'vertical envelope does not taper at horizontal edge'
fbo.clear(depth=1);source(350,256,300,420,fade=64);b=image()
assert not np.any(b[...,0]==5),'removed source survived clear'
print('PASS height shader: finite fields, distinct elevated/ground envelopes, nearest source, rounded reach and removal')
