"""Terrain relief must be independent of a neighbouring surface's height."""
from world_rain_gpu import *
p=program(vert,prefix+'''
uniform float edge;
uniform float shift;
void main(){
 vec2 xz=(gl_FragCoord.xy-32.0)*.3;
 vec3 n=normalize(vec3(-.6,1,0));
 vec3 p=vec3(128+xz.x,30+xz.x*.6+(gl_FragCoord.y>edge ? shift : 0.0),128+xz.y);
 float height=terrainReliefAt(p,n,.3);
 vec3 g=terrainReliefGradient(p,n,height,.3);
 gl_FragColor=vec4(g*1.5+.5,1);
}
''')
use(p);uf(loc(p,b'terrainWetness'),1);uf(loc(p,b'terrainFlowTime'),1.7)
uf(loc(p,b'edge'),100);uf(loc(p,b'shift'),0);low=render(p)
uf(loc(p,b'edge'),-1);uf(loc(p,b'shift'),40);high=render(p)
# Odd pixel row deliberately splits a derivative quad across the discontinuity.
uf(loc(p,b'edge'),31);joined=render(p)
for y in range(64):
 reference=high if y+.5>31 else low
 for x in range(64):
  i=(y*64+x)*4
  assert max(abs(a-b) for a,b in zip(joined[i:i+4],reference[i:i+4]))<.005,(x,y,'neighbour surface changed relief')
assert max(low[::4])-min(low[::4])>.01,'test failed to exercise curved water normals'
print('PASS: relief normals unchanged beside a 40-unit depth break; rounded water profile remains visible')
