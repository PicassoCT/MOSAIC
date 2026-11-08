"""Distant layer depth, animation and linear weather; shoreline transition."""
from world_rain_gpu import *
p=program(vert,prefix+'''
uniform float testDistance;
void main(){vec2 q=(gl_FragCoord.xy-32.0)/128.0;
vec4 r=drawDistantRain(normalize(vec3(q.x,q.y,1)),testDistance);
vec4 c=composeRainEffects(vec3(0),vec4(0),r,vec4(0),vec3(0));
gl_FragColor=vec4(c.rgb*c.a,c.a);}
''')
use(p);u3(loc(p,b'eyePos'),0,500,0);u3(loc(p,b'skyCol'),.4,.5,.7)
uf(loc(p,b'rainPercent'),1);uf(loc(p,b'testDistance'),800)
assert max(render(p))==0,'distant rain over foreground'
uf(loc(p,b'testDistance'),3000);a=render(p)
assert max(a)>0,'missing distant rain'
uf(loc(p,b'time'),.4);assert render(p)!=a,'static distant layer'
uf(loc(p,b'time'),0)
for rain in [i/10 for i in range(11)]:
 uf(loc(p,b'rainPercent'),rain);b=render(p)
 assert max(abs(y-x*rain) for x,y in zip(a,b))<.005,'weather applied more than once'
print('PASS: distant rain depth rejection, animation, 0.0–1.0 linear visibility')
p=program(vert,prefix+'''
uniform float testHeight;
void main(){float r=getSurfaceRivulets(vec3(gl_FragCoord.x*.2,testHeight,gl_FragCoord.y*.2),normalize(vec3(.4,1,0)));
gl_FragColor=vec4(r);}
''')
use(p)
for height in [-1,0]:
 uf(loc(p,b'testHeight'),height);assert max(render(p))==0
uf(loc(p,b'testHeight'),.001);assert max(render(p))<.00001
uf(loc(p,b'testHeight'),1.5);assert max(render(p))>.1
print('PASS: shoreline smoothly fades to zero; no underwater runoff')
