"""Production tapered facade capture + reprojection, using a real Mesa GL context.
Run from repo root: python3 tests/standalone_taper_gpu.py
Requires numpy; the EGL setup uses ctypes. Optional --preview PATH writes a PNG.
"""
from pathlib import Path
import argparse
import numpy as np

exec(Path('tests/world_rain_gpu.py').read_text().split('root=Path(__file__)')[0])
root = Path('luaui/widgets_mosaic/shaders/radiancecascade')
N = 256
use=fn(G,'glUseProgram',None,U)
loc=fn(G,'glGetUniformLocation',I,U,C.c_char_p)
ui=fn(G,'glUniform1i',None,I,I); uf=fn(G,'glUniform1f',None,I,F)
u2=fn(G,'glUniform2f',None,I,F,F); u3=fn(G,'glUniform3f',None,I,F,F,F)
active=fn(G,'glActiveTexture',None,U); bind=fn(G,'glBindTexture',None,U,U)
upload=fn(G,'glTexImage2D',None,U,I,I,I,I,I,U,U,P)
bind_fbo=fn(G,'glBindFramebuffer',None,U,U)
attach_tex=fn(G,'glFramebufferTexture2D',None,U,U,U,U,I)
buffers=fn(G,'glDrawBuffers',None,I,P)
viewport=fn(G,'glViewport',None,I,I,I,I)
clear=fn(G,'glClear',None,U); enable=fn(G,'glEnable',None,U); disable=fn(G,'glDisable',None,U)
begin=fn(G,'glBegin',None,U); end=fn(G,'glEnd',None)
vertex=fn(G,'glVertex3f',None,F,F,F); normal=fn(G,'glNormal3f',None,F,F,F)
uv=fn(G,'glTexCoord2f',None,F,F)
matrix=fn(G,'glMatrixMode',None,U); identity=fn(G,'glLoadIdentity',None)
read=fn(G,'glReadPixels',None,I,I,I,I,U,U,P)

def texture(data=None, depth=False):
    t=U(); fn(G,'glGenTextures',None,I,P)(1,C.byref(t)); bind(0x0DE1,t.value)
    for option in [0x2800,0x2801]: fn(G,'glTexParameteri',None,U,U,I)(0x0DE1,option,0x2600)
    for option in [0x2802,0x2803]: fn(G,'glTexParameteri',None,U,U,I)(0x0DE1,option,0x812F)
    if depth: upload(0x0DE1,0,0x81A6,N,N,0,0x1902,0x1406,None)
    else:
        data=np.ascontiguousarray(data if data is not None else np.zeros((N,N,4)),dtype='f4')
        upload(0x0DE1,0,0x8814,data.shape[1],data.shape[0],0,0x1908,0x1406,data.ctypes.data)
    return t.value

def framebuffer(targets,depth=None):
    f=U(); fn(G,'glGenFramebuffers',None,I,P)(1,C.byref(f)); bind_fbo(0x8D40,f.value)
    for i,t in enumerate(targets): attach_tex(0x8D40,0x8CE0+i,0x0DE1,t,0)
    if depth: attach_tex(0x8D40,0x8D00,0x0DE1,depth,0)
    buffers(len(targets),(U*len(targets))(*[0x8CE0+i for i in range(len(targets))]))
    assert fn(G,'glCheckFramebufferStatus',U,U)(0x8D40)==0x8CD5
    return f.value

capture_program=program((root/'taper_capture.vert').read_text(),(root/'taper_capture.frag').read_text())
splat_program=create_program()
for kind,name in [(0x8B31,'taper_splat.vert'),(0x8DD9,'taper_splat.geom'),(0x8B30,'taper_splat.frag')]:
    attach(splat_program,shader(kind,(root/name).read_text()))
link(splat_program)
ok=I(); get_program(splat_program,0x8B82,C.byref(ok))
log=C.create_string_buffer(8192); fn(G,'glGetProgramInfoLog',None,U,I,P,P)(splat_program,len(log),None,log)
assert ok.value,log.value.decode()

color=texture(); position=texture(); depth=texture(depth=True)
capture_fbo=framebuffer([color,position],depth)
output=texture(); output_fbo=framebuffer([output])
diffuse=np.ones((64,64,4),dtype='f4'); diffuse[:32,:,:3]=[1,.32,.08]; diffuse[32:,:,:3]=[.1,.5,1]
mask=np.zeros((64,64,4),dtype='f4'); mask[:,:,3]=1
yy,xx=np.indices((64,64)); mask[:,:,0]=((xx%8>=2)&(xx%8<6)&(yy%8>=2)&(yy%8<6))
source_tex=texture(diffuse); mask_tex=texture(mask)
zero_mask=mask.copy(); zero_mask[:,:,0]=0; zero_tex=texture(zero_mask)
points=fn(G,'glGenLists',U,I)(1)
fn(G,'glNewList',None,U,U)(points,0x1300)
begin(0)
for y in range(N):
    for x in range(N): vertex((x+.5)/N,(y+.5)/N,0)
end(); fn(G,'glEndList',None)()

def read_target(index=0):
    fn(G,'glReadBuffer',None,U)(0x8CE0+index)
    result=np.empty((N,N,4),dtype='f4'); read(0,0,N,N,0x1908,0x1406,result.ctypes.data)
    assert fn(G,'glGetError',U)()==0
    return result

def face(n,corners,coords=((0,0),(1,0),(1,1),(0,1))):
    begin(7); normal(*n)
    for p,t in zip(corners,coords): uv(*t); vertex(*p)
    end()

def capture(taper=.18,unlit=False,lid=False,zero_to_one=False,correct_clip=True):
    # Match Recoil's GL_ARB_clip_control path, not only Mesa's legacy default.
    fn(G,'glClipControl',None,U,U)(0x8CA1,0x935F if zero_to_one else 0x935E)
    bind_fbo(0x8D40,capture_fbo); viewport(0,0,N,N)
    use(capture_program)
    ui(loc(capture_program,b'sourceTex'),0); ui(loc(capture_program,b'materialTex'),1)
    ui(loc(capture_program,b'clipZeroToOne'),int(zero_to_one and correct_clip))
    active(0x84C0); bind(0x0DE1,source_tex); active(0x84C1); bind(0x0DE1,zero_tex if unlit else mask_tex)
    u3(loc(capture_program,b'buildingOrigin'),128,0,128)
    uf(loc(capture_program,b'taperAmount'),taper); uf(loc(capture_program,b'taperHeight'),160)
    matrix(0x1701); identity(); fn(G,'glOrtho',None,*([C.c_double]*6))(0,256,0,256,100000,-100000)
    matrix(0x1700); identity(); fn(G,'glRotatef',None,F,F,F,F)(-90,1,0,0)
    enable(0x0B71); fn(G,'glDepthMask',None,C.c_ubyte)(1); fn(G,'glDepthFunc',None,U)(0x0201)
    disable(0x0BE2); disable(0x0B44); clear(0x4100)
    face((1,0,0),[(168,0,88),(168,0,168),(168,160,168),(168,160,88)])
    face((-1,0,0),[(88,0,168),(88,0,88),(88,160,88),(88,160,168)])
    face((0,0,1),[(168,0,168),(88,0,168),(88,160,168),(168,160,168)])
    face((0,0,-1),[(88,0,88),(168,0,88),(168,160,88),(88,160,88)])
    face((0,1,0),[(88,160,88),(168,160,88),(168,160,168),(88,160,168)])
    if lid:
        active(0x84C1); bind(0x0DE1,zero_tex)
        face((0,1,0),[(40,180,40),(216,180,40),(216,180,216),(40,180,216)])
    return read_target(0),read_target(1)

def splat(emission,positions,intensity=1,origin=0,span=256):
    active(0x84C0); bind(0x0DE1,color)
    upload(0x0DE1,0,0x8814,N,N,0,0x1908,0x1406,emission.ctypes.data)
    active(0x84C1); bind(0x0DE1,position)
    upload(0x0DE1,0,0x8814,N,N,0,0x1908,0x1406,positions.ctypes.data)
    bind_fbo(0x8D40,output_fbo); viewport(0,0,N,N); use(splat_program)
    ui(loc(splat_program,b'captureEmission'),0); ui(loc(splat_program,b'capturePosition'),1)
    u2(loc(splat_program,b'domainOrigin'),origin,origin); u2(loc(splat_program,b'domainSize'),span,span)
    u2(loc(splat_program,b'atlasSize'),N,N); u2(loc(splat_program,b'heightRange'),0,128)
    uf(loc(splat_program,b'heightFalloff'),256); uf(loc(splat_program,b'emissionStrength'),intensity)
    uf(loc(splat_program,b'sourceOffset'),4)
    disable(0x0B71); clear(0x4000); enable(0x0BE2); fn(G,'glBlendFunc',None,U,U)(1,1)
    fn(G,'glCallList',None,U)(points)
    return read_target()

flat,_=capture(0); assert flat[:,:,:3].sum()==0,'vertical walls should be edge-on without taper'
e,p=capture(); assert e[:,:,:3].sum()>10,'taper did not expose window pixels'
lit=e[:,:,:3].sum(axis=2)>0
assert np.all((np.isclose(p[:,:,0][lit],88)|np.isclose(p[:,:,0][lit],168)|np.isclose(p[:,:,2][lit],88)|np.isclose(p[:,:,2][lit],168))), 'stored positions were tapered'
energies=[]
for taper in [.12,.18,.3]:
    c,_=capture(taper); energies.append(float((c[:,:,:3]*c[:,:,3:4]).sum()))
assert max(energies)/min(energies)<1.2,('capture energy changed with taper',energies)
assert capture(unlit=True)[0][:,:,:3].sum()==0,'unlit material emitted'
assert capture(lid=True)[0][:,:,:3].sum()==0,'unlit roof failed to occlude windows'
# Without depth conversion the real engine clips every above-ground facade.
assert capture(zero_to_one=True,correct_clip=False)[0][:,:,:3].sum()==0,'missing reproduction of Recoil clipping'
recoil_e,recoil_p=capture(zero_to_one=True)
assert np.allclose(recoil_e,e,rtol=1e-4,atol=1e-4),'Recoil capture lost window emission/area'
assert np.allclose(recoil_p,p,rtol=1e-4,atol=1e-4),'Recoil capture changed original source positions'
assert capture(lid=True,zero_to_one=True)[0][:,:,:3].sum()==0,'Recoil roof failed to occlude windows'
recoil_field=splat(recoil_e,recoil_p)
fn(G,'glClipControl',None,U,U)(0x8CA1,0x935E)
field=splat(e,p)
assert np.allclose(recoil_field,field,rtol=1e-4,atol=1e-4),'Recoil capture/splat lost light'
assert field[:,:,:3].sum()>0
assert field[89:167,89:167,:3].max()==0,'injected inside original footprint'
raised=p.copy(); raised[:,:,1]+=512
dim=splat(e,raised)
assert 0<dim[:,:,:3].sum()<field[:,:,:3].sum()*.3,'source heights lost before accumulation'
assert splat(e,p,intensity=0)[:,:,:3].sum()==0,'day/off multiplier failed'
local=splat(e,p,origin=32,span=192)
ratio=local[:,:,:3].sum()*(192/N)**2/field[:,:,:3].sum()
assert .98<ratio<1.02,('global/local energy mismatch',ratio)
assert field[:,:,:3].max()>1,'HDR accumulation clamped'
print('PASS: GLSL compile/link; Recoil zero-to-one and legacy depth capture/splat; window extraction; material mask; original positions; unlit roof depth; taper area correction; outward injection; height falloff; zero intensity; HDR; global/local energy')
print('Area-weighted capture energy at taper 0.12 / 0.18 / 0.30:',[round(x,1) for x in energies])

if __name__=='__main__':
    parser=argparse.ArgumentParser(); parser.add_argument('--preview'); args=parser.parse_args()
    if args.preview:
        from PIL import Image,ImageDraw
        canvas=Image.new('RGB',(1120,430),(12,17,26)); draw=ImageDraw.Draw(canvas)
        draw.text((22,18),'MOSAIC / tapered facade emission - actual shader output, synthetic tower',fill='white')
        panels=[('Top-down, no taper',flat[:,:,:3]),('Tapered window capture',e[:,:,:3]),('Restored facade emission',field[:,:,:3]*.15),('Same sources +512 high',dim[:,:,:3]*.15)]
        for i,(title,data) in enumerate(panels):
            rgb=(255*np.clip(1-np.exp(-data*2),0,1)).astype('uint8')
            canvas.paste(Image.fromarray(np.flipud(rgb)),(22+i*274,80))
            draw.text((22+i*274,55),title,fill='white')
        draw.text((22,361),'Positions return to the original walls. Energy is added after per-source height weighting.',fill=(173,190,208))
        draw.text((22,389),'The first panel is dark because vertical facades have zero area in an ordinary top-down capture.',fill=(173,190,208))
        canvas.save(args.preview)
