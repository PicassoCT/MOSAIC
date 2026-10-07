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
assert np.array_equal(hair,render()), 'stationary hair flutters without wind or motion'
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
# Hold the root, camera and rest direction fixed: only wind and time change.
p['stiffness'].value=0.35;p['curl'].value=0.25
p['colorStart'].value=(0.85,0.74,0.46,1);p['colorEnd'].value=(1,0.93,0.72,1)
calm=render()
p['directionalDrift'].value=(1.53,0,0) # strength 10, production gain 1.2*0.3, scaled 4 -> 1.7
p['effectTime'].value=1
wind_right=render()
p['effectTime'].value=2.3
wind_later=render()
assert np.abs(wind_right-wind_later).sum()>1, 'steady wind does not animate a stationary lock'
assert centroid_x(wind_right)-centroid_x(calm)>4, 'stationary wind has no readable deflection'
assert np.allclose(wind_right[471:,:,3],wind_later[471:,:,3],atol=1e-4), 'wind unpinned the scalp roots'
p['directionalDrift'].value=(-1.53,0,0)
p['effectTime'].value=1
assert centroid_x(render())<centroid_x(calm)-4, 'wind reversal fails to move the lock left'
p['directionalDrift'].value=(0,0,0)
assert np.array_equal(calm,render()), 'calm hair does not return to its rest shape'
if '--hair-preview' in sys.argv:
    from PIL import Image
    rgb=hanging[...,:3]+np.array([0.55,0.58,0.62])*(1-hanging[...,3:4])
    Image.fromarray((np.clip(rgb[::-1],0,1)**(1/2.2)*255).astype('uint8')).save(sys.argv[sys.argv.index('--hair-preview')+1])
if '--preview' in sys.argv:
    from PIL import Image
    rgb=lit[...,:3]+np.array([0.025,0.035,0.05])*(1-lit[...,3:4])
    Image.fromarray((np.clip(rgb[::-1],0,1)**(1/2.2)*255).astype('uint8')).save(sys.argv[sys.argv.index('--preview')+1])
print('PASS: GLSL compile/render, finite output, endpoints, advection, deterministic pause, colour gradient, emission, alpha, directional drift, camera-axis fallback, small scale, hair roots, bounded length, no glow, separated fibres, stationary wind deflection/flutter/reversal, calm rest, pinned roots')
print('Renderer:',ctx.info['GL_RENDERER'])

# Exercise the production centre() function on the GPU. These are sampled
# shader paths, not a second CPU implementation of the landing equations.
source=(root/'smokeRibbon.vert').read_text().split('void main() {')[0]
flight=ctx.program(vertex_shader=source+'''
in vec2 samplePoint;
out vec3 samplePosition;
void main() {
    vec3 helper = abs(direction.y) < 0.9 ? vec3(0,1,0) : vec3(1,0,0);
    vec3 u = normalize(cross(direction,helper));
    samplePosition = centre(samplePoint.x,samplePoint.y,u,cross(direction,u));
}
''', varyings=['samplePosition'])
samples=np.array([(t,s) for s in range(4) for t in np.linspace(0,1,129)],dtype='f4')
vbo=ctx.buffer(samples.tobytes()); capture=ctx.buffer(reserve=len(samples)*12)
vao=ctx.vertex_array(flight,[(vbo,'2f','samplePoint')])
for name,value in dict(origin=(0,0,0),direction=(0,-1,0),effectTime=1,
    plumeLength=1,plumeWidth=.13125,curl=.65,seed=3,strandCount=4,
    directionalDrift=(0,0,0),hairMode=0,landingMode=1,landingPad=(0,-2,0,1)).items():
    flight[name].value=value

def paths():
    vao.transform(capture,vertices=len(samples))
    result=np.frombuffer(capture.read(),dtype='f4').reshape(4,129,3).copy()
    assert np.isfinite(result).all()
    return result

free=paths()
assert free[:,16:49,1].max()<0, 'landing burn lost its downward core'
assert free[:,96,1].min()>0, 'return flow does not curl upward past the nozzle'
assert np.allclose(free[:,0,:],0), 'landing nozzle roots drifted'
flight['landingPad'].value=(0,-.15,0,1)
contact=paths()
assert contact[:,:,1].min()>=-.150001, 'landing flames went through the deck'
tips=contact[:,96,:][:,[0,2]]
tip_lengths=np.linalg.norm(tips,axis=1)
assert tip_lengths.min()>.1, 'pad fan failed to spread sideways'
for i in range(4):
    opposite=(i+2)%4
    assert np.dot(tips[i],tips[opposite])/(tip_lengths[i]*tip_lengths[opposite])<-.8, 'pad did not split exhaust into opposing directions'
flight['landingPad'].value=(3,-.15,0,.2)
assert np.allclose(paths(),free), 'a distant pad deflected a free jet'
# Render the actual vertex main as well: billboard width must stay above deck.
for name,value in dict(origin=(0,.15,0),direction=(0,-1,0),effectTime=1,
    plumeLength=1,plumeWidth=.13125,curl=.65,seed=3,strandCount=4,
    directionalDrift=(0,0,0),hairMode=0,landingMode=1,landingPad=(0,-.15,0,1),
    cameraPosition=(0,0,5),colorStart=(.65,.8,1,.95),colorEnd=(1,.25,.04,0),
    strandOpacity=.4,emission=(4,1)).items():
    p[name].value=value
fan=render()
assert fan[...,3].sum()>10, 'landing fan is invisible'
assert fan[:int(h*(1-.15)/2)-1,:,3].max()==0, 'billboard width pierced the deck'
if '--landing-preview' in sys.argv:
    from PIL import Image
    rgb=fan[...,:3]+np.array([.025,.035,.05])*(1-fan[...,3:4])
    Image.fromarray((np.clip(rgb[::-1],0,1)**(1/2.2)*255).astype('uint8')).save(sys.argv[sys.argv.index('--landing-preview')+1])
print('PASS: landing GLSL downward core, upward return flow, four-way pad fan, deck clipping and out-of-pad free flight')
