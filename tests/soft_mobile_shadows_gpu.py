"""Run actual GLSL using Mesa EGL/OpenGL, no pip packages needed.

python3 tests/soft_mobile_shadows_gpu.py
Software GPU regression, not an engine or target-hardware performance test.
"""
from pathlib import Path
from array import array
import ctypes as C
import os

os.environ.setdefault('EGL_PLATFORM', 'surfaceless')
os.environ.setdefault('LIBGL_ALWAYS_SOFTWARE', '1')
EGL = C.CDLL('libEGL.so.1')
GL = C.CDLL('libGL.so.1')
I, U, F, D, P = C.c_int, C.c_uint, C.c_float, C.c_double, C.c_void_p

def function(lib, name, result, *arguments):
    fn = getattr(lib, name)
    fn.restype, fn.argtypes = result, arguments
    return fn

get_display = function(EGL, 'eglGetDisplay', P, P)
initialize = function(EGL, 'eglInitialize', U, P, P, P)
bind_api = function(EGL, 'eglBindAPI', U, U)
choose = function(EGL, 'eglChooseConfig', U, P, P, P, I, P)
create_context = function(EGL, 'eglCreateContext', P, P, P, P, P)
make_current = function(EGL, 'eglMakeCurrent', U, P, P, P, P)
display = get_display(None)
assert initialize(display, None, None), 'Mesa EGL initialization failed'
assert bind_api(0x30A2), 'EGL OpenGL API unavailable'
attributes = (I * 9)(0x3033, 1, 0x3040, 8, 0x3024, 8, 0x3023, 8, 0x3038)
config, number = P(), I()
assert choose(display, attributes, C.byref(config), 1, C.byref(number)) and number.value
context = create_context(display, config, None, (I * 7)(0x3098,3,0x30FB,3,0x30FD,2,0x3038))
assert context and make_current(display, None, None, context), 'OpenGL compatibility context failed'

get_string = function(GL, 'glGetString', C.c_char_p, U)
print('Renderer:', get_string(0x1F01).decode())
create_shader = function(GL, 'glCreateShader', U, U)
shader_source = function(GL, 'glShaderSource', None, U, I, P, P)
compile_shader = function(GL, 'glCompileShader', None, U)
shader_iv = function(GL, 'glGetShaderiv', None, U, U, P)
shader_log = function(GL, 'glGetShaderInfoLog', None, U, I, P, P)
create_program = function(GL, 'glCreateProgram', U)
attach = function(GL, 'glAttachShader', None, U, U)
link = function(GL, 'glLinkProgram', None, U)
program_iv = function(GL, 'glGetProgramiv', None, U, U, P)
program_log = function(GL, 'glGetProgramInfoLog', None, U, I, P, P)
use = function(GL, 'glUseProgram', None, U)
location = function(GL, 'glGetUniformLocation', I, U, C.c_char_p)
uniform_i = function(GL, 'glUniform1i', None, I, I)
uniform_1 = function(GL, 'glUniform1f', None, I, F)
uniform_2 = function(GL, 'glUniform2f', None, I, F, F)
uniform_3 = function(GL, 'glUniform3f', None, I, F, F, F)
uniform_matrix = function(GL, 'glUniformMatrix4fv', None, I, I, U, P)
gen_textures = function(GL, 'glGenTextures', None, I, P)
bind_texture = function(GL, 'glBindTexture', None, U, U)
active_texture = function(GL, 'glActiveTexture', None, U)
tex_image = function(GL, 'glTexImage2D', None, U, I, I, I, I, I, U, U, P)
tex_param = function(GL, 'glTexParameteri', None, U, U, I)
gen_fbos = function(GL, 'glGenFramebuffers', None, I, P)
bind_fbo = function(GL, 'glBindFramebuffer', None, U, U)
fbo_texture = function(GL, 'glFramebufferTexture2D', None, U, U, U, U, I)
fbo_status = function(GL, 'glCheckFramebufferStatus', U, U)
viewport = function(GL, 'glViewport', None, I, I, I, I)
clear_color = function(GL, 'glClearColor', None, F, F, F, F)
clear = function(GL, 'glClear', None, U)
read_pixels = function(GL, 'glReadPixels', None, I, I, I, I, U, U, P)
begin = function(GL, 'glBegin', None, U)
end = function(GL, 'glEnd', None)
vertex = function(GL, 'glVertex2f', None, F, F)
texcoord = function(GL, 'glTexCoord2f', None, F, F)
error = function(GL, 'glGetError', U)
get_integer = function(GL, 'glGetIntegerv', None, U, P)

def program(fragment):
    result = create_program()
    for kind, text in ((0x8B31, '#version 150 compatibility\nvoid main(){gl_Position=gl_Vertex;gl_TexCoord[0]=gl_MultiTexCoord0;}'), (0x8B30, fragment)):
        shader = create_shader(kind)
        encoded = C.c_char_p(text.encode())
        shader_source(shader, 1, C.byref(encoded), None)
        compile_shader(shader)
        ok = I(); shader_iv(shader, 0x8B81, C.byref(ok))
        log = C.create_string_buffer(32768); shader_log(shader, len(log), None, log)
        assert ok.value, log.value.decode()
        attach(result, shader)
    link(result)
    ok = I(); program_iv(result, 0x8B82, C.byref(ok))
    log = C.create_string_buffer(32768); program_log(result, len(log), None, log)
    assert ok.value, log.value.decode()
    return result

def uniform(p, name, value, integer=False):
    use(p); loc = location(p, name.encode())
    if loc < 0: return
    if integer: uniform_i(loc, value)
    elif isinstance(value, (int, float)): uniform_1(loc, value)
    elif len(value) == 2: uniform_2(loc, *value)
    elif len(value) == 3: uniform_3(loc, *value)
    else: uniform_matrix(loc, 1, 0, (F*16)(*value))

def texture(width, height, values):
    previous=I();get_integer(0x8069,C.byref(previous))
    t = U(); gen_textures(1, C.byref(t)); bind_texture(0x0DE1, t.value)
    for param, value in ((0x2801,0x2600),(0x2800,0x2600),(0x2802,0x812F),(0x2803,0x812F)):
        tex_param(0x0DE1, param, value)
    tex_image(0x0DE1, 0, 0x8814, width, height, 0, 0x1908, 0x1406, (F*len(values))(*values))
    bind_texture(0x0DE1,previous.value)
    return t.value

def bind(p, name, slot, t):
    active_texture(0x84C0+slot); bind_texture(0x0DE1, t); uniform(p,name,slot,integer=True)

def draw(p):
    use(p); clear_color(0,0,0,0); clear(0x4000)
    begin(7)
    for x,y,u,v in ((-1,-1,0,0),(1,-1,1,0),(1,1,1,1),(-1,1,0,1)):
        texcoord(u,v); vertex(x,y)
    end()
    output=(F*4)(); read_pixels(0,0,1,1,0x1908,0x1406,output)
    assert error()==0, 'OpenGL error'
    assert all(abs(x)<1e10 for x in output), 'non-finite output'
    return tuple(output)

ROOT=Path(__file__).resolve().parents[1]
SHADERS=ROOT/'luaui/widgets_mosaic/shaders/radiancecascade'
helper=(SHADERS/'mobile_shadow.glsl').read_text()
ray_program=program('#version 150 compatibility\n'+helper+'''\nuniform vec3 testSource;
uniform vec3 testReceiver;uniform float testOwner;
void main(){gl_FragColor=vec4(mobileVisibility(testSource,testReceiver,testOwner));}''')
output_texture=texture(1,1,[0]*4)
fbo=U();gen_fbos(1,C.byref(fbo));bind_fbo(0x8D40,fbo.value)
fbo_texture(0x8D40,0x8CE0,0x0DE1,output_texture,0)
assert fbo_status(0x8D40)==0x8CD5
viewport(0,0,1,1)

def proxy(center, half, shape=1, owner=73, axes=((1,0,0),(0,1,0),(0,0,1))):
    return center, half, shape, owner, axes

def mobile_data(records, origin=(0,0), span=256, softness=3):
    values=array('f',[0])*(256*32*4); cells=[[] for _ in range(1024)]; low,high=1e9,-1e9
    pad=max(1,2*softness)
    for slot,(center,half,shape,owner,axes) in enumerate(records):
        def write(row,data): values[row*4:row*4+4]=array('f',data)
        write(slot*5,(*center,shape))
        for axis in range(3):write(slot*5+1+axis,(*axes[axis],half[axis]))
        write(slot*5+4,(owner,0,0,0))
        extent=[sum(abs(axes[j][i])*half[j] for j in range(3)) for i in range(3)]
        low=min(low,center[1]-extent[1]-pad);high=max(high,center[1]+extent[1]+pad)
        lower=[int((center[k]-extent[k]-pad-origin[i])*32//span) for i,k in enumerate((0,2))]
        upper=[int((center[k]+extent[k]+pad-origin[i])*32//span) for i,k in enumerate((0,2))]
        for z in range(max(0,lower[1]),min(31,upper[1])+1):
            for x in range(max(0,lower[0]),min(31,upper[0])+1):cells[z*32+x].append(slot+1)
    for cell,indices in enumerate(cells):
        assert len(indices)<=16
        start=(1280+cell*4)*4
        values[start:start+len(indices)]=array('f',indices)
    return texture(256,32,values),len(records),origin,span,(low,high) if records else (0,0),softness

def set_mobile(p,data,active=1):
    tex,count,origin,span,height,softness=data
    bind(p,'mobileShadowData',15,tex)
    for name,value in [('mobileShadowActive',active),('mobileShadowCount',count)]:uniform(p,name,value,integer=True)
    for name,value in [('mobileShadowOrigin',origin),('mobileShadowSpan',span),('mobileShadowHeight',height),('mobileShadowSoftness',softness)]:uniform(p,name,value)

def ray(data,source,receiver,owner=-1,active=1):
    set_mobile(ray_program,data,active)
    uniform(ray_program,'testSource',source);uniform(ray_program,'testReceiver',receiver);uniform(ray_program,'testOwner',owner)
    return draw(ray_program)[0]

def near(actual,expected,label):assert abs(actual-expected)<1e-5,(label,actual,expected)

box=proxy((128,12,128),(12,10,20))
hard=mobile_data([box],softness=0)
for start,finish,expected in [((32,12,128),(224,12,128),0),((32,1,128),(224,1,128),1),((32,40,128),(224,40,128),1),((128,40,128),(128,0,128),0),((128,40,128),(128,40,128),1),((-100,12,128),(224,12,128),0),((32,12,128),(100,12,128),1)]:
    near(ray(hard,start,finish),expected,'hard regression')
near(ray(hard,(32,12,128),(224,12,128),owner=73),1,'exact owner')
near(ray(hard,(32,12,128),(224,12,128),active=0),1,'disabled')
near(ray(mobile_data([]),(32,12,128),(224,12,128)),1,'removed')
for shape in (1,2):
    data=mobile_data([proxy((128,12,128),(12,10,20),shape=shape)])
    near(ray(data,(32,12,128),(224,12,128)),0,'umbra')
    near(ray(data,(32,12,128),(224,12,190)),1,'clear')
    values=[ray(data,(32,12,128),(224,12,165+i*.2)) for i in range(61)]
    assert any(.03<v<.97 for v in values),(shape,'no penumbra',values)
    assert all(b>=a-1e-4 for a,b in zip(values,values[1:])),(shape,'non-monotone edge')
    # Moving the spatial grid cannot create a seam or count a caster twice.
    shifted=mobile_data([proxy((128,12,128),(12,10,20),shape=shape)],origin=(1,1))
    for i in range(0,61,5):near(ray(shifted,(32,12,128),(224,12,165+i*.2)),values[i],'grid shift')

# Full orientation and height handling remain active in soft mode.
q=2**-.5
pitched=mobile_data([proxy((128,30,128),(20,4,4),axes=((q,q,0),(-q,q,0),(0,0,1)))])
assert ray(pitched,(96,40,128),(160,40,128))<.1
near(ray(pitched,(96,58,128),(160,58,128)),1,'pitched roof clearance')
large=mobile_data([proxy((8320,12,4224),(12,10,20))],origin=(8192,4096))
near(ray(large,(8224,12,4224),(8416,12,4224)),0,'large world coordinates')
near(ray(large,(8224,12,4224),(8300,12,4224)),1,'blocker beyond receiver')

# Fixed lamp and blocker, scan corresponding receiver-plane silhouette edges.
def penumbra_width(receiver_x):
    data=mobile_data([proxy((128,12,128),(12,10,20))])
    zs=[128+i*.1 for i in range(700)]
    partial=[z for z in zs if .05<ray(data,(32,12,128),(receiver_x,12,z))<.95]
    assert partial
    return max(partial)-min(partial)
near_width=penumbra_width(144);far_width=penumbra_width(224)
assert far_width>near_width*2,(near_width,far_width)
print('PASS: hard compatibility, box/ellipsoid penumbra, opaque core, cone widening, finite segments, owner IDs, grid seams and cleanup')

# Real production scene: nearest depth receiver, real normal, both atlas paths.
scene=(SHADERS/'scene.frag').read_text()
program(scene) # Ordinary 14-sampler fallback still compiles without the helper.
scene=scene.replace('#version 150 compatibility','#version 150 compatibility\n#define MOBILE_SHADOWS_ENABLED 1',1).replace('// MOBILE_SHADOWS',helper,1)
scene_program=program(scene)
zero=texture(32,32,[0]*(32*32*4));white=texture(1,1,[1,1,1,1]);normal=texture(1,1,[0,0.5,0.5,1]);depth=texture(1,1,[.4,0,0,0]);far_depth=texture(1,1,[.9,0,0,0])
for slot,(name,tex) in enumerate([('radianceTex',zero),('occupancyTex',zero),('mapDepthTex',far_depth),('modelDepthTex',depth),('mapNormalTex',normal),('modelNormalTex',normal),('mapDiffuseTex',white),('modelDiffuseTex',white),('localRadianceTex',white),('localOccupancyTex',zero),('headlightTex',white),('headlightLocalTex',white),('windowTex',zero),('windowGroundTex',zero)]):bind(scene_program,name,slot,tex)
for name,value in [('deferred',1),('clipZeroToOne',0),('smoothing',0),('localActive',1),('headlightActive',1),('headlightLocalActive',1),('mobileCascadeSourceActive',1),('mobileDirectSourceActive',1),('windowActive',0),('objectiveLightCount',0)]:uniform(scene_program,name,value,integer=True)
for name,value in [('mapSize',(256,256)),('heightRange',(0,128)),('strength',1),('nightIntensity',1),('headlightIntensity',1),('localOrigin',(0,0)),('localSpan',256),('headlightOrigin',(0,0)),('headlightSpan',256)]:uniform(scene_program,name,value)
identity=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]
uniform(scene_program,'inverseProjection',identity)
# Center receiver inside its proxy; deep within the local field blend plateau.
receiver=(160,12,128)
view=identity[:];view[12:15]=[receiver[0],receiver[1],receiver[2]+.2]
uniform(scene_program,'inverseView',view)
receiver_body=proxy(receiver,(12,10,8),owner=74)
set_mobile(scene_program,mobile_data([receiver_body]))
atlas=texture(2,1,[32,12,128,1,32,12,128,74])
bind(scene_program,'mobileSourceAtlas',14,atlas)
front=draw(scene_program)[0]
back_normal=texture(1,1,[1,.5,.5,1]);bind(scene_program,'modelNormalTex',5,back_normal)
back=draw(scene_program)[0]
assert front>.6 and back<1e-5,('normal receiving',front,back)
# A different proxy must still block the receiving body; never clear a radius.
bind(scene_program,'modelNormalTex',5,normal)
set_mobile(scene_program,mobile_data([receiver_body,proxy((100,12,128),(12,10,8),owner=75)]))
near(draw(scene_program)[0],0,'neighbor shadows receiving surface')
# Owner clearance changes obstruction, not the facing-normal calculation.
set_mobile(scene_program,mobile_data([receiver_body]))
atlas=texture(2,1,[32,12,128,1,32,12,128,75]);bind(scene_program,'mobileSourceAtlas',14,atlas)
bind(scene_program,'modelNormalTex',5,back_normal)
near(draw(scene_program)[0],0,'own lamp does not light back face')
# Ground at the same reconstructed point is NOT classified as a vehicle pixel.
bind(scene_program,'mapDepthTex',2,depth);bind(scene_program,'modelDepthTex',3,far_depth)
bind(scene_program,'mapNormalTex',4,back_normal)
assert draw(scene_program)[0]>.6,'ground inherited vehicle facing restriction'
print('PASS: production scene and fallback compilation, depth/normal receiving, back-face rejection, owner response, neighboring occlusion, ground isolation')
print('All soft mobile-shadow GPU checks passed.')
