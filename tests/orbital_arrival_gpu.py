"""Production shader check using headless EGL/Mesa; no Python GL packages needed.
Run: python3 tests/orbital_arrival_gpu.py [--preview-dir /tmp/arrival-preview]
"""
import argparse, ctypes as C, os
from pathlib import Path
import numpy as np
os.environ.setdefault('EGL_PLATFORM','surfaceless')
egl=C.CDLL('libEGL.so.1'); gl=C.CDLL('libGL.so.1')
def bind(lib,name,restype,args):
 f=getattr(lib,name); f.restype=restype; f.argtypes=args; return f
I=C.c_int; U=C.c_uint; F=C.c_float; P=C.c_void_p
bind(egl,'eglGetDisplay',P,[P]); bind(egl,'eglInitialize',U,[P,C.POINTER(I),C.POINTER(I)])
bind(egl,'eglBindAPI',U,[U]); bind(egl,'eglChooseConfig',U,[P,C.POINTER(I),C.POINTER(P),I,C.POINTER(I)])
bind(egl,'eglCreateContext',P,[P,P,P,C.POINTER(I)]); bind(egl,'eglCreatePbufferSurface',P,[P,P,C.POINTER(I)])
bind(egl,'eglMakeCurrent',U,[P,P,P,P])
display=egl.eglGetDisplay(None); major=I(); minor=I()
assert egl.eglInitialize(display,C.byref(major),C.byref(minor))
assert egl.eglBindAPI(0x30A2)
attrs=(I*13)(0x3033,1,0x3040,8,0x3024,8,0x3023,8,0x3022,8,0x3021,8,0x3038)
config=P(); count=I(); assert egl.eglChooseConfig(display,attrs,C.byref(config),1,C.byref(count)) and count.value
context=egl.eglCreateContext(display,config,None,(I*7)(0x3098,3,0x30FB,3,0x30FD,2,0x3038)); assert context
W,H=960,540
surface=egl.eglCreatePbufferSurface(display,config,(I*5)(0x3057,W,0x3056,H,0x3038)); assert surface
assert egl.eglMakeCurrent(display,surface,surface,context)
for n,ret,args in [
 ('glCreateShader',U,[U]),('glShaderSource',None,[U,I,C.POINTER(C.c_char_p),P]),
 ('glCompileShader',None,[U]),('glGetShaderiv',None,[U,U,C.POINTER(I)]),
 ('glGetShaderInfoLog',None,[U,I,P,C.c_char_p]),('glCreateProgram',U,[]),
 ('glAttachShader',None,[U,U]),('glLinkProgram',None,[U]),('glGetProgramiv',None,[U,U,C.POINTER(I)]),
 ('glGetProgramInfoLog',None,[U,I,P,C.c_char_p]),('glUseProgram',None,[U]),
 ('glGetUniformLocation',I,[U,C.c_char_p]),('glUniform1f',None,[I,F]),('glUniform1i',None,[I,I]),
 ('glUniform2f',None,[I,F,F]),('glGenTextures',None,[I,C.POINTER(U)]),
 ('glBindTexture',None,[U,U]),('glTexImage2D',None,[U,I,I,I,I,I,U,U,P]),
 ('glTexParameteri',None,[U,U,I]),('glActiveTexture',None,[U]),
 ('glGenFramebuffers',None,[I,C.POINTER(U)]),('glBindFramebuffer',None,[U,U]),
 ('glFramebufferTexture2D',None,[U,U,U,U,I]),('glViewport',None,[I,I,I,I]),
 ('glBegin',None,[U]),('glEnd',None,[]),('glTexCoord2f',None,[F,F]),('glVertex2f',None,[F,F]),
 ('glReadPixels',None,[I,I,I,I,U,U,P]),('glDisable',None,[U]),('glGetError',U,[]),
 ('glGetString',C.c_char_p,[U])]: bind(gl,n,ret,args)
print('GL:',gl.glGetString(0x1F02).decode())
def compile_stage(kind,source):
 shader=gl.glCreateShader(kind); src=C.c_char_p(source.encode())
 gl.glShaderSource(shader,1,C.byref(src),None); gl.glCompileShader(shader)
 status=I(); gl.glGetShaderiv(shader,0x8B81,C.byref(status))
 if not status.value:
  log=C.create_string_buffer(65536); gl.glGetShaderInfoLog(shader,len(log),None,log); raise AssertionError(log.value.decode())
 return shader
vertex='#version 150 compatibility\nvoid main(){gl_Position=gl_ModelViewProjectionMatrix*gl_Vertex;gl_TexCoord[0]=gl_MultiTexCoord0;}'
root=Path(__file__).resolve().parents[1]/'luaui/widgets_mosaic/shaders'
def program(path):
 p=gl.glCreateProgram()
 gl.glAttachShader(p,compile_stage(0x8B31,vertex));gl.glAttachShader(p,compile_stage(0x8B30,path.read_text()));gl.glLinkProgram(p)
 status=I();gl.glGetProgramiv(p,0x8B82,C.byref(status))
 if not status.value:
  log=C.create_string_buffer(65536);gl.glGetProgramInfoLog(p,len(log),None,log);raise AssertionError(log.value.decode())
 return p
earth=program(root/'orbital_arrival_earth.frag'); composite=program(root/'orbital_arrival_composite.frag')
def uniform(p,n,v,integer=False):
 gl.glUseProgram(p);loc=gl.glGetUniformLocation(p,n.encode())
 if isinstance(v,tuple):gl.glUniform2f(loc,*v)
 elif integer:gl.glUniform1i(loc,v)
 else:gl.glUniform1f(loc,v)
def texture(data=None):
 t=U();gl.glGenTextures(1,C.byref(t));gl.glBindTexture(0x0DE1,t.value)
 gl.glTexImage2D(0x0DE1,0,0x8814,W,H,0,0x1908,0x1406,None if data is None else data.ctypes.data)
 for key,val in [(0x2801,0x2601),(0x2800,0x2601),(0x2802,0x812F),(0x2803,0x812F)]:gl.glTexParameteri(0x0DE1,key,val)
 return t.value
fbo=U();gl.glGenFramebuffers(1,C.byref(fbo)); orbit=texture();out=texture()
y,x=np.mgrid[0:H,0:W]; live_data=np.ones((H,W,4),dtype='f4')
live_data[:,:,0]=x/W;live_data[:,:,1]=y/H;live_data[:,:,2]=((x//24+y//24)%2)*0.5
live=texture(live_data); other=texture(np.full_like(live_data,0.05)); art=texture(np.full_like(live_data,0.25))
gl.glDisable(0x0BE2);gl.glDisable(0x0B71)
def quad(p,target):
 gl.glBindFramebuffer(0x8D40,fbo.value);gl.glFramebufferTexture2D(0x8D40,0x8CE0,0x0DE1,target,0)
 gl.glViewport(0,0,W,H);gl.glUseProgram(p);gl.glBegin(7)
 for px,py,u,v in [(-1,-1,0,0),(1,-1,1,0),(1,1,1,1),(-1,1,0,1)]:gl.glTexCoord2f(u,v);gl.glVertex2f(px,py)
 gl.glEnd();assert gl.glGetError()==0
 data=np.empty((H,W,4),dtype='f4');gl.glReadPixels(0,0,W,H,0x1908,0x1406,data.ctypes.data)
 assert np.isfinite(data).all();return data
uniform(earth,'elapsed',20);uniform(earth,'aspect',W/H)
for n,v in [('orbitTex',0),('artworkTex',1),('liveTex',2),('hasArtwork',1),('hasLive',1)]:uniform(composite,n,v,True)
uniform(composite,'artScale',(1.,1.));uniform(composite,'fade',1.)
def render(descent,live_input=live,fade=1.):
 uniform(earth,'descent',descent);gl.glActiveTexture(0x84C0);gl.glBindTexture(0x0DE1,0)
 e=quad(earth,orbit)
 for unit,tex in enumerate((orbit,art,live_input)):gl.glActiveTexture(0x84C0+unit);gl.glBindTexture(0x0DE1,tex)
 uniform(composite,'descent',descent);uniform(composite,'fade',fade)
 return e,quad(composite,out)
parser=argparse.ArgumentParser();parser.add_argument('--preview-dir');args=parser.parse_args()
for descent in [0.,0.16,0.43,0.52,0.65,0.8,0.96,1.]:
 e,result=render(descent)
 assert result[:,:,:3].min()>=0 and result[:,:,:3].max()<=1.5
 if 0.42<=descent<=0.55:assert np.allclose(e[:,:,3],1.),'Handoff cloud is not fully opaque'
 if descent==1.:
  assert np.allclose(result,live_data,atol=2e-6),'Final composite changed live pixels or orientation'
 if args.preview_dir:
  from PIL import Image
  directory=Path(args.preview_dir);directory.mkdir(parents=True,exist_ok=True)
  Image.fromarray(np.uint8(np.clip(result[::-1,:,:3],0,1)*255)).save(directory/f'{descent:.2f}.png')
a=render(0.52,live)[1];b=render(0.52,other)[1]
assert np.array_equal(a,b),'Cloud handoff exposes underlying projection switch'
assert np.allclose(render(0,fade=0)[1][:,:,:3],0.25,atol=1e-6),'Artwork continuity failed'
print('PASS: production shaders compile; finite output; fully opaque cloud handoff; exact final live pixels; artwork continuity')
