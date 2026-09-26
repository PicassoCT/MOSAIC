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

# Sample the shipped repeating field, including both repeat boundaries.
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
 assert max(abs(x-y) for x,y in zip(a,b))<.005,'nonperiodic bank or crest data'
uf(loc(repeat,b'terrainWetness'),0)
assert max(render(repeat)[::4])==0,'dry terrain remains flooded'
print('PASS: bank/depth/crest data repeat across both atlas boundaries; zero wetness is dry')
