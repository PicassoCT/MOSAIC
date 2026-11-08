"""Production roof bead eligibility, animation and directional coverage."""
from world_rain_gpu import *
p=program(vert,prefix+'''
uniform vec3 testNormal;
uniform int building;
uniform float testPixel;
uniform float testHeight;
void main(){
 vec3 n=normalize(testNormal);
 vec3 down=vec3(0,-1,0)+n*n.y;
 if(dot(down,down)<0.00001)down=vec3(1,0,0);
 down=normalize(down);
 vec3 across=normalize(cross(n,down));
 vec2 xy=(gl_FragCoord.xy-32.0)*testPixel;
 vec4 beads=roofWaterBeads(across*xy.x+down*xy.y+vec3(0,testHeight,0),n,building!=0);
 gl_FragColor=vec4(abs(beads.xyz),beads.w);
}
''')
use(p);uf(loc(p,b'testHeight'),20);uf(loc(p,b'testPixel'),.12);ui(loc(p,b'building'),1);uf(loc(p,b'time'),1.7)
for n in [(0,1,0),(1,0,0)]:
 u3(loc(p,b'testNormal'),*n)
 assert max(render(p))==0,'beads outside roof runoff slopes'
for n in [(.4,1,0),(-.4,1,0),(0,1,.4),(0,1,-.4)]:
 u3(loc(p,b'testNormal'),*n)
 uf(loc(p,b'time'),1.7);a=render(p)
 assert max(a[3::4])>.1,('missing roof beads',n)
 assert any(max(a[i:i+3])>.01 for i in range(0,len(a),4)),'missing rounded normals'
 assert sum(v>.02 for v in a[3::4])<len(a[3::4])*.2,'continuous bead blanket'
 uf(loc(p,b'time'),2.0);b=render(p)
 assert a!=b,'beads not animated'
 ui(loc(p,b'building'),0);assert max(render(p))==0,'terrain beads'
 ui(loc(p,b'building'),1)
print('PASS: sparse rounded animated roof beads on four slope directions; absent on terrain, flat puddles and walls')

u3(loc(p,b'testNormal'),.4,1,0)
for pixel in [.6,1.2,2.0]:
 uf(loc(p,b'testPixel'),pixel)
 a=render(p)
 assert max(a[3::4])>.01,('gameplay bead coverage lost',pixel)
print('PASS: roof beads retain coverage at 0.6, 1.2 and 2.0 world units per pixel')

uf(loc(p,b'testHeight'),-100)
assert max(render(p))==0,'underwater roof runoff'
print('PASS: submerged building beads and wakes are fully clipped')

motion=program(vert,prefix+"""
void main(){float age=(gl_FragCoord.x-0.5)/63.0;float t=roofTravel(age);
gl_FragColor=vec4(t,t,t,1);}
""")
use(motion);values=render(motion)[0:64*4:4]
assert all(b>=a for a,b in zip(values,values[1:])), 'uphill reversal'
assert values[20]==0 and values[-1]>.99,'growth hold / complete travel'
assert sum(a==b for a,b in zip(values,values[1:]))>25,'missing pauses'
print('PASS: downhill travel is monotone with stationary intervals between bursts')

# A fixed camera over a dome catches projection transitions across one mesh.
dome=program(vert,prefix+"""
void main(){vec2 xz=(gl_FragCoord.xy-32.0)*0.2;
float y=sqrt(max(64.0-dot(xz,xz),0.001));vec3 n=normalize(vec3(xz.x,y,xz.y));
vec4 b=roofWaterBeads(vec3(xz.x,y+20.0,xz.y),n,true);
gl_FragColor=vec4(abs(b.xyz),b.w);}
""")
use(dome);sectors=[0.0]*8
for t in [0,1,2,3,4,5]:
 uf(loc(dome,b'time'),t);a=render(dome)
 for y in range(64):
  for x in range(64):
   dx=(x+.5-32)*.2;dz=(y+.5-32)*.2
   if 3<math.hypot(dx,dz)<6:
    sector=int((math.atan2(dz,dx)+math.pi)/(2*math.pi)*8)%8
    sectors[sector]=max(sectors[sector],a[(y*64+x)*4+3])
assert min(sectors)>.05,('dome projection dropout',sectors)
print('PASS: building water appears in all eight dome sectors over its cycle')
