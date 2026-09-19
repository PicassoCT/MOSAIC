"""Validate lit falling rain and its final half-float/straight-alpha composition.
Run python tests/rain_composite_gpu.py (stdlib + Mesa EGL).
"""
from world_rain_gpu import *

# Use the actual storage format now configured by the widget. Testing only a
# mask in an 8-bit pbuffer missed the loss of highlight energy before blending.
fbo=U(); fn(G,'glGenFramebuffers',None,I,P)(1,C.byref(fbo))
fn(G,'glBindFramebuffer',None,U,U)(0x8D40,fbo.value)
out=U(); gen(1,C.byref(out)); active(0x84C0); bind(0x0DE1,out.value)
param(0x0DE1,0x2801,0x2600); param(0x0DE1,0x2800,0x2600)
upload(0x0DE1,0,0x881A,64,64,0,0x1908,0x1406,None)
fn(G,'glFramebufferTexture2D',None,U,U,U,U,I)(0x8D40,0x8CE0,0x0DE1,out.value,0)
assert fn(G,'glCheckFramebufferStatus',U,U)(0x8D40)==0x8CD5
p=program(vert,prefix+'''
uniform vec3 testBackground;
uniform vec3 testRunoff;
uniform vec4 testSurface;
uniform vec4 testRain;
uniform vec4 testSplash;
void main(){gl_FragColor=composeRainEffects(testBackground,testSurface,testRain,testSplash,testRunoff);}
''')
u4=fn(G,'glUniform4f',None,I,F,F,F,F)
use(p)
surface=(.15,.2,.25,.2); rain=(.08,.2,.5,.3); splash=(.2,.1,.05,.15); runoff=(.03,.06,.1)
for background in [(.04,.06,.09),(.3,.3,.3),(.8,.8,.8)]:
    u3(loc(p,b'testBackground'),*background)
    for weather in [0,.4,1]:
        uf(loc(p,b'rainPercent'),weather)
        for name,value in [('testSurface',surface),('testRain',rain),('testSplash',splash)]:
            u4(loc(p,name.encode()),*value)
        u3(loc(p,b'testRunoff'),*runoff)
        result=render(p)[:4]
        composite=[result[i]*result[3]+background[i]*(1-result[3]) for i in range(3)]
        wet=[surface[i]*surface[3]+background[i]*(1-surface[3]) for i in range(3)]
        expected=[background[i]*(1-weather)+weather*(wet[i]+rain[i]*rain[3]+splash[i]*splash[3]+runoff[i]) for i in range(3)]
        assert max(abs(a-b) for a,b in zip(composite,expected))<.001,(background,weather,composite,expected)
# A faint glint on a bright surface must retain RGB above one until blending.
u3(loc(p,b'testBackground'),.8,.8,.8)
u4(loc(p,b'testSurface'),0,0,0,0); u4(loc(p,b'testRain'),.1,.2,.4,.03)
u4(loc(p,b'testSplash'),0,0,0,0); u3(loc(p,b'testRunoff'),0,0,0)
uf(loc(p,b'rainPercent'),1)
r=render(p)[:4]
assert r[2]>1.1,'highlight clipped inside rain canvas'
assert r[2]*r[3]+.8*(1-r[3])>.81,'no reflected-light contrast on bright background'
print('PASS: half-float canvas, additive rain/splash/runoff, unchanged surface blend, weather applied once, no dark bars on bright backgrounds')

# The fullscreen falling rain itself, with no hologram geometry or splashback.
# Check atmospheric hue independently of local radiance and then the radiance path.
use(rain_program)
vector('eyePos',(256,100,256)); vector('testForward',(0,-.4,1))
scalar('time',3); scalar('testDistance',400); scalar('timePercent',.5)
scalar('rainLightActive',0); vector('sunCol',(0,0,0))
for sky,dominant in [((.08,.16,.5),2),((.6,.25,.08),0)]:
    vector('skyCol',sky)
    pixels=render(rain_program)
    visible=[i for i in range(0,len(pixels),4) if pixels[i+3]>.025]
    assert visible,'no foreground rain'
    assert all(pixels[i+dominant]>pixels[i+1] for i in visible),'sky hue lost'
vector('skyCol',(0,0,0))
assert max(render(rain_program)[::4])==0,'invented illumination'
# Reuse texture slots, but never sample the attached render target itself.
for slot,name,rgba in [(5,'rainRadianceTex',(0,1,0,0)),(6,'rainOccupancyTex',(0,0,0,0))]:
    t=U(); gen(1,C.byref(t)); active(0x84C0+slot); bind(0x0DE1,t.value)
    param(0x0DE1,0x2801,0x2600); param(0x0DE1,0x2800,0x2600)
    upload(0x0DE1,0,0x8814,1,1,0,0x1908,0x1406,(F*4)(*rgba))
    ui(loc(rain_program,name.encode()),slot)
u2=fn(G,'glUniform2f',None,I,F,F)
u2(loc(rain_program,b'rainMapSize'),4096,4096); u2(loc(rain_program,b'rainLightHeight'),0,1024)
scalar('rainLightActive',1); scalar('rainLocalActive',0)
scalar('rainLightIntensity',1); scalar('rainLightStrength',2)
pixels=render(rain_program)
visible=[i for i in range(0,len(pixels),4) if pixels[i+3]>.025]
assert visible and any(pixels[i+1]>.1 for i in visible),'no radiance on actual falling rain'
assert all(pixels[i]==0 and pixels[i+2]==0 for i in visible),'wrong radiance hue'
print('PASS: actual falling streaks receive blue/orange skylight and green radiance, independent of hologram rain or splashback')
