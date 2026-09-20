"""Regression for the ordinary RTS distances/angles missed by close-up tests.
Run python tests/rain_visibility_gpu.py (stdlib + Mesa EGL).
"""
from rain_splashback_gpu import *

# Test a 64-pixel crop of a larger perspective view at map-sized coordinates.
# Camera matrices and depth contain the same float precision as the game.
texture(0,up); texture(1,empty); texture(3,(1,0,0,0))
sf('rainLightActive',0); sf('time',3); sf('rainPercent',1)
sv('sunCol',(.2,.2,.2)); sv('skyCol',(.1,.1,.1))
def scene(angle,distance,pixel_world):
    a=math.radians(angle)
    forward=(0,-math.sin(a),-math.cos(a)); right=(1,0,0)
    upward=(0,math.cos(a),-math.sin(a)); target=(7492,0,1466)
    eye=tuple(target[i]-distance*forward[i] for i in range(3))
    f=distance/(32*pixel_world)
    def dot(a,b): return sum(x*y for x,y in zip(a,b))
    mat('viewProjection',[
        [f*right[0],f*right[1],f*right[2],-f*dot(right,eye)],
        [f*upward[0],f*upward[1],f*upward[2],-f*dot(upward,eye)],
        [*forward,-dot(forward,eye)-1], [*forward,-dot(forward,eye)]])
    mat('viewProjectionInv',[[right[i]/f,upward[i]/f,-eye[i],eye[i]+forward[i]]
                              for i in range(3)]+[[0,0,-1,1]])
    sv('eyePos',eye)
    depths=[]
    for y in range(64):
        for x in range(64):
            qx=((x+.5)/64*2-1)/f; qy=((y+.5)/64*2-1)/f
            dy=forward[1]+right[1]*qx+upward[1]*qy
            t=-eye[1]/dy
            depths.extend((1-1/t,0,0,0))
    for slot in [2,4]:
        active(0x84C0+slot); bind(0x0DE1,textures[slot].value)
        upload(0x0DE1,0,0x8814,64,64,0,0x1908,0x1406,(F*len(depths))(*depths))

for angle in [30,45,60]:
    for distance,pixel_world in [(500,.3),(1000,.6),(1500,.9)]:
        scene(angle,distance,pixel_world)
        pixels=render(splash)
        # Count visibly blended droplets, not simply a nonzero float somewhere.
        visible=sum(a>.035 for a in pixels[3::4])
        assert visible>=3,('invisible RTS splashback',angle,distance,visible)
        assert visible<64*64*.15,('water veil',angle,distance,visible)
        assert all(math.isfinite(v) for v in pixels)
        print('splash pixels >3.5% alpha:',angle,distance,visible)

scene(45,1000,.6)
sv('sunCol',(0,0,0))
for sky,dominant in [((.08,.16,.5),2),((.6,.25,.08),0)]:
    sv('skyCol',sky)
    pixels=render(splash)
    visible=[i for i in range(0,len(pixels),4) if pixels[i+3]>.035]
    assert visible
    assert all(pixels[i+dominant]>pixels[i+1] for i in visible),'skylight hue lost'
print('PASS: splash visibility at 30/45/60 degrees and 500/1000/1500 distance; blue/orange skylight without radiance')

# Rivulets must remain distinct at these footprints rather than being erased
# by AA attenuation; a slight incline must also receive runoff coverage.
runoff=program(vert,prefix+'''
uniform float testPixelWorld;
void main(){vec3 n=normalize(vec3(0.1,1,0));
float channel=getSurfaceRivulets(vec3(gl_FragCoord.x*testPixelWorld,-0.1*gl_FragCoord.x*testPixelWorld,gl_FragCoord.y*testPixelWorld),n);
gl_FragColor=vec4(vec3(channel*(1.0-surfaceWaterWeights(n.y).y)),1);}
''')
use(runoff)
for footprint in [.3,.6,.9]:
    uf(loc(runoff,b'testPixelWorld'),footprint)
    pixels=render(runoff)[::4]
    assert max(pixels)>.05 and min(pixels)==0,('runoff disappeared',footprint)
print('PASS: readable, separated rivulets on a shallow incline at gameplay pixel footprints')
