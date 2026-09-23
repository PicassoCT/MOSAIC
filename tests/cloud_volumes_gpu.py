"""Render the production volume shader: MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/cloud_volumes_gpu.py
Optional --preview PATH saves a contact sheet for visual review. Requires moderngl, numpy, Pillow.
"""
import ctypes
from pathlib import Path
import sys
import moderngl
import numpy as np
ctx=moderngl.create_standalone_context(backend='egl',require=330)
root=Path(__file__).resolve().parents[1]/'luarules/gadgets/shaders'
p=ctx.program(vertex_shader=(root/'cloudVolume.vert').read_text(),fragment_shader=(root/'cloudVolume.frag').read_text())
gl=ctypes.CDLL('libGL.so.1')
gl.glUseProgram.argtypes=[ctypes.c_uint];gl.glBegin.argtypes=[ctypes.c_uint]
gl.glVertex2f.argtypes=[ctypes.c_float]*2
gl.glMatrixMode.argtypes=[ctypes.c_uint];gl.glLoadMatrixf.argtypes=[ctypes.POINTER(ctypes.c_float)]
w=h=256
out=ctx.texture((w,h),4,dtype='f4');fbo=ctx.framebuffer([out]);fbo.use()
depth=ctx.texture((w,h),1,np.ones((h,w),dtype='f4').tobytes(),dtype='f4');depth.use(0)
for n,v in dict(sceneDepth=0,viewportSize=(w,h),viewportOrigin=(0,0),zeroToOne=0.,effectTime=1.,seed=7.,density=4.,emission=2.5,
                opacity=1.,phase=0.,smokeColor=(.25,.24,.23),hotColor=(1.,.55,.12),ambient=(.5,.5,.5),shape=0,steps=24,volumeAxis=1,gradientSign=1.).items():p[n].value=v

def matrix(mode,m):
    gl.glMatrixMode(mode); a=(ctypes.c_float*16)(*np.asarray(m,dtype='f4').T.flatten());gl.glLoadMatrixf(a)

def camera(z=4,reflect=False,zero=False,ortho=False):
    n,f=.1,50.
    if ortho:
        proj=np.diag([.6,.6,-2/(f-n),1.]);proj[2,3]=-(f+n)/(f-n)
    else:
        proj=np.array([[2.,0,0,0],[0,2.,0,0],[0,0,-(f+n)/(f-n),-2*f*n/(f-n)],[0,0,-1.,0]])
    if zero:proj[2]=(proj[2]+proj[3])*.5
    matrix(0x1701,proj)
    model=np.eye(4);model[2,3]=-z
    if reflect:model[0,0]=-1
    matrix(0x1700,model);p['zeroToOne'].value=float(zero)

def render(**kwargs):
    for k,v in kwargs.items():p[k].value=v
    fbo.clear();gl.glUseProgram(p.glo);gl.glBegin(7)
    for x,y in [(-1,-1),(1,-1),(1,1),(-1,1)]:gl.glVertex2f(x,y)
    gl.glEnd();gl.glUseProgram(0)
    assert ctx.error=='GL_NO_ERROR',ctx.error
    a=np.frombuffer(out.read(),dtype='f4').reshape(h,w,4).copy()
    assert np.isfinite(a).all(),'non-finite raymarch'
    return a
camera();a=render();assert a[...,3].sum()>100,'invisible volume'
assert a[:20].max()==0 and a[-20:].max()==0,'proxy edge leak'
assert np.array_equal(a,render()),'paused animation changes'
b=render(effectTime=2.);assert np.abs(a-b).sum()>10,'frozen turbulence'
assert render(opacity=0.).max()==0,'transparent volume emits light'
render(opacity=1.)
smoke=render(emission=0.);hot=render(emission=3.)
assert np.allclose(smoke[...,3],hot[...,3]),'emission changes alpha'
assert hot[...,:3].sum()>smoke[...,:3].sum()*2,'no self illumination'
p['shape'].value=3
young=render(phase=.15);old=render(phase=.8)
assert young[...,:3].sum()>old[...,:3].sum()*2,'explosion never cools'
depth.write(np.full((h,w),.2,dtype='f4').tobytes());assert render().max()==0,'draws through foreground'
depth.write(np.ones((h,w),dtype='f4').tobytes())
camera(z=0);assert render()[...,3].sum()>0,'camera inside volume invisible'
camera(ortho=True);assert render()[...,3].sum()>0,'orthographic invisible'
camera(reflect=True);assert render()[...,3].sum()>0,'mirrored transform invisible'
camera();normal=render();camera(zero=True);zero=render()
assert np.allclose(normal,zero,atol=.002),'clip-space convention mismatch'
camera()
images=[]
for name,shape,emission,phase in [('Steam',0,0.,0.),('Exhaust',1,3.,0.),('Gas ring',2,.4,0.),('Impact ignition',3,3.5,.05),('Cooling cloud',3,3.5,.8)]:
    images.append((name,render(shape=shape,emission=emission,phase=phase)))
if '--preview' in sys.argv:
    from PIL import Image,ImageDraw
    sheet=Image.new('RGB',(w*len(images),h+30),(18,22,28));draw=ImageDraw.Draw(sheet)
    for i,(name,im) in enumerate(images):
        rgb=im[...,:3]+np.array([.025,.035,.05])*(1-im[...,3:4])
        # Reinhard exposure for HDR preview only; production uses the game's framebuffer.
        rgb=np.clip(rgb,0,1)**(1/2.2)
        sheet.paste(Image.fromarray((rgb[::-1]*255).astype('uint8')),(i*w,30));draw.text((i*w+10,9),name,fill='white')
    sheet.save(sys.argv[sys.argv.index('--preview')+1])
print('PASS: compile, deterministic turbulence, silhouettes, alpha/emission, cooling, foreground depth, camera inside, orthographic, mirrored transform, both clip-depth conventions')
print(ctx.info['GL_RENDERER'])
