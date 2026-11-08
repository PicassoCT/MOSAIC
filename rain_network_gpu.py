"""Stable drainage paths, monotonic rain widths and animation confined to paths."""
from world_rain_gpu import *
p=program(vert,prefix+'''
void main(){vec2 at=gl_FragCoord.xy*.25;
float mask=terrainChannelMask(at,.25);
float water=terrainWaterFilm(at,.25);
gl_FragColor=vec4(mask,water,0,1);}
''')
use(p);previous=None;coverage=[]
for rain in [i/10 for i in range(1,11)]:
 uf(loc(p,b'terrainWetness'),rain);uf(loc(p,b'terrainFlowTime'),0);a=render(p)
 uf(loc(p,b'terrainFlowTime'),3.7);b=render(p)
 assert a[::4]==b[::4],'network moves with time'
 if previous is not None: assert all(x<=y for x,y in zip(previous,a[::4])),'rain relocates or narrows channels'
 previous=a[::4];coverage.append(sum(previous))
 assert max(abs(x-y) for x,y in zip(a[1::4],b[1::4]))>.005,'missing flow animation'
 for mask,x,y in zip(a[::4],a[1::4],b[1::4]):
  if mask==0: assert x==y,'animation outside drainage paths'
assert coverage[-1]>coverage[0]*2,'insufficient channel widening'
print('PASS: fixed recursive split/rejoin network, monotonically wider channels at rain 0.1–1.0, flow confined to channels')

# Old 64-unit offsets must no longer reproduce identical channel patches.
repeat=program(vert,prefix+'''
uniform vec3 offset;
void main(){vec2 at=gl_FragCoord.xy+offset.xy;
vec4 f=terrainChannelFrame(at,1.0);
gl_FragColor=vec4(f.x,terrainWaterFilm(at,1.0),f.y,1);}
''')
use(repeat);uf(loc(repeat,b'terrainWetness'),.7)
u3(loc(repeat,b'offset'),0,0,0);a=render(repeat)
for x,y in [(64,0),(0,64),(-64,-64)]:
 u3(loc(repeat,b'offset'),x,y,0);b=render(repeat)
 assert sum(abs(x-y) for x,y in zip(a[::4],b[::4]))/4096>.05,'repeated channel patch'
uf(loc(repeat,b'terrainWetness'),0)
assert max(render(repeat)[::4])==0,'dry terrain remains flooded'
print('PASS: old atlas offsets produce distinct channels; zero wetness is dry')

# Sample both sides of every shared row at positive and negative coordinates.
seams=program(vert,prefix+'''
uniform float side;
void main(){
 vec2 at=vec2((gl_FragCoord.x-32.0)*0.31,floor(gl_FragCoord.y)-32.0+side);
 vec3 path=terrainPath(at);
 gl_FragColor=vec4(path.x,fract(path.y),path.z,1);
}''')
use(seams);uf(loc(seams,b'side'),-0.00001);a=render(seams)
uf(loc(seams,b'side'),0.00001);b=render(seams)
for channel in (0,2):
 assert max(abs(x-y) for x,y in zip(a[channel::4],b[channel::4]))<.008,'disconnected shared ports'
print('PASS: randomized paths and widths join across 64 row boundaries, including negative cells')

# A geometric plane remains flat even with an exaggerated splat normal.
surface_test=program(vert,prefix+'''
uniform float incline;
uniform float elevation;
void main(){
 vec2 xz=(gl_FragCoord.xy-32.0)*0.5;
 vec3 p=vec3(xz.x,elevation+incline*xz.y,xz.y);
 gl_FragColor=terrainSurfaceWater(p,normalize(vec3(.8,1,.5)));
}''')
use(surface_test);uf(loc(surface_test,b'terrainWetness'),1)
uf(loc(surface_test,b'elevation'),40);uf(loc(surface_test,b'incline'),0)
a=render(surface_test)
assert max(a[::4])-min(a[::4])<.005,'flat terrain still shows channels'
assert max(a[1::4])==0,'flat film acquired channel relief'
uf(loc(surface_test,b'incline'),.65);b=render(surface_test)
assert max(b[::4])-min(b[::4])>.4,'bank missing channel pattern'
uf(loc(surface_test,b'elevation'),-40);c=render(surface_test)
assert max(c)==0,'underwater terrain still has channels'
print('PASS: flat geometry ignores splat slopes; banks carry channels; submerged terrain is rejected')

