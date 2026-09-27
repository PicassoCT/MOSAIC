"""Production facade/mask/projection GLSL in Mesa. No engine or game assets required.
Run: python3 tests/window_lighting_gpu.py [--preview /tmp/window-light.png]
Needs numpy, Mesa EGL and Lua/texlua (for the production flood-fill helper).
"""
from pathlib import Path
import argparse, shutil, subprocess, tempfile
import numpy as np
exec(Path('tests/world_rain_gpu.py').read_text().split('root=Path(__file__)')[0])
root=Path('luaui/widgets_mosaic/shaders/windowlight')
use=fn(G,'glUseProgram',None,U);loc=fn(G,'glGetUniformLocation',I,U,C.c_char_p)
ui=fn(G,'glUniform1i',None,I,I);uf=fn(G,'glUniform1f',None,I,F)
u2=fn(G,'glUniform2f',None,I,F,F);u3=fn(G,'glUniform3f',None,I,F,F,F);u4=fn(G,'glUniform4f',None,I,F,F,F,F)
active=fn(G,'glActiveTexture',None,U);bind=fn(G,'glBindTexture',None,U,U)
upload=fn(G,'glTexImage2D',None,U,I,I,I,I,I,U,U,P)
bind_fbo=fn(G,'glBindFramebuffer',None,U,U);viewport=fn(G,'glViewport',None,I,I,I,I)
begin=fn(G,'glBegin',None,U);end=fn(G,'glEnd',None);vertex=fn(G,'glVertex3f',None,F,F,F)
normal=fn(G,'glNormal3f',None,F,F,F);uv=fn(G,'glTexCoord2f',None,F,F)
enable=fn(G,'glEnable',None,U);disable=fn(G,'glDisable',None,U);clear=fn(G,'glClear',None,U)
matrix=fn(G,'glMatrixMode',None,U);identity=fn(G,'glLoadIdentity',None)
read=fn(G,'glReadPixels',None,I,I,I,I,U,U,P)
N=64;FIELD=128
def compile_program(v,f,g=None):
    p=create_program()
    for kind,name in [(0x8B31,v),(0x8DD9,g),(0x8B30,f)]:
        if name:attach(p,shader(kind,(root/name).read_text().replace('// WINDOW_CLASSIFY',(root/'classify.glsl').read_text())))
    link(p);ok=I();get_program(p,0x8B82,C.byref(ok));log=C.create_string_buffer(8192)
    fn(G,'glGetProgramInfoLog',None,U,I,P,P)(p,len(log),None,log)
    assert ok.value,log.value.decode();return p
capture_program=compile_program('capture.vert','capture.frag')
wall_program=compile_program('walls.vert','walls.frag','walls.geom')
project_program=compile_program('project.vert','project.frag','project.geom')
debug_program=compile_program('debug.vert','debug.frag')
compile_program('data.vert','data.frag')
flat_vertex='#version 150 compatibility\nvoid main(){gl_Position=gl_Vertex;gl_TexCoord[0]=gl_MultiTexCoord0;}'
copy_program=program(flat_vertex,(root/'copy.frag').read_text())
scene_program=program(flat_vertex,Path('luaui/widgets_mosaic/shaders/radiancecascade/scene.frag').read_text())
def texture(w,h,data=None,depth=False):
    t=U();fn(G,'glGenTextures',None,I,P)(1,C.byref(t));bind(0x0DE1,t.value)
    for key in [0x2800,0x2801]:fn(G,'glTexParameteri',None,U,U,I)(0x0DE1,key,0x2600)
    for key in [0x2802,0x2803]:fn(G,'glTexParameteri',None,U,U,I)(0x0DE1,key,0x812F)
    if depth:upload(0x0DE1,0,0x81A6,w,h,0,0x1902,0x1406,None)
    else:
        data=np.ascontiguousarray(data if data is not None else np.zeros((h,w,4)),dtype='f4')
        upload(0x0DE1,0,0x8814,w,h,0,0x1908,0x1406,data.ctypes.data)
    return t.value
def framebuffer(targets,depth=None):
    f=U();fn(G,'glGenFramebuffers',None,I,P)(1,C.byref(f));bind_fbo(0x8D40,f.value)
    for i,t in enumerate(targets):fn(G,'glFramebufferTexture2D',None,U,U,U,U,I)(0x8D40,0x8CE0+i,0x0DE1,t,0)
    if depth:fn(G,'glFramebufferTexture2D',None,U,U,U,U,I)(0x8D40,0x8D00,0x0DE1,depth,0)
    fn(G,'glDrawBuffers',None,I,P)(len(targets),(U*len(targets))(*[0x8CE0+i for i in range(len(targets))]))
    assert fn(G,'glCheckFramebufferStatus',U,U)(0x8D40)==0x8CD5
    return f.value
def pixels(w,h,index=0):
    fn(G,'glReadBuffer',None,U)(0x8CE0+index);out=np.empty((h,w,4),dtype='f4')
    read(0,0,w,h,0x1908,0x1406,out.ctypes.data)
    assert fn(G,'glGetError',U)()==0
    return out
def face(n,corners):
    normal(*n);begin(4)
    for idx in [0,1,2,0,2,3]:
        uv(*[(0,0),(1,0),(1,1),(0,1)][idx]);vertex(*corners[idx])
    end()
def ring(open_court=False):
    # A square block with a completely enclosed, open-topped courtyard.
    for x,n in [(128,(-1,0,0)),(384,(1,0,0))]:
        face(n,[(x,0,128),(x,0,384),(x,160,384),(x,160,128)])
    for z,n in [(128,(0,0,-1)),(384,(0,0,1))]:
        if not(open_court and z==384):face(n,[(128,0,z),(384,0,z),(384,160,z),(128,160,z)])
    for x,n in [(224,(1,0,0)),(288,(-1,0,0))]:
        face(n,[(x,0,224),(x,0,288),(x,160,288),(x,160,224)])
    for z,n in [(224,(0,0,1)),(288,(0,0,-1))]:
        if not(open_court and z==288):face(n,[(224,0,z),(288,0,z),(288,160,z),(224,160,z)])
    # Floor must not fill the courtyard mask; roofs must still block capture depth.
    face((0,1,0),[(128,0,128),(384,0,128),(384,0,384),(128,0,384)])
def uniforms(p):
    u2(loc(p,b'maskOrigin'),96,96);uf(loc(p,b'maskSpan'),320)
    u2(loc(p,b'buildingY'),0,200)
diffuse=np.ones((64,64,4),dtype='f4');diffuse[:,:,:3]=[1,.65,.25]
material=diffuse.copy();material[:,:,:3]=0;material[:,:,3]=1
yy,xx=np.indices((64,64));material[:,:,0]=((xx%8>=2)&(xx%8<6)&(yy%8>=2)&(yy%8<6))
source=texture(64,64,diffuse);mask=texture(64,64,material)
emission=texture(N*4,N);position=texture(N*4,N);depth=texture(N*4,N,depth=True)
capture_fbo=framebuffer([emission,position],depth)
def capture(zero_to_one):
    fn(G,'glClipControl',None,U,U)(0x8CA1,0x935F if zero_to_one else 0x935E)
    bind_fbo(0x8D40,capture_fbo);viewport(0,0,N*4,N)
    enable(0x0B71);fn(G,'glDepthFunc',None,U)(0x0201);fn(G,'glDepthMask',None,C.c_ubyte)(1)
    disable(0x0B44);disable(0x0BE2);clear(0x4100);use(capture_program)
    ui(loc(capture_program,b'sourceTex'),0);ui(loc(capture_program,b'materialTex'),1)
    active(0x84C0);bind(0x0DE1,source);active(0x84C1);bind(0x0DE1,mask)
    u3(loc(capture_program,b'captureOrigin'),256,0,256);u2(loc(capture_program,b'captureSize'),320,200)
    matrix(0x1701);identity();matrix(0x1700);identity()
    for i,d in enumerate([(1,0),(-1,0),(0,1),(0,-1)]):
        viewport(i*N,0,N,N);u2(loc(capture_program,b'captureDirection'),*d);ring()
    return pixels(N*4,N),pixels(N*4,N,1)
legacy,legacy_p=capture(False);captured,positions=capture(True)
assert captured[:,:,:3].sum()>10,'untapered captures lost window light'
assert np.allclose(legacy,captured,rtol=1e-4,atol=1e-4),'Recoil depth regression'
lit=captured[:,:,:3].sum(axis=2)>0
assert np.all(np.isclose(positions[:,:,0][lit],128)|np.isclose(positions[:,:,0][lit],384)|np.isclose(positions[:,:,2][lit],128)|np.isclose(positions[:,:,2][lit],384)),'side view moved surfaces or captured hidden courtyard'
wall=texture(N,N);wall_fbo=framebuffer([wall])
def walls(open_court=False):
    bind_fbo(0x8D40,wall_fbo);viewport(0,0,N,N);disable(0x0B71);clear(0x4000)
    enable(0x0BE2);fn(G,'glBlendFunc',None,U,U)(1,1);use(wall_program);uniforms(wall_program)
    uf(loc(wall_program,b'maskResolution'),N)
    for band in range(4):
        u2(loc(wall_program,b'heightRange'),band*50,(band+1)*50)
        u4(loc(wall_program,b'bandColor'),*[int(i==band) for i in range(4)]);ring(open_court)
    return pixels(N,N)
def flood(data):
    lua=shutil.which('lua') or shutil.which('texlua')
    assert lua,'install Lua or texlua for the production exterior flood fill'
    rows=','.join('{'+','.join(str(float(c)) for c in pixel)+'}' for pixel in data.reshape(-1,4))
    with tempfile.TemporaryDirectory() as tmp:
        script=Path(tmp)/'fill.lua'
        script.write_text("local M=dofile('luaui/widgets_mosaic/include/window_exterior.lua')\nlocal p=M.Fill({"+rows+"},64)\nfor _,v in ipairs(p) do print(table.concat(v,',')) end\n")
        out=subprocess.check_output([lua,str(script)],text=True)
    return np.asarray([[float(x) for x in line.split(',')] for line in out.splitlines()],dtype='f4').reshape(N,N,4)
barriers=walls();outside=flood(barriers)
assert outside[32,32,0]==0 and outside[32,32,2]==0,'closed courtyard classified outside'
assert outside[32,61,0]==1,'street-facing space rejected'
assert flood(walls(True))[32,32,0]==1,'open courtyard should remain connected'
walls() # restore GPU wall texture
exterior=texture(N,N,outside)
ground=texture(64,64);empty=np.zeros((256,256,4),dtype='f4');blockers=texture(256,256,empty)
result=texture(FIELD,FIELD);result_fbo=framebuffer([result])
def project(height=80,normal_angle=0,source_x=384,blocked=False,gain=1,cutoff=.00005):
    e=np.zeros((N,N*4,4),dtype='f4');p=e.copy()
    e[0,0]=[1*gain,.65*gain,.25*gain,128];p[0,0]=[source_x,height,256,normal_angle]
    obstacle=empty.copy()
    if blocked:
        for band in range(16):
            # Opaque wall at x=424..448, spanning all z and height bands.
            tx,ty=(band%4)*64,(band//4)*64;obstacle[ty:ty+64,tx+53:tx+56,0]=1
    for slot,t,data in [(0,emission,e),(1,position,p),(4,blockers,obstacle)]:
        active(0x84C0+slot);bind(0x0DE1,t);upload(0x0DE1,0,0x8814,data.shape[1],data.shape[0],0,0x1908,0x1406,data.ctypes.data)
    for slot,t in [(2,exterior),(3,ground),(5,wall)]:active(0x84C0+slot);bind(0x0DE1,t)
    bind_fbo(0x8D40,result_fbo);viewport(0,0,FIELD,FIELD);use(project_program)
    for i,name in enumerate(['emissionTex','positionTex','exteriorTex','groundTex','blockerTex','wallTex']):ui(loc(project_program,name.encode()),i)
    uniforms(project_program);u2(loc(project_program,b'mapSize'),512,512)
    u2(loc(project_program,b'fieldOrigin'),0,0);uf(loc(project_program,b'fieldSpan'),512);uf(loc(project_program,b'fieldResolution'),FIELD)
    uf(loc(project_program,b'maxRange'),128);uf(loc(project_program,b'cutoff'),cutoff)
    disable(0x0B71);enable(0x0BE2);fn(G,'glBlendFunc',None,U,U)(1,1);clear(0x4000)
    begin(0);vertex(.5/(N*4),.5/N,0);end()
    return pixels(FIELD,FIELD)
field=project();assert field[:,:,:3].sum()>0,'accepted exterior window failed to light ground'
assert field[:,:96,:3].max()==0,'window illuminated behind its facade'
courtyard=project(source_x=224,normal_angle=0)
assert courtyard[:,:,:3].max()==0,'courtyard emitter escaped exterior filter'
shadow=project(blocked=True)
assert shadow[:,113:,:3].max()==0 and shadow[:,:,:3].sum()>0,'blocking wall failed / killed all light'
raised=project(height=140)
assert raised[:,:,:3].sum()<field[:,:,:3].sum(),'higher source was not dimmer'
assert project(gain=0)[:,:,:3].max()==0,'disabled emission left stale light'
assert project(gain=1e-7,cutoff=1e-12)[:,108:,:3].max()>0,'geometry cutoff discarded faint samples before they could accumulate'
line=field[FIELD//2,:,0];far=np.nonzero(line)[0]
assert len(far)>1 and line[far[-1]]<line.max()*.2,'cutoff is a hard bright edge'
def constant(rgba):return texture(1,1,np.asarray([[rgba]],dtype='f4'))
def screenquad():
    begin(7)
    for x,y,u,v in [(-1,-1,0,0),(1,-1,1,0),(1,1,1,1),(-1,1,0,1)]:uv(u,v);vertex(x,y,0)
    end()
def composite(window=True,model=False,height=0):
    slots=[('radianceTex',[.2,.1,.05,0]),('occupancyTex',[0,0,0,0]),('mapDepthTex',[.5,0,0,0]),
        ('modelDepthTex',[.4 if model else 1,0,0,0]),('mapNormalTex',[.5,1,.5,1]),('modelNormalTex',[.5,1,.5,1]),
        ('mapDiffuseTex',[1,1,1,1]),('modelDiffuseTex',[1,1,1,1]),('localRadianceTex',[0,0,0,0]),
        ('localOccupancyTex',[0,0,0,0]),('headlightTex',[0,0,0,0]),('headlightLocalTex',[0,0,0,0]),
        ('windowTex',[.3,.2,.1,0]),('windowGroundTex',[height,0,0,0])]
    use(scene_program)
    for slot,(name,value) in enumerate(slots):
        active(0x84C0+slot);t=constant(value);bind(0x0DE1,t);ui(loc(scene_program,name.encode()),slot)
    for name,value in [('clipZeroToOne',1),('deferred',1),('smoothing',0),('localActive',0),('headlightActive',0),('windowActive',int(window))]:
        ui(loc(scene_program,name.encode()),value)
    u2(loc(scene_program,b'mapSize'),512,512);u2(loc(scene_program,b'heightRange'),0,128)
    uf(loc(scene_program,b'strength'),2);uf(loc(scene_program,b'nightIntensity'),1)
    inverse_p=np.zeros((4,4),dtype='f4');inverse_p[3,3]=1
    inverse_v=np.eye(4,dtype='f4');inverse_v[3,:3]=[256,height,256]
    m4=fn(G,'glUniformMatrix4fv',None,I,I,C.c_ubyte,P)
    m4(loc(scene_program,b'inverseProjection'),1,0,inverse_p.ctypes.data)
    m4(loc(scene_program,b'inverseView'),1,0,inverse_v.ctypes.data)
    bind_fbo(0x8D40,result_fbo);viewport(0,0,FIELD,FIELD);disable(0x0BE2);clear(0x4000);screenquad()
    return pixels(FIELD,FIELD)[FIELD//2,FIELD//2,:3]
assert np.allclose(composite(),1-np.exp(-np.array([.5,.3,.15])*2),atol=1e-5),'direct and cascade terms did not add once'
assert np.allclose(composite(window=False),composite(model=True),atol=1e-5),'direct ground light leaked onto model roofs'
assert np.allclose(composite(height=256),1-np.exp(-np.array([.3,.2,.1])*2),atol=1e-5),'direct terrain light incorrectly clipped to cascade height band'
print('PASS: production GLSL; untapered side capture; both depth modes; actual raster walls -> Lua flood fill; enclosed/open courtyard; original positions; direct exterior footprint; source height; obstruction; smooth cutoff; zero emission; scene addition exactly once; roof rejection; terrain above cascade band')
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--preview');args=parser.parse_args()
    if args.preview:
        from PIL import Image,ImageDraw
        canvas=Image.new('RGB',(1080,350),(13,17,23));draw=ImageDraw.Draw(canvas)
        panels=[('Exterior mask / courtyard excluded',outside[:,:,:3]),('Direct window footprint',1-np.exp(-field[:,:,:3]*100)),('Same window, higher',1-np.exp(-raised[:,:,:3]*100)),('Wall blocks projection',1-np.exp(-shadow[:,:,:3]*100))]
        for i,(title,data) in enumerate(panels):
            im=Image.fromarray((np.clip(data,0,1)*255).astype('uint8')).transpose(Image.Transpose.FLIP_TOP_BOTTOM).resize((248,248))
            canvas.paste(im,(15+i*270,55));draw.text((15+i*270,28),title,fill='white')
        draw.text((15,326),'Actual shader fixture: one window patch, synthetic courtyard. Not an in-game screenshot.',fill=(175,191,205))
        canvas.save(args.preview)
