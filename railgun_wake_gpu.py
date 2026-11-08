"""Render the production railgun wake shaders with Mesa EGL, no engine needed.

Run: python tests/railgun_wake_gpu.py
Dependencies: NumPy, libEGL, libGL, a Mesa compatibility OpenGL driver.
Optional: --preview /absolute/path.png creates an actual shader contact sheet.
"""
from pathlib import Path
import sys
import numpy as np
from railgun_headless_gl import HeadlessGL

root=Path(__file__).resolve().parents[1]
ctx=HeadlessGL(768,256)
gl=ctx.gl
shaders=root/'luaui/widgets_mosaic/shaders/railgun_wake'
program=ctx.program((shaders/'wake.vert').read_text(),(shaders/'wake.frag').read_text())
ctx.ortho(-30,530,-40,40)
ctx.uniform(program,'cameraPosition',250,0,1000)
ctx.uniform(program,'driftDirection',0.7,0,0.3)
ctx.uniform(program,'ambient',0.3,0.3,0.3)

def draw_path(age, remaining=None, opacity=1, ranges=((0,500),), width=3.5, fades=(1,1)):
    remaining=15-age if remaining is None else remaining
    gl.glUseProgram(program)
    gl.glMultiTexCoord4f(0x84C1,1,0,0,width)
    gl.glMultiTexCoord4f(0x84C2,13,opacity,*fades)
    gl.glBegin(7)
    for start,end in ranges:
        cells=max(1,int(np.ceil((end-start)/12)))
        for cell in range(cells):
            a=start+(end-start)*cell/cells
            b=start+(end-start)*(cell+1)/cells
            for x,side in ((a,-1),(a,1),(b,1),(b,-1)):
                gl.glMultiTexCoord4f(0x84C0,side,x,age,remaining)
                gl.glVertex4f(x,0,0,(x-start)/(end-start))
    gl.glEnd();gl.glUseProgram(0)

def render(age, remaining=None, opacity=1, ranges=((0,500),), occlude=False, width=3.5, fades=(1,1)):
    ctx.clear()
    if occlude:
        # A foreground building writes depth only. Zero alpha leaves the
        # colour buffer untouched, making the occlusion assertion exact.
        gl.glUseProgram(0);gl.glDepthMask(1);gl.glColor4f(0,0,0,0)
        gl.glBegin(7)
        for x,y in [(220,-40),(280,-40),(280,40),(220,40)]: gl.glVertex3f(x,y,10)
        gl.glEnd();gl.glDepthMask(0)
    draw_path(age,remaining,opacity,ranges,width,fades)
    return ctx.read()

fresh=render(.1)
four=render(4)
twelve=render(12)
mass=lambda im:float(im[...,3].sum())
assert mass(fresh)>mass(four)>mass(twelve)>0, 'wake does not cool/dissolve through 12 seconds'
assert np.array_equal(four,render(4)), 'identical simulation age does not give deterministic output'
assert np.abs(four-render(4.5)).sum()>1, 'wake curls/erosion are frozen'
assert fresh[...,:3].max()>fresh[...,3].max(), 'fresh white-cyan core lacks emissive energy'
assert np.all(four[...,:3] <= four[...,3:4]+1e-6), 'old residue retains excessive emission or unpremultiplied RGB'
assert np.count_nonzero(twelve[...,3]>0.01)<np.count_nonzero(four[...,3]>0.01), 'erosion does not open gaps'
assert render(15).max()==0 and render(16).max()==0, 'residue survives its 15-second shader limit'
assert render(4,remaining=0).max()==0, 'late path samples bypass shot expiry'
assert render(-1).max()==0, 'unborn segment appears'
assert render(4,opacity=0).max()==0, 'zero-opacity wake still glows'

# A very short shot can have both endpoint fade flags on one single quad.
# Fade must be evaluated in the fragment stage so its middle stays visible.
short=render(.1,ranges=((250,260),),fades=(0,0))
assert mass(short)>0, 'two faded ends erased a one-quad short shot'

# Sparse observed paths must remain sparse after tessellation and deformation.
gapped=render(4,ranges=((0,180),(320,500)))
x=np.linspace(-30,530,ctx.width,endpoint=False)
gap=(x>195)&(x<305)
assert gapped[:,gap].max()==0, 'shader bridged an unobserved route interval'
assert mass(gapped)>0, 'gap handling erased both visible sections'

blocked=render(.1,occlude=True)
middle=(x>225)&(x<275)
assert fresh[:,middle,3].sum()>0 and blocked[:,middle,3].max()==0, 'wake ignores building depth'
assert mass(blocked)>0, 'depth occlusion erased the entire wake'

# Looking down the trajectory and small dimensions must remain finite.
ctx.uniform(program,'cameraPosition',1000,0,0)
render(.1);render(12);render(4,width=.001)
ctx.uniform(program,'cameraPosition',250,0,1000)

if '--preview' in sys.argv:
    from PIL import Image,ImageDraw
    panels=[]
    for label,im in [('0.1 seconds',render(.1,fades=(0,0))),('4 seconds',render(4,fades=(0,0))),('12 seconds',render(12,fades=(0,0)))]:
        background=np.zeros_like(im[...,:3])+[.018,.026,.034]
        rgb=im[...,:3]+background*(1-im[...,3:4])
        rgb=np.clip(rgb,0,1)**(1/2.2)
        panel=Image.fromarray((rgb[::-1]*255).astype('uint8'))
        ImageDraw.Draw(panel).text((15,12),label,fill=(220,235,240))
        panels.append(panel)
    sheet=Image.new('RGB',(ctx.width,ctx.height*3))
    for index,panel in enumerate(panels): sheet.paste(panel,(0,index*ctx.height))
    sheet.save(sys.argv[sys.argv.index('--preview')+1])

print('PASS: production GLSL compile/render, finite output, fresh emission, cooling, 12-second wisps, hard expiry, deterministic motion, alpha, visible gaps, depth occlusion and axial/small-scale stability')
print('Alpha mass at 0.1/4/12 seconds:',*[round(mass(im),3) for im in [fresh,four,twelve]])
print('Renderer:',ctx.renderer)
ctx.close()
