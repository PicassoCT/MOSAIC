"""Production roof bead eligibility, animation and directional coverage."""
from world_rain_gpu import *
p=program(vert,prefix+'''
uniform vec3 testNormal;
uniform int building;
void main(){
 vec3 n=normalize(testNormal);
 vec3 down=vec3(0,-1,0)+n*n.y;
 if(dot(down,down)<0.00001)down=vec3(1,0,0);
 down=normalize(down);
 vec3 across=normalize(cross(n,down));
 vec2 xy=(gl_FragCoord.xy-32.0)*0.12;
 vec4 beads=roofWaterBeads(across*xy.x+down*xy.y,n,building!=0);
 gl_FragColor=vec4(abs(beads.xyz),beads.w);
}
''')
use(p);ui(loc(p,b'building'),1);uf(loc(p,b'time'),1.7)
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
