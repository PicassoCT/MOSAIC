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
