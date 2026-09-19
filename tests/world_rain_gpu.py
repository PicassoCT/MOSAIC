"""Standard-library-only EGL smoke/regression tests; run python tests/world_rain_gpu.py.
Uses production GLSL and Mesa/OpenGL compatibility context; no game required.
"""
import ctypes as C
import os
from pathlib import Path
os.environ.setdefault('EGL_PLATFORM', 'surfaceless')
os.environ.setdefault('MESA_GL_VERSION_OVERRIDE', '3.3COMPAT')
E=C.CDLL('libEGL.so.1'); G=C.CDLL('libGL.so.1')
def fn(lib,name,result,*args):
    f=getattr(lib,name); f.restype=result; f.argtypes=args; return f
I=C.c_int; U=C.c_uint; F=C.c_float; P=C.c_void_p
display=fn(E,'eglGetDisplay',P,P)(None)
assert fn(E,'eglInitialize',U,P,P,P)(display,None,None)
assert fn(E,'eglBindAPI',U,U)(0x30A2)
attrs=(I*11)(0x3033,1,0x3040,8,0x3024,8,0x3021,8,0x3025,0,0x3038)
config=P(); count=I()
assert fn(E,'eglChooseConfig',U,P,P,P,I,P)(display,attrs,C.byref(config),1,C.byref(count)) and count.value
context=fn(E,'eglCreateContext',P,P,P,P,P)(display,config,None,(I*1)(0x3038))
surface=fn(E,'eglCreatePbufferSurface',P,P,P,P)(display,config,(I*5)(0x3057,64,0x3056,64,0x3038))
assert context and surface
assert fn(E,'eglMakeCurrent',U,P,P,P,P)(display,surface,surface,context)
create=fn(G,'glCreateShader',U,U)
source=fn(G,'glShaderSource',None,U,I,P,P)
compile_shader=fn(G,'glCompileShader',None,U)
get_shader=fn(G,'glGetShaderiv',None,U,U,P)
shader_log=fn(G,'glGetShaderInfoLog',None,U,I,P,P)
def shader(kind,text):
    s=create(kind); data=C.c_char_p(text.encode()); source(s,1,C.byref(data),None); compile_shader(s)
    ok=I(); get_shader(s,0x8B81,C.byref(ok))
    log=C.create_string_buffer(16384); shader_log(s,len(log),None,log)
    assert ok.value,log.value.decode()
    return s
create_program=fn(G,'glCreateProgram',U)
attach=fn(G,'glAttachShader',None,U,U); link=fn(G,'glLinkProgram',None,U)
get_program=fn(G,'glGetProgramiv',None,U,U,P)
def program(v,f):
    p=create_program(); attach(p,shader(0x8B31,v)); attach(p,shader(0x8B30,f)); link(p)
    ok=I(); get_program(p,0x8B82,C.byref(ok))
    log=C.create_string_buffer(16384)
    fn(G,'glGetProgramInfoLog',None,U,I,P,P)(p,len(log),None,log)
    assert ok.value,log.value.decode()
    return p
root=Path(__file__).resolve().parents[1]/'luaui/widgets_mosaic/shaders'
frag=(root/'rainShader.frag').read_text().replace('// RAIN_LIGHT_GLITTER',(root/'rainLightGlitter.glsl').read_text()).replace('// WORLD_RAIN',(root/'worldRain.glsl').read_text()).replace('// SURFACE_WATER',(root/'surfaceWater.glsl').read_text()).replace('// RAIN_SPLASHBACK',(root/'rainSplashback.glsl').read_text())
vert=(root/'rainShader.vert').read_text()
program(vert,frag)
prefix=frag[:frag.index('void main(void)')]
normal_program=program(vert,prefix+'''
void main(){bool g,u,p,s; vec3 n=GetGroundVertexNormal(vec2(0.5),g,u,p,s);
gl_FragColor=vec4(g?1:0,u?1:0,p?1:0,s?1:0);}
''')
use=fn(G,'glUseProgram',None,U); loc=fn(G,'glGetUniformLocation',I,U,C.c_char_p)
ui=fn(G,'glUniform1i',None,I,I); uf=fn(G,'glUniform1f',None,I,F)
u3=fn(G,'glUniform3f',None,I,F,F,F)
gen=fn(G,'glGenTextures',None,I,P); active=fn(G,'glActiveTexture',None,U)
bind=fn(G,'glBindTexture',None,U,U); param=fn(G,'glTexParameteri',None,U,U,I)
upload=fn(G,'glTexImage2D',None,U,I,I,I,I,I,U,U,P)
textures=[]
for slot,name in enumerate(['normaltex','normalunittex','mapDepthTex','modelDepthTex']):
    t=U(); gen(1,C.byref(t)); textures.append(t)
    active(0x84C0+slot); bind(0x0DE1,t.value)
    param(0x0DE1,0x2801,0x2600); param(0x0DE1,0x2800,0x2600)
    use(normal_program); ui(loc(normal_program,name.encode()),slot)
def texture(slot,rgba):
    active(0x84C0+slot); bind(0x0DE1,textures[slot].value)
    upload(0x0DE1,0,0x8814,1,1,0,0x1908,0x1406,(F*4)(*rgba))
begin=fn(G,'glBegin',None,U); vertex=fn(G,'glVertex2f',None,F,F); end=fn(G,'glEnd',None)
read=fn(G,'glReadPixels',None,I,I,I,I,U,U,P)
fn(G,'glViewport',None,I,I,I,I)(0,0,64,64)
def render(p):
    use(p); begin(7)
    for x,y in [(-1,-1),(1,-1),(1,1),(-1,1)]: vertex(x,y)
    end(); data=(F*(64*64*4))(); read(0,0,64,64,0x1908,0x1406,data)
    assert fn(G,'glGetError',U)()==0
    return list(data)
up=(0.5,1,0.5,0); wall=(1,0.5,0.5,1); empty=(0,0,0,0)
cases=[('ground',up,empty,.6,1,(1,0,1,0)),
       ('roof alpha zero',up,up,.6,.3,(0,1,1,0)),
       ('wall hides ground',up,wall,.6,.3,(0,1,0,0)),
       ('ground hides unit',up,wall,.2,.7,(1,0,1,0)),
       ('normal without deferred depth',up,empty,1,1,(1,0,1,0)),
       ('sky',empty,empty,1,1,(0,0,0,1))]
for name,g,u,gd,ud,expected in cases:
    texture(0,g); texture(1,u); texture(2,(gd,0,0,0)); texture(3,(ud,0,0,0))
    got=render(normal_program)[:4]
    assert all(abs(a-b)<.01 for a,b in zip(got,expected)),(name,got,expected)
print('PASS: production shader compile/link; combined terrain/unit normals, roofs, walls, sky, alpha-independent eligibility, deferred-depth fallback')

# Render the production rain helper with perspective rays in several directions.
rain_program=program(vert,prefix+'''
uniform vec3 testForward;
uniform float testDistance;
void main(){vec2 q=(gl_FragCoord.xy/64.0-0.5)*0.7;
vec3 right=normalize(cross(testForward,abs(testForward.y)>.99?vec3(0,0,1):vec3(0,1,0)));
vec3 up=cross(right,testForward);
gl_FragColor=drawWorldRain(normalize(testForward+q.x*right+q.y*up),testDistance);}
''')
def scalar(name,value): uf(loc(rain_program,name.encode()),value)
def vector(name,value): u3(loc(rain_program,name.encode()),*value)
use(rain_program)
vector('eyePos',(128,512,128)); vector('sunCol',(1,1,1)); vector('skyCol',(.3,.4,.5))
scalar('time',1); scalar('timePercent',.5); scalar('rainLightActive',0); scalar('testDistance',2000)
import math
images=[]
for direction in [(0,-1,0),(1,0,0),(0,0,1),(0,1,0),(.5,-.5,.5)]:
    vector('testForward',direction); pixels=render(rain_program)
    assert all(math.isfinite(x) for x in pixels)
    assert max(pixels[3::4])>0,('no precipitation',direction)
    assert pixels==render(rain_program),'non-deterministic frame'
    images.append(pixels)
scalar('testDistance',0); assert max(render(rain_program)[3::4])==0,'depth occlusion'
scalar('testDistance',2000); scalar('time',2)
assert render(rain_program)!=images[-1],'time animation'
print('PASS: vertical/horizontal/oblique rain, deterministic stationary camera, time animation, scene-depth occlusion; GPU',fn(G,'glGetString',C.c_char_p,U)(0x1F01).decode())

# Identical world rays must produce identical drops after a one-pixel camera pan.
# Orthographic test camera isolates anchoring from perspective/AA changes.
ortho=program(vert,prefix.replace('uniform vec3 eyePos;', 'vec3 eyePos;')+'''
uniform vec3 testCamera;
void main(){eyePos=testCamera+vec3(gl_FragCoord.x*2.0,0,gl_FragCoord.y*2.0);
gl_FragColor=drawWorldRain(vec3(0,-1,0),2000.0);}
''')
use(ortho)
for name,value in [('sunCol',(0.4,0.4,0.4)),('skyCol',(0.1,0.1,0.1)),('testCamera',(128,512,128))]:
    u3(loc(ortho,name.encode()),*value)
uf(loc(ortho,b'time'),1)
a=render(ortho)
u3(loc(ortho,b'testCamera'),130,512,128)
b=render(ortho)
assert max(a[3::4])>0
for y in range(64):
    for x in range(63):
        ia=(y*64+x+1)*4; ib=(y*64+x)*4
        assert a[ia:ia+4]==b[ib:ib+4],('camera anchoring',x,y)
print('PASS: camera pan preserves identical world-ray precipitation (63x64 pixel overlap)')

water_program=program(vert,prefix+'''
uniform float testUp;
void main(){vec2 w=surfaceWaterWeights(testUp);
float r=getSurfaceRivulets(vec3(gl_FragCoord.x*0.25,0,gl_FragCoord.y*0.25),
                          normalize(vec3(0.4,0.9,0.2)));
gl_FragColor=vec4(w,r,1);}
''')
use(water_program)
last=(-1,-1)
for upwardness in [0,.3,.45,.6,.8,.92,.94,.96,.98,.995,1]:
    uf(loc(water_program,b'testUp'),upwardness)
    pixels=render(water_program); wet,puddle=pixels[:2]
    assert wet>=last[0] and puddle>=last[1],('nonmonotonic slope blend',upwardness)
    if upwardness<=.45: assert wet==0 and puddle==0
    if upwardness==1: assert wet==1 and puddle==1
    if upwardness==.98: assert 0<puddle<1
    last=(wet,puddle)
a=render(water_program)
uf(loc(water_program,b'time'),.3); b=render(water_program)
assert max(a[2::4])>0 and min(a[2::4])==0,'channels do not resolve'
assert a[2::4]!=b[2::4],'rivulets not animated'
print('PASS: flat puddles -> partial blend -> rivulets -> dry walls; animated sparse channels')
