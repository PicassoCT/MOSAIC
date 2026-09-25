"""Render the production volume shader: MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/cloud_volumes_gpu.py
Optional --preview PATH saves a contact sheet for visual review. Requires moderngl, numpy, Pillow, lupa.
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
                glow=0.,opacity=1.,phase=0.,smokeColor=(.25,.24,.23),hotColor=(1.,.55,.12),ambient=(.5,.5,.5),shape=0,steps=24,volumeAxis=1,gradientSign=1.,
                windView=(0.,0.,0.),upView=(0.,1.,0.),windDeform=0.,proxyScale=1.).items():p[n].value=v

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
# Load the production Lua presets rather than duplicating tuned values here.
from lupa.lua51 import LuaRuntime
lua=LuaRuntime(unpack_returned_tuples=True)
config=lua.execute((root.parent/'include/cloud_volume_config.lua').read_text())
def preset(name,age,ambient=(.08,.08,.08)):
    cfg=config.Preset(name)
    opacity,density,emission,growth=config.Appearance(cfg,age)
    return render(shape=cfg['shape'],density=cfg['density']*density,
                  emission=cfg['emission']*emission,glow=(cfg['glow'] or 0)*emission,
                  opacity=opacity,phase=age/(cfg['lifetime'] or cfg['duration'] or 1e9),
                  effectTime=age*cfg['speed'],smokeColor=tuple(cfg['color'][i] for i in range(1,4)),
                  hotColor=tuple(cfg['hot'][i] for i in range(1,4)),ambient=ambient)
for name,channels in [('depressol',(2,0)),('tollwutox',(0,1)),('orgyanyl',(0,2)),('wanderlost',(1,0))]:
    gas=preset('aerosol_'+name,2.)
    assert gas[...,:3].sum()>100,'unreadable aerosol at night: '+name
    assert gas[...,channels[0]].sum()>gas[...,channels[1]].sum()*3,'aerosol hue lost: '+name
    dark=render(glow=0.)
    assert np.allclose(gas[...,3],dark[...,3]),'glow changed aerosol opacity'
    assert gas[...,:3].sum()>dark[...,:3].sum()*4,'weak aerosol glow: '+name
    assert preset('aerosol_'+name,6.).max()==0,'expired aerosol leaves light'
for name in ['fire','flameTongue','gasExplosion','risingSmoke']:
    lit=preset(name,.8);unlit=render(emission=0.,glow=0.)
    assert np.allclose(lit[...,3],unlit[...,3]),name+' brightness changes alpha'
    assert lit[...,:3].sum()>unlit[...,:3].sum()*3,name+' too dark at night'
    assert render(opacity=0.,glow=2.,emission=6.).max()==0,'invisible flame leaves glow'
preset('risingSmoke',18.);assert p['emission'].value==0 and p['glow'].value==0,'old soot never cools'
assert render()[...,3].sum()>0,'cooled soot disappeared prematurely'
images=[(name,preset('aerosol_'+name,2.)) for name in ['depressol','tollwutox','orgyanyl','wanderlost']]+[
    ('Flame tongue',preset('flameTongue',.8)),('Gas flare',preset('gasExplosion',.8)),
    ('Hot rising smoke',preset('risingSmoke',2.)),('Cooled smoke',preset('risingSmoke',18.))]

# Pump-only wind: exercise the production transform with room for deformed edges.
cfg=config.Preset('risingSmoke'); bend=cfg['windDeform']; padding=1+bend*1.5
def wind_camera(linear=None):
    camera(ortho=True)
    model=np.eye(4);model[:3,:3]=(np.eye(3) if linear is None else linear)*padding;model[2,3]=-4
    matrix(0x1700,model)
def centroid(im):
    alpha=im[...,3]
    return float((alpha*np.arange(w)[None,:]).sum()/alpha.sum())
wind_camera();preset('risingSmoke',18.)
calm=render(proxyScale=padding,windDeform=0.,windView=(1.,0.,0.))
right=render(windDeform=bend)
assert np.array_equal(right,render()),'paused wind deformation changes'
left=render(windView=(-1.,0.,0.))
assert centroid(right)>centroid(left)+3,'density does not bend downwind'
assert np.abs(right-calm).sum()>10,'wind changes no smoke shape'
later=render(effectTime=7.,windView=(1.,0.,0.))
assert np.abs(later-right).sum()>10,'rolling smoke frozen'
# Sample enlarged proxy face-on: its density must die before every screen edge.
for transform in [np.eye(3),np.diag([-1.,1.,1.]),
                  np.array([[0.,-.8,0.],[1.2,0.,0.],[0.,0.,.7]])]:
    wind_camera(transform)
    right=render(windView=(1.,0.,0.));left=render(windView=(-1.,0.,0.))
    assert centroid(right)>centroid(left)+2,'piece transform rotated/reversed world wind'
    assert right[:3].max()==0 and right[-3:].max()==0 and right[:,:3].max()==0 and right[:,-3:].max()==0,'wind clips at proxy edge'
    still=render(windDeform=0.);breeze=render(windDeform=1e-6)
    assert np.allclose(still,breeze,atol=.0001),'noise jumps when calm wind starts'
    render(windDeform=bend)
# A camera yaw changes view-space wind; projected drift still follows it.
yaw=np.array([[.7071,0.,.7071],[0.,1.,0.],[-.7071,0.,.7071]])
wind_camera(yaw)
right=render(windView=(.7071,0.,-.7071));left=render(windView=(-.7071,0.,.7071))
assert centroid(right)>centroid(left)+2,'camera yaw changed world wind direction'
wind_camera();render(windView=(0.,0.,0.),windDeform=0.)
assert render(opacity=0.).max()==0,'wind smoke survives zero opacity'
depth.write(np.full((h,w),.01,dtype='f4').tobytes())
assert render(opacity=.7,windDeform=bend).max()==0,'wind smoke draws through foreground'
depth.write(np.ones((h,w),dtype='f4').tobytes())
wind_camera();preset('risingSmoke',18.)
wind_preview=render(proxyScale=padding,windDeform=bend,windView=(1.,0.,0.))
images.extend([('Pump smoke: calm',calm),('Pump smoke: wind',wind_preview)])
camera();render(windDeform=0.,proxyScale=1.)
if '--preview' in sys.argv:
    from PIL import Image,ImageDraw
    sheet=Image.new('RGB',(w*len(images),h+30),(18,22,28));draw=ImageDraw.Draw(sheet)
    for i,(name,im) in enumerate(images):
        rgb=im[...,:3]+np.array([.025,.035,.05])*(1-im[...,3:4])
        # Clamped HDR with display gamma for the preview; the game uses its framebuffer.
        rgb=np.clip(rgb,0,1)**(1/2.2)
        sheet.paste(Image.fromarray((rgb[::-1]*255).astype('uint8')),(i*w,30));draw.text((i*w+10,9),name,fill='white')
    sheet.save(sys.argv[sys.argv.index('--preview')+1])
print('PASS: compile, deterministic turbulence, silhouettes, alpha/emission, cooling, foreground depth, camera inside, orthographic, mirrored transform, both clip-depth conventions, aerosol identification, flame and rising smoke glow')
print(ctx.info['GL_RENDERER'])
print('PASS: pump wind bends density, rolling silhouette, paused wind, reversed wind, mirrored/rotated/scaled pieces, padded bounds, wind depth and alpha')
