"""Production shore shaders on headless Mesa/EGL; Python + numpy, no game.
Checks real half-float FBOs, sand/coast masking, persistent decay, wave motion,
weather/night gating, tiled UVs, emission height bands and finite output.
"""
import ctypes as C
import os
from pathlib import Path
import numpy as np
os.environ.setdefault('EGL_PLATFORM', 'surfaceless')
os.environ.setdefault('MESA_GL_VERSION_OVERRIDE', '3.3COMPAT')
E=C.CDLL('libEGL.so.1');G=C.CDLL('libGL.so.1')
I=C.c_int;U=C.c_uint;F=C.c_float;P=C.c_void_p

def fn(lib,name,result,*args):
    f=getattr(lib,name);f.restype=result;f.argtypes=args;return f

display=fn(E,'eglGetDisplay',P,P)(None)
assert fn(E,'eglInitialize',U,P,P,P)(display,None,None)
assert fn(E,'eglBindAPI',U,U)(0x30A2)
config=P();count=I()
attrs=(I*11)(0x3033,1,0x3040,8,0x3024,8,0x3021,8,0x3025,0,0x3038)
assert fn(E,'eglChooseConfig',U,P,P,P,I,P)(display,attrs,C.byref(config),1,C.byref(count)) and count.value
context=fn(E,'eglCreateContext',P,P,P,P,P)(display,config,None,(I*1)(0x3038))
surface=fn(E,'eglCreatePbufferSurface',P,P,P,P)(display,config,(I*5)(0x3057,128,0x3056,128,0x3038))
assert context and surface and fn(E,'eglMakeCurrent',U,P,P,P,P)(display,surface,surface,context)
get_error=fn(G,'glGetError',U)

def shader(kind,text):
    s=fn(G,'glCreateShader',U,U)(kind);data=C.c_char_p(text.encode())
    fn(G,'glShaderSource',None,U,I,P,P)(s,1,C.byref(data),None)
    fn(G,'glCompileShader',None,U)(s)
    ok=I();fn(G,'glGetShaderiv',None,U,U,P)(s,0x8B81,C.byref(ok))
    log=C.create_string_buffer(16384);fn(G,'glGetShaderInfoLog',None,U,I,P,P)(s,len(log),None,log)
    assert ok.value,log.value.decode();return s

root=Path(__file__).resolve().parents[1]/'luaui/widgets_mosaic/shaders/shore_bioluminescence'
common=(root/'common.glsl').read_text()
def program(name,vertex):
    p=fn(G,'glCreateProgram',U)()
    for kind,text in [(0x8B31,(root/vertex).read_text()),(0x8B30,(root/(name+'.frag')).read_text().replace('// SHORE_COMMON',common))]:
        fn(G,'glAttachShader',None,U,U)(p,shader(kind,text))
    fn(G,'glLinkProgram',None,U)(p);ok=I();fn(G,'glGetProgramiv',None,U,U,P)(p,0x8B82,C.byref(ok))
    log=C.create_string_buffer(16384);fn(G,'glGetProgramInfoLog',None,U,I,P,P)(p,len(log),None,log)
    assert ok.value,log.value.decode();return p

mask_p=program('mask','atlas.vert');history_p=program('history','atlas.vert');surface_p=program('surface','surface.vert')
use=fn(G,'glUseProgram',None,U);loc=fn(G,'glGetUniformLocation',I,U,C.c_char_p)
u1=fn(G,'glUniform1f',None,I,F);u2=fn(G,'glUniform2f',None,I,F,F);ui=fn(G,'glUniform1i',None,I,I)
def uniforms(p,ints=None,**values):
    use(p)
    for name,value in (ints or {}).items():ui(loc(p,name.encode()),value)
    for name,value in values.items():
        if isinstance(value,tuple):u2(loc(p,name.encode()),*value)
        else:u1(loc(p,name.encode()),value)

active=fn(G,'glActiveTexture',None,U);bind=fn(G,'glBindTexture',None,U,U)
param=fn(G,'glTexParameteri',None,U,U,I)
textures=[]
def texture(data,half=False):
    data=np.ascontiguousarray(data,dtype='f4');h,w,c=data.shape
    t=U();fn(G,'glGenTextures',None,I,P)(1,C.byref(t));bind(0x0DE1,t.value)
    param(0x0DE1,0x2801,0x2601);param(0x0DE1,0x2800,0x2601)
    param(0x0DE1,0x2802,0x812F);param(0x0DE1,0x2803,0x812F)
    internal=(0x822D if half else 0x822E) if c==1 else (0x881A if half else 0x8814)
    fn(G,'glTexImage2D',None,U,I,I,I,I,I,U,U,P)(0x0DE1,0,internal,w,h,0,0x1903 if c==1 else 0x1908,0x1406,data.ctypes.data)
    textures.append(t.value);return t.value

def bindings(*ids):
    for i,t in enumerate(ids):active(0x84C0+i);bind(0x0DE1,t)

fbo=U();fn(G,'glGenFramebuffers',None,I,P)(1,C.byref(fbo))
def target(t):
    fn(G,'glBindFramebuffer',None,U,U)(0x8D40,fbo.value)
    fn(G,'glFramebufferTexture2D',None,U,U,U,U,I)(0x8D40,0x8CE0,0x0DE1,t,0)
    assert fn(G,'glCheckFramebufferStatus',U,U)(0x8D40)==0x8CD5
    fn(G,'glViewport',None,I,I,I,I)(0,0,128,128)

begin=fn(G,'glBegin',None,U);end=fn(G,'glEnd',None)
vertex=fn(G,'glVertex3f',None,F,F,F);uv=fn(G,'glMultiTexCoord2f',None,U,F,F)
def quad(world=False):
    begin(7)
    for u,v in [(0,0),(1,0),(1,1),(0,1)]:
        uv(0x84C0,u,v);uv(0x84C1,u*256,v*256)
        vertex(u*256,0,v*256) if world else vertex(u*2-1,v*2-1,0)
    end()

def read():
    data=np.zeros((128,128,4),dtype='f4')
    fn(G,'glReadPixels',None,I,I,I,I,U,U,P)(0,0,128,128,0x1908,0x1406,data.ctypes.data)
    assert get_error()==0;assert np.isfinite(data).all();return data

heights=np.repeat(((np.arange(33)*8-96)*.1)[None,:,None],33,axis=0)
height=texture(heights)
sand_data=np.ones((128,128,4),dtype='f4');sand_data[64:,:,:]=0
sand=texture(sand_data)
mask=texture(np.zeros((128,128,4)),half=True)
history=[texture(np.zeros((128,128,1)),half=True) for _ in range(2)]
out=texture(np.zeros((128,128,4)),half=True)
bindings(height,sand);target(mask)
uniforms(mask_p,ints={'heightTex':0,'sandTex':1},mapSize=(256,256));quad()
m=read();assert m[24,55,1]>.95 and abs(m[24,55,0]-15)<.15
assert m[96,:,1].max()<.001,'non-sand coastline glows'
assert m[24,110,1]==0,'inland lowland glows'
assert m[24,35,0]<0 and m[24,35,1]>.9,'wave cannot approach sandy coast'
print('PASS: production mask finds real coast, preserves sand, rejects harbour/inland, uses half-float FBO')

# Independent steep cliff must be ineligible even with the sand channel on.
cliff=texture(np.repeat(((np.arange(33)*8-96)*1.0)[None,:,None],33,axis=0))
bindings(cliff,sand);target(out);use(mask_p);quad();assert read()[:,:,1].max()==0,'cliff glow'

def step(t,previous_time,gate=1):
    bindings(history[0],mask);target(history[1])
    uniforms(history_p,ints={'previousTex':0,'maskTex':1},shoreTime=t,previousTime=previous_time,
             halfLife=6,intensity=gate,lineWidth=3)
    quad();data=read()[:,:,0];history.reverse();return data

previous=0
for i in range(1,51):
    t=i*.1;trail=step(t,previous);previous=t
assert trail.max()>.65,'no sand deposits'
assert np.count_nonzero(trail>.02)<128*128*.07,'painted a carpet instead of lines'
assert trail[64:,:].max()==0 and trail[:,:48].max()==0,'trail leaked off sand'
a=trail.copy();b=step(6,5)
assert np.allclose(b,a*2**(-1/6),atol=.001),'trail moved or failed exponential decay'
c=step(6,6);assert np.array_equal(c,b),'paused history changed'
print('PASS: thin fixed sand lines, exponential decay, pause, no submerged/non-sand trail')

# Top-down projection for actual production surface vertex+fragment pair.
rows=np.array([[2/256,0,0,-1],[0,0,2/256,-1],[0,-.001,0,0],[0,0,0,1]],dtype='f4')
fn(G,'glMatrixMode',None,U)(0x1701);fn(G,'glLoadMatrixf',None,P)(np.ascontiguousarray(rows.T).ctypes.data)
fn(G,'glMatrixMode',None,U)(0x1700);fn(G,'glLoadIdentity',None)()
def surface_render(t,gate=1,band=(0,128)):
    bindings(history[0],mask,height);target(out)
    fn(G,'glClearColor',None,F,F,F,F)(0,0,0,0);fn(G,'glClear',None,U)(0x4000)
    uniforms(surface_p,ints={'historyTex':0,'maskTex':1,'heightTex':2,'capture':1},
             mapSize=(256,256),shoreTime=t,historyTime=6,halfLife=6,intensity=gate,
             lineWidth=3,gain=.28,heightRange=band)
    quad(world=True);return read()

a=surface_render(6);b=surface_render(6.4)
assert a[:,:,:3].max()>.03 and np.abs(a-b).sum()>1,'no moving front/emission'
assert surface_render(6,0).max()==0,'day/rain gate leaked'
assert surface_render(6,1,(128,256)).max()==0,'emission escaped height band'
assert np.allclose(surface_render(6,.25)[:,:,:3]/.25,a[:,:,:3],atol=.012),'intensity scaled twice'
print('PASS: moving blue-green front, radiance emission, dry-night gate, ground band, finite output')

# Optional diagnostic of real shader output, not a generated mockup.
if os.environ.get('SHORE_TEST_IMAGE'):
    from PIL import Image
    pic=np.clip(surface_render(6.4)[:,:,:3]*4,0,1)
    Image.fromarray((pic[::-1]*255).astype('uint8')).resize((768,768)).save(os.environ['SHORE_TEST_IMAGE'])
