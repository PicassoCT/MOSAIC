"""Runoff coverage across compass directions, materials and varying normals."""
from world_rain_gpu import *
p=program(vert,prefix+'''
uniform float heading;
uniform float normalVariation;
uniform float worldOffset;
uniform int building;
void main(){
 vec2 xy=(gl_FragCoord.xy-32.0)*0.12;
 vec3 n=normalize(vec3(-0.4,1,0));
 vec3 down=normalize(vec3(0,-1,0)+n*n.y);
 vec3 across=normalize(cross(n,down));
 vec3 pos=across*xy.x+down*xy.y;
 n=normalize(n+vec3(sin(xy.x*2.0)*normalVariation,0,cos(xy.y*2.0)*normalVariation));
 mat3 turn=mat3(cos(heading),0,-sin(heading),0,1,0,sin(heading),0,cos(heading));
 float r=getSurfaceRivulets(turn*pos+vec3(worldOffset,0,worldOffset),turn*n,building!=0);
 gl_FragColor=vec4(r,r,r,1);
}
''')
use(p);uf(loc(p,b'time'),1.7)
patterns=[]
for building in [0,1]:
 ui(loc(p,b'building'),building)
 frames=[]
 for heading in [0,math.pi/2,math.pi,3*math.pi/2]:
  uf(loc(p,b'heading'),heading)
  uf(loc(p,b'worldOffset'),0);uf(loc(p,b'normalVariation'),0)
  a=render(p);frames.append(a)
  assert sum(v>.05 for v in a[::4])>100,('direction missing',building,heading)
  assert max(abs(x-y) for x,y in zip(frames[0],a))<.012,('compass-dependent pattern',building,heading)
  # Curved normals far from map origin must not trigger an all-dry pixel filter.
  uf(loc(p,b'worldOffset'),7492);uf(loc(p,b'normalVariation'),.02)
  a=render(p)
  assert sum(v>.05 for v in a[::4])>100,('varying normal dropout',building,heading)
 patterns.append(frames[0])
assert sum(abs(a-b)>.1 for a,b in zip(patterns[0][::4],patterns[1][::4]))>400,'building/terrain patterns identical'
print('PASS: all four compass directions match; building lanes differ from terrain Voronoi; curved normals at map coordinates retain coverage')

# A fixed camera looking at a dome exercises changing normals across one mesh.
# Rotating a plane/camera together cannot catch a collapsing tangent projection.
dome=program(vert,prefix+'''
uniform int building;
void main(){
 vec2 xz=(gl_FragCoord.xy-32.0)*0.2;
 float y=sqrt(max(64.0-dot(xz,xz),0.001));
 vec3 pos=vec3(xz.x,y,xz.y),n=normalize(pos);
 // Terrain channels are four times broader: sample a correspondingly larger dome.
 float r=getSurfaceRivulets(pos*(building!=0 ? 1.0 : 4.0),n,building!=0);
 gl_FragColor=vec4(r,r,r,1);
}
''')
for building in [0,1]:
 use(dome);ui(loc(dome,b'building'),building);uf(loc(dome,b'time'),1.7)
 a=render(dome);sectors=[[] for _ in range(8)]
 for y in range(64):
  for x in range(64):
   dx=(x+.5-32)*.2;dz=(y+.5-32)*.2
   if 3<math.hypot(dx,dz)<6:
    sector=int((math.atan2(dz,dx)+math.pi)/(2*math.pi)*8)%8
    sectors[sector].append(a[(y*64+x)*4])
 for i,values in enumerate(sectors):
  assert max(values)>.1 and max(values)-min(values)>.1,('collapsed dome channels',building,i)
print('PASS: fixed-camera dome has resolved channels in all eight azimuth sectors')

# Existing channel pixels remain wet between gently varying swells.
use(p);uf(loc(p,b'heading'),0);uf(loc(p,b'worldOffset'),0);uf(loc(p,b'normalVariation'),0)
for building in [0,1]:
 ui(loc(p,b'building'),building)
 frames=[]
 for tick in range(12):
  uf(loc(p,b'time'),tick*.37);frames.append(render(p)[::4])
 for samples in zip(*frames):
  if max(samples)>.1:
   assert min(samples)>=(.92 if building else .72)*max(samples)-.008,'channel blinks between swells'
print('PASS: runoff stays continuously visible through its animation cycle')
