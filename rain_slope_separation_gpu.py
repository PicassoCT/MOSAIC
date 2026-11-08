"""Flat rain impacts must not inherit the expanding terrain channel atlas."""
from world_rain_gpu import *
# Relief height (Y) stays unmasked for same-surface gradients; coverage, foam
# and depth must be zero where water is ineligible.
p=program(vert,prefix+'''
uniform float slope;
uniform float altitude;
void main(){
 vec3 n=normalize(vec3(slope,1,0));
 vec3 p=vec3(gl_FragCoord.x*.25,altitude-gl_FragCoord.x*.25*slope,gl_FragCoord.y*.25);
 gl_FragColor=terrainSurfaceWater(p,n);
}
''')
use(p);uf(loc(p,b'altitude'),100)
for wet in [.1,.5,1]:
 uf(loc(p,b'terrainWetness'),wet);uf(loc(p,b'slope'),0)
 a=render(p)
 assert max(abs(v) for i,v in enumerate(a) if i%4!=1)==0,'channel atlas visible on level ground'
for slope in [.2,.7,1.5]:
 uf(loc(p,b'slope'),slope);previous=None;coverage=[]
 for wet in [i/10 for i in range(1,11)]:
  uf(loc(p,b'terrainWetness'),wet);a=render(p)[::4]
  if previous is not None:assert all(x<=y+1e-6 for x,y in zip(previous,a)),'flooding shrank'
  previous=a;coverage.append(sum(a))
 assert coverage[-1]>coverage[0],'lost flooding expansion'
uf(loc(p,b'altitude'),-1)
a=render(p)
assert max(abs(v) for i,v in enumerate(a) if i%4!=1)==0,'submerged terrain runoff'
print('PASS: no channel atlas on flat/submerged ground; flooding still expands on shallow and steep banks')
