"""MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/smoke_ribbons_gpu.py
Compiles and renders the actual production shaders in a headless GL context.
Requires moderngl and numpy. Optional --preview /absolute/path.png.
"""
import ctypes
from pathlib import Path
import sys
import moderngl
import numpy as np

ctx = moderngl.create_standalone_context(backend='egl', require=330)
root = Path(__file__).resolve().parents[1] / 'luarules/gadgets/shaders'
p = ctx.program(vertex_shader=(root/'smokeRibbon.vert').read_text(),
                fragment_shader=(root/'smokeRibbon.frag').read_text())
gl = ctypes.CDLL('libGL.so.1')
gl.glUseProgram.argtypes = [ctypes.c_uint]
gl.glBegin.argtypes = [ctypes.c_uint]
gl.glVertex3f.argtypes = [ctypes.c_float]*3
gl.glEnd.argtypes = []
w,h=256,512
out=ctx.texture((w,h),4,dtype='f4'); fbo=ctx.framebuffer([out]); fbo.use()
ctx.enable(moderngl.BLEND)
ctx.blend_func=(moderngl.ONE,moderngl.ONE_MINUS_SRC_ALPHA)
for name,value in dict(origin=(0,-0.9,0),direction=(0,1,0),cameraPosition=(0,0,5),
    effectTime=1.0,plumeLength=1.7,plumeWidth=0.35,curl=0.8,seed=3.0,
    colorStart=(0.7,0.7,0.7,0.8),colorEnd=(0.7,0.7,0.7,0),
    emission=(0,0),ambient=(0.3,0.3,0.3),strandOpacity=1.6/3,strandCount=3,directionalDrift=(0,0,0)).items():
    p[name].value=value

def render():
    fbo.clear(); gl.glUseProgram(p.glo)
    for strand in range(round(p['strandCount'].value)):
        gl.glBegin(5)
        for i in range(49):
            gl.glVertex3f(i/48,-1,strand); gl.glVertex3f(i/48,1,strand)
        gl.glEnd()
    gl.glUseProgram(0)
    assert ctx.error=='GL_NO_ERROR',ctx.error
    result=np.frombuffer(out.read(),dtype='f4').reshape(h,w,4).copy()
    assert np.isfinite(result).all()
    return result

a=render()
assert a[...,3].sum()>20, 'smoke is invisible'
assert a[:20].max()==0 and a[-5:].max()<0.001, 'ribbon escapes endpoints'
assert a[:,:,:3].max()<=a[:,:,3].max(), 'unpremultiplied colour'
p['effectTime'].value=2.0
b=render(); assert np.abs(a-b).sum()>5, 'motion is frozen'
assert np.array_equal(b,render()), 'same time is not deterministic'
p['emission'].value=(1,1)
lit=render()
assert np.allclose(lit[...,:3],b[...,:3]/0.3,atol=1e-5), 'self-illumination is incorrect'
assert np.allclose(lit[...,3],b[...,3]), 'emission changed density'
def centroid_x(im):
    a=im[...,3]; return (a*np.arange(w)[None,:]).sum()/a.sum()
p['directionalDrift'].value=(0.5,0,0)
right=render()
p['directionalDrift'].value=(-0.5,0,0)
left=render()
assert centroid_x(right)>centroid_x(lit)>centroid_x(left), 'drift does not bend in requested direction'
p['directionalDrift'].value=(0,0,0)
assert np.allclose(render(),lit), 'disabling drift does not restore the plume'
p['colorStart'].value=(1,0,0,0.8);p['colorEnd'].value=(0,0,1,0.5)
gradient=render()
assert gradient[30:120,:,0].sum()>gradient[30:120,:,2].sum(), 'source colour reversed'
assert gradient[330:440,:,2].sum()>gradient[330:440,:,0].sum(), 'tail colour reversed'
p['colorStart'].value=(0.7,0.7,0.7,0);p['colorEnd'].value=(0.7,0.7,0.7,0)
assert render().max()==0, 'zero alpha still glows'
p['colorStart'].value=(0.7,0.7,0.7,0.8);p['colorEnd'].value=(0.7,0.7,0.7,0)
# Camera collinear with plume and very small scale must not generate NaNs.
p['cameraPosition'].value=(0,5,0); render()
p['plumeWidth'].value=0.00035;p['plumeLength'].value=0.0017;render()
# Hair roots stay visible, length is bounded even under extreme drift, no glow.
p['hairMode'].value=1;p['stiffness'].value=0.65;p['gravity'].value=0.35
p['plumeWidth'].value=0.15;p['plumeLength'].value=1.7
p['cameraPosition'].value=(0,0,5)
p['colorStart'].value=(0.2,0.1,0.05,1);p['colorEnd'].value=(0.2,0.1,0.05,1)
p['strandOpacity'].value=1
hair=render()
assert hair[25:40,:,3].max()>0.5, 'hair roots lost antialiased fibre coverage'
p['emission'].value=(8,8)
assert np.array_equal(hair,render()), 'hair glows'
p['directionalDrift'].value=(100,0,0)
bent=render()
assert bent[...,3].sum()>0 and bent[-5:].max()==0, 'hair disappeared or stretched'
p['directionalDrift'].value=(0,0,0)
p['effectTime'].value=8
assert np.abs(hair-render()).sum()>0.01, 'hair does not flex'
# Inspect a wider, downward lock: separated fibre coverage must survive close-up.
p['origin'].value=(0,0.85,0);p['direction'].value=(0,-1,0)
p['plumeWidth'].value=0.65;p['strandCount'].value=4;p['effectTime'].value=1
p['ambient'].value=(0.7,0.7,0.7)
hanging=render()
profile=hanging[350:390,:,3].mean(axis=0)
peaks=np.flatnonzero((profile[1:-1]>profile[:-2]) & (profile[1:-1]>profile[2:]) & (profile[1:-1]>0.15))
assert len(peaks)>=4, 'hair remains one solid wedge without visible fibres'
assert hanging[-25:,:,3].max()==0, 'hanging hair extends above its root'
p['effectTime'].value=6
moving=render()
assert np.allclose(hanging[469:,:,3],moving[469:,:,3],atol=1e-4), 'hair roots drift with animation'
if '--hair-preview' in sys.argv:
    from PIL import Image
    rgb=hanging[...,:3]+np.array([0.55,0.58,0.62])*(1-hanging[...,3:4])
    Image.fromarray((np.clip(rgb[::-1],0,1)**(1/2.2)*255).astype('uint8')).save(sys.argv[sys.argv.index('--hair-preview')+1])
if '--preview' in sys.argv:
    from PIL import Image
    rgb=lit[...,:3]+np.array([0.025,0.035,0.05])*(1-lit[...,3:4])
    Image.fromarray((np.clip(rgb[::-1],0,1)**(1/2.2)*255).astype('uint8')).save(sys.argv[sys.argv.index('--preview')+1])
print('PASS: GLSL compile/render, finite output, endpoints, advection, deterministic pause, colour gradient, emission, alpha, directional drift, camera-axis fallback, small scale, hair roots, bounded length, no glow, flex, separated fibres, hanging silhouette, stationary roots')
print('Renderer:',ctx.info['GL_RENDERER'])
