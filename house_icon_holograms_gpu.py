"""Production house shaders on Mesa EGL. Run via run.sh -- python3 tests/house_icon_holograms_gpu.py.
Baseline material fixture is from game commit cae627c4 (before the contour merge).
Tests pixels, not a recreation of the shader's edge-detection algorithm.
"""
import ctypes as C
from pathlib import Path
import numpy as np
from railgun_headless_gl import HeadlessGL

root = Path(__file__).resolve().parents[1]
shaders = root / 'luarules/gadgets/shaders/house_icon'
ctx = HeadlessGL(128, 96)
g = ctx.gl
house = ctx.program((shaders/'house.vert').read_text(), (shaders/'house.frag').read_text())
original = ctx.program((shaders/'house.vert').read_text(), Path(__file__).with_name('house_icon_original.frag').read_text())
contour = ctx.program((shaders/'contour.vert').read_text(), (shaders/'contour.frag').read_text())
ctx.bind(g, 'glActiveTexture', None, C.c_uint)
ctx.bind(g, 'glUniform1i', None, C.c_int, C.c_int)
ctx.bind(g, 'glCopyTexSubImage2D', None, C.c_uint, C.c_int, C.c_int, C.c_int, C.c_int, C.c_int, C.c_int, C.c_int)
TEX, FBO = 0x0DE1, 0x8D40

def quad(x0,y0,x1,y1,z=0):
    g.glBegin(7)
    for x,y,u,v in ((x0,y0,0,0),(x1,y0,1,0),(x1,y1,1,1),(x0,y1,0,1)):
        g.glMultiTexCoord4f(0x84C0,u,v,0,1); g.glVertex3f(x,y,z)
    g.glEnd()

def material(program, selected, time):
    ctx.clear(); ctx.ortho(0,128,0,96,-1,1)
    g.glDisable(0x0B44); g.glEnable(0x0BE2); g.glBlendFunc(0x0302,1)
    ctx.uniform(program,'time',time); ctx.uniform(program,'selected',selected)
    if program == house: ctx.uniform(program,'maskPass',0)
    quad(20,16,80,80); quad(40,32,100,70)
    return ctx.read()

for selected in (0,1):
    for time in (0,2.75,19):
        baseline=material(original,selected,time)
        merged=material(house,selected,time)
        assert np.max(np.abs(merged-baseline)) < 1e-6, 'wireframe/scanline brightness changed'
print('Original material: pixel-identical for both selection states and three animation times')

def texture(internal, format):
    handle=C.c_uint(); g.glGenTextures(1,C.byref(handle)); g.glBindTexture(TEX,handle)
    for parameter in (0x2800,0x2801): g.glTexParameteri(TEX,parameter,0x2600)
    for parameter in (0x2802,0x2803): g.glTexParameteri(TEX,parameter,0x812F)
    g.glTexImage2D(TEX,0,internal,128,96,0,format,0x1406,None)
    return handle

mask=texture(0x8058,0x1908); depth=texture(0x81A6,0x1902)
fbo=C.c_uint(); g.glGenFramebuffers(1,C.byref(fbo)); g.glBindFramebuffer(FBO,fbo)
g.glFramebufferTexture2D(FBO,0x8CE0,TEX,mask,0)
g.glFramebufferTexture2D(FBO,0x8D00,TEX,depth,0)
assert g.glCheckFramebufferStatus(FBO)==0x8CD5

def read_depth():
    data=np.zeros((96,128),np.float32)
    g.glReadPixels(0,0,128,96,0x1902,0x1406,data.ctypes.data_as(C.c_void_p))
    return data

def draw_contour(origin=(0,0)):
    g.glBindFramebuffer(FBO,ctx.fbo); ctx.clear()
    g.glViewport(*origin,128-origin[0],96-origin[1])
    g.glDisable(0x0B71); g.glDisable(0x0BE2)
    ctx.uniform(contour,'viewportOrigin',*origin)
    for unit,name,tex in ((0,'buildingMask',mask),(1,'resolvedDepth',depth)):
        g.glActiveTexture(0x84C0+unit); g.glBindTexture(TEX,tex)
        g.glUniform1i(g.glGetUniformLocation(contour,name.encode()),unit)
    quad(-1,-1,1,1)
    result=ctx.read()
    for unit in (1,0): g.glActiveTexture(0x84C0+unit); g.glBindTexture(TEX,0)
    g.glViewport(0,0,128,96)
    return result

# Scene foreground covers the left edge of the house and its outward glow.
g.glBindFramebuffer(FBO,ctx.fbo); ctx.clear(); ctx.ortho(0,128,0,96,-1,1)
g.glUseProgram(0); g.glEnable(0x0B71); g.glDepthMask(1)
quad(0,0,24,96,0.6)
scene_depth=read_depth()
g.glBindTexture(TEX,depth); g.glCopyTexSubImage2D(TEX,0,0,0,0,0,128,96)
g.glBindTexture(TEX,0)
g.glBindFramebuffer(FBO,fbo)
g.glClearColor(0,0,0,0); g.glClear(0x4000) # keep copied depth
ctx.uniform(house,'maskPass',1); ctx.uniform(house,'selected',0)
ctx.uniform(house,'buildingKey',8/255,0,0)
g.glDisable(0x0BE2); g.glDepthFunc(0x0203)
# Two overlapping pieces with one identity; another selected building touches it.
quad(20,16,64,80); quad(48,16,80,80)
ctx.uniform(house,'buildingKey',9/255,0,0); ctx.uniform(house,'selected',1)
quad(80,16,108,80)
mask_pixels=ctx.read()
assert np.allclose(mask_pixels[40,30,:3], [8/255,0,0], atol=1e-6)
assert np.allclose(mask_pixels[40,90,:], [9/255,0,0,1], atol=1e-6)
assert not mask_pixels[40,20].any(), 'foreground must occlude mask'
g.glBindFramebuffer(FBO,ctx.fbo)
assert np.array_equal(read_depth(),scene_depth), 'mask pass changed main scene depth'
result=draw_contour()
assert result[40,23,3]==0, 'outer glow leaked across foreground'
assert result[40,24,3]>.5, 'visible house contour missing'
assert result[40,48,3]==0 and result[40,63,3]==0, 'internal piece boundary gained a contour'
assert result[40,79,3]>.5 and result[40,80,3]>.5, 'adjacent houses lost separate outlines'
assert result[40,80,0]>result[40,80,2], 'selected building must be amber'
assert result[40,79,2]>result[40,79,0], 'ordinary building must stay cyan'
assert result[40,109,3]>0 and result[40,117,3]==0, 'outer glow radius incorrect'
# The world viewport can be offset by a side panel/dual screen.
shifted=draw_contour((7,5))
assert np.allclose(shifted[5:,7:],result[:91,:121]), 'viewport origin shifts contour samples'
# Open courtyard: the opening also receives an inner contour.
g.glBindFramebuffer(FBO,fbo); ctx.clear(); ctx.ortho(0,128,0,96,-1,1)
g.glEnable(0x0B71); g.glDepthMask(1); g.glDisable(0x0BE2)
ctx.uniform(house,'maskPass',1); ctx.uniform(house,'selected',0)
ctx.uniform(house,'buildingKey',8/255,0,0)
for bounds in ((20,16,100,28),(20,68,100,80),(20,28,32,68),(88,28,100,68)): quad(*bounds)
courtyard=draw_contour()
assert courtyard[48,31,3]>.5 and courtyard[48,33,3]>0 and courtyard[48,60,3]==0
ctx.check()
print('Contour: overlap, adjacent identities, amber selection, courtyard, foreground occlusion, depth isolation and viewport offset passed')
g.glDeleteFramebuffers(1,C.byref(fbo))
for tex in (mask,depth): g.glDeleteTextures(1,C.byref(tex))
ctx.close()
