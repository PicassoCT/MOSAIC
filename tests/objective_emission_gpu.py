"""Real emission shaders: elevated objective projection and per-source intensity."""
from pathlib import Path
# Reuse only the standard-library EGL context/compiler setup.
setup=Path('tests/world_rain_gpu.py').read_text().split("root=Path(__file__)")[0]
exec(setup)
root=Path('luaui/widgets_mosaic/shaders/radiancecascade')
p=create_program()
for kind,name in [(0x8B31,'emission_slice.vert'),(0x8DD9,'emission_slice.geom'),(0x8B30,'emission_slice.frag')]:
    attach(p,shader(kind,(root/name).read_text()))
link(p)
ok=I();get_program(p,0x8B82,C.byref(ok));assert ok.value,'emission shader link failed'
program('#version 150 compatibility\nvoid main(){gl_Position=gl_Vertex;}',(root/'scene.frag').read_text())
fn(G,'glUseProgram',None,U)(p)
loc=fn(G,'glGetUniformLocation',I,U,C.c_char_p)
ui=fn(G,'glUniform1i',None,I,I);uf=fn(G,'glUniform1f',None,I,F)
u2=fn(G,'glUniform2f',None,I,F,F)
u2(loc(p,b'heightRange'),0,128);u2(loc(p,b'atlasSize'),64,64)
ui(loc(p,b'textured'),0)
fn(G,'glViewport',None,I,I,I,I)(0,0,64,64)
fn(G,'glMatrixMode',None,U)(0x1701);fn(G,'glLoadIdentity',None)()
fn(G,'glOrtho',None,*([C.c_double]*6))(-1,1,-1,1,-1000,1000)
fn(G,'glMatrixMode',None,U)(0x1700);fn(G,'glLoadIdentity',None)()
begin=fn(G,'glBegin',None,U);end=fn(G,'glEnd',None)
vertex=fn(G,'glVertex3f',None,F,F,F)
fn(G,'glColor4f',None,F,F,F,F)(1,1,1,1)
def capture(project,strength):
    ui(loc(p,b'projectToBand'),project);uf(loc(p,b'emissionStrength'),strength)
    fn(G,'glClear',None,U)(0x4000)
    begin(4)
    for x,y in [(-.7,-.7),(.7,-.7),(0,.7)]:vertex(x,y,-500)
    end()
    pixels=(F*(64*64*4))()
    fn(G,'glReadPixels',None,I,I,I,I,U,U,P)(0,0,64,64,0x1908,0x1406,pixels)
    return sum(pixels[0::4])
assert capture(0,1)==0,'out-of-band hologram should be clipped'
assert capture(1,1)>100,'elevated objective should emit'
assert capture(1,0)==0,'zero source intensity should not emit'
print('PASS: real GLSL compile/link, elevated objective emission, hologram clipping, zero-intensity suppression')
