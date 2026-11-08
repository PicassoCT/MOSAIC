"""Render the production temporal shader in Mesa EGL; no game or pip packages needed.
Run: python tests/hivemind_ripple_gpu.py
"""
import ctypes as C
import math
import os
from pathlib import Path
os.environ.setdefault('EGL_PLATFORM', 'surfaceless')
os.environ.setdefault('MESA_GL_VERSION_OVERRIDE', '3.3COMPAT')
E, G = C.CDLL('libEGL.so.1'), C.CDLL('libGL.so.1')
I, U, F, P = C.c_int, C.c_uint, C.c_float, C.c_void_p

def fn(lib, name, result, *args):
    f = getattr(lib, name); f.restype = result; f.argtypes = args
    return f

display = fn(E, 'eglGetDisplay', P, P)(None)
assert fn(E, 'eglInitialize', U, P, P, P)(display, None, None)
assert fn(E, 'eglBindAPI', U, U)(0x30A2)
attrs = (I*11)(0x3033,1,0x3040,8,0x3024,8,0x3021,8,0x3025,0,0x3038)
config, count = P(), I()
assert fn(E,'eglChooseConfig',U,P,P,P,I,P)(display,attrs,C.byref(config),1,C.byref(count)) and count.value
context=fn(E,'eglCreateContext',P,P,P,P,P)(display,config,None,(I*1)(0x3038))
size=256
surface=fn(E,'eglCreatePbufferSurface',P,P,P,P)(display,config,(I*5)(0x3057,size,0x3056,size,0x3038))
assert context and surface
assert fn(E,'eglMakeCurrent',U,P,P,P,P)(display,surface,surface,context)

def compile_shader(kind, text):
    s=fn(G,'glCreateShader',U,U)(kind)
    data=C.c_char_p(text.encode())
    fn(G,'glShaderSource',None,U,I,P,P)(s,1,C.byref(data),None)
    fn(G,'glCompileShader',None,U)(s)
    ok=I();fn(G,'glGetShaderiv',None,U,U,P)(s,0x8B81,C.byref(ok))
    log=C.create_string_buffer(16384)
    fn(G,'glGetShaderInfoLog',None,U,I,P,P)(s,len(log),None,log)
    assert ok.value,log.value.decode()
    return s
root=Path(__file__).resolve().parents[1]/'luaui/widgets_mosaic/shaders/slowmo'
p=fn(G,'glCreateProgram',U)()
for kind,path in [(0x8B31,'slowmo.vert'),(0x8B30,'slowmo.frag')]:
    fn(G,'glAttachShader',None,U,U)(p,compile_shader(kind,(root/path).read_text()))
fn(G,'glLinkProgram',None,U)(p)
ok=I();fn(G,'glGetProgramiv',None,U,U,P)(p,0x8B82,C.byref(ok))
assert ok.value,'shader link failed'
fn(G,'glUseProgram',None,U)(p)
location=fn(G,'glGetUniformLocation',I,U,C.c_char_p)
def loc(name): return location(p,name.encode())
ui=fn(G,'glUniform1i',None,I,I); uf=fn(G,'glUniform1f',None,I,F)
u2=fn(G,'glUniform2f',None,I,F,F);u4=fn(G,'glUniform4f',None,I,F,F,F,F)
matrix=fn(G,'glUniformMatrix4fv',None,I,I,U,P)
ui(loc('screencopy'),0);ui(loc('depthcopy'),1)
u2(loc('resolution'),size,size);uf(loc('temporalPrivilege'),1)
uf(loc('realTime'),0)
# A known top-down world plane: UV -> x/z in [-700,700], depth -> height.
def transform(zero_to_one, camera_x=0):
    uf(loc('clipZeroToOne'),zero_to_one)
    scale=200 if zero_to_one else 100
    offset=-100 if zero_to_one else 0
    values=(700,0,0,0, 0,0,700,0, 0,scale,0,0, camera_x,offset,0,1)
    matrix(loc('viewProjectionInv'),1,0,(F*16)(*values))

gen=fn(G,'glGenTextures',None,I,P); active=fn(G,'glActiveTexture',None,U)
bind=fn(G,'glBindTexture',None,U,U); param=fn(G,'glTexParameteri',None,U,U,I)
upload=fn(G,'glTexImage2D',None,U,I,I,I,I,I,U,U,P)
textures=[]
for slot in range(2):
    t=U();gen(1,C.byref(t));textures.append(t)
    active(0x84C0+slot);bind(0x0DE1,t.value)
    param(0x0DE1,0x2801,0x2600);param(0x0DE1,0x2800,0x2600)
    param(0x0DE1,0x2802,0x812F);param(0x0DE1,0x2803,0x812F)
    rgba=(.25,.30,.35,1) if slot==0 else (.5,0,0,1)
    upload(0x0DE1,0,0x8814,1,1,0,0x1908,0x1406,(F*4)(*rgba))
active(0x84C0);bind(0x0DE1,0)
begin=fn(G,'glBegin',None,U);end=fn(G,'glEnd',None)
vertex=fn(G,'glVertex2f',None,F,F);texcoord=fn(G,'glTexCoord2f',None,F,F)
read=fn(G,'glReadPixels',None,I,I,I,I,U,U,P)
fn(G,'glViewport',None,I,I,I,I)(0,0,size,size)

def depth(value):
    active(0x84C1);bind(0x0DE1,textures[1].value)
    upload(0x0DE1,0,0x8814,1,1,0,0x1908,0x1406,(F*4)(value,0,0,1))

def render(age=2,source=(0,0,0),sources=1,strength=1,zero_to_one=0,camera_x=0):
    transform(zero_to_one,camera_x)
    uf(loc('slowAmount'),strength);ui(loc('sourceCount'),sources)
    u4(loc('rippleSources[0]'),*source,age)
    active(0x84C0);bind(0x0DE1,textures[0].value)
    begin(7)
    for x,y,u,v in [(-1,-1,0,0),(1,-1,1,0),(1,1,1,1),(-1,1,0,1)]:
        texcoord(u,v);vertex(x,y)
    end()
    data=(F*(size*size*4))();read(0,0,size,size,0x1908,0x1406,data)
    assert fn(G,'glGetError',U)()==0
    return list(data)

def difference(a,b): return max(abs(x-y) for x,y in zip(a,b))
def wave_points(pixels,base):
    result=[]
    for y in range(size):
        for x in range(size):
            i=(y*size+x)*4
            if pixels[i]-base[i]>.04:
                result.append(((x+.5)/size*1400-700,(y+.5)/size*1400-700))
    return result

def radius(points, center=(0,0)):
    assert points,'missing water crest'
    return sum(math.hypot(x-center[0],z-center[1]) for x,z in points)/len(points)

base=render(sources=0)
a=render(age=2);b=render(age=4)
ra,rb=radius(wave_points(a,base)),radius(wave_points(b,base))
assert abs(ra-164)<10 and abs(rb-288)<10,(ra,rb)
assert rb>ra+100,'ripple did not move outward'
shift=(180,0,-100)
shifted=render(age=2,source=shift)
assert abs(radius(wave_points(shifted,base),(180,-100))-164)<10,'ripple followed screen center'
# Moving camera and source together leaves the same view of the world effect.
assert difference(render(age=2,source=(180,0,0),camera_x=180),a)<.01,'world/camera registration mismatch'
assert difference(render(age=2,zero_to_one=1),a)<.01,'Recoil zero-to-one depth reconstruction mismatch'
assert difference(render(age=38),render(age=20))<.01,'waves stopped/restarted discontinuously after first cycle'
assert len(wave_points(render(age=38),base))>100,'no sustained effect'
assert difference(render(age=2,source=(0,500,0)),base)<.005,'ring painted over high occluder'
depth(1)
assert difference(render(age=2),base)<.005,'ring painted the sky'
depth(.5)
neutral=render(age=2,strength=0)
assert max(abs(neutral[i]-v) for i,v in enumerate([.25,.30,.35,1]*(size*size)))<.005,'zero-strength changed scene'
assert all(math.isfinite(v) for v in a+b+shifted)
# Spatially varied source color exercises the refraction path and exact inactive identity.
pattern=[]
for y in range(size):
    for x in range(size):
        v=.2+(.4 if ((x//8+y//8)%2) else 0)
        pattern.extend((v,v*.8,v*.6,1))
active(0x84C0);bind(0x0DE1,textures[0].value)
upload(0x0DE1,0,0x8814,size,size,0,0x1908,0x1406,(F*len(pattern))(*pattern))
neutral=render(strength=0)
assert difference(neutral,pattern)<.005,'inactive effect altered edge pixels or inverted UVs'
active_scene=render(age=2)
assert difference(active_scene,render(age=2,sources=0))>.1,'refraction/highlight path inactive'
print('PASS: production GLSL compile/link, outward radius, world/camera origin, both depth conventions')
print('PASS: sustained repetition, sky/high-surface exclusion, zero-strength identity, UVs and patterned refraction')
print('Renderer:',fn(G,'glGetString',C.c_char_p,U)(0x1F01).decode())
