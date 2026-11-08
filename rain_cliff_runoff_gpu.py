"""Fine cliff drainage: stable wet paths, moving crests and smooth terrain normals."""
from world_rain_gpu import *
p=program(vert,prefix+'''
uniform float phase;
uniform float wet;
uniform float offset;
uniform float stepHeight;
void main(){
 vec2 at=(gl_FragCoord.xy-32.0)*0.12+vec2(offset,50.0);
 at.y+=gl_FragCoord.y>31.0 ? stepHeight : 0.0;
 vec2 gradient;
 vec4 water=terrainCliffChart(at,0.12,gradient);
 gl_FragColor=vec4(water.x,water.y,gradient*0.5+0.5);
}
''')
use(p)
frames=[]
for wet in [0,.25,.6,1]:
 uf(loc(p,b'terrainWetness'),wet);uf(loc(p,b'terrainFlowTime'),30)
 a=render(p);frames.append(a)
 assert all(math.isfinite(v) for v in a)
 if wet==0:assert max(a[::4])==0 and max(a[1::4])==0,'dry cliffs must stay dry'
 else:assert .02<sum(a[::4])/4096<.8,'fine channels missing or flooding whole face'
for low,high in zip(frames,frames[1:]):
 assert all(b>=a-.00001 for a,b in zip(low[::4],high[::4])),'rain moved/dried established channels'
uf(loc(p,b'terrainFlowTime'),30.3);moving=render(p)
assert max(abs(a-b) for a,b in zip(frames[-1][::4],moving[::4]))<.00001,'channel bed moves with crests'
assert sum(abs(a-b) for a,b in zip(frames[-1][1::4],moving[1::4]))>1,'crests do not move'
uf(loc(p,b'offset'),128);shifted=render(p)
assert sum(abs(a-b) for a,b in zip(moving[::4],shifted[::4]))>100,'periodic tiled channel field'
# An unrelated surface in the neighbouring derivative quad cannot change relief.
uf(loc(p,b'stepHeight'),40);joined=render(p)
for y in range(31):
 for x in range(64):
  i=(y*64+x)*4
  assert max(abs(a-b)for a,b in zip(joined[i:i+4],shifted[i:i+4]))<.00001
print('PASS: fine world-seeded channels, dry/wet nesting, travelling crests, nonrepeating field and silhouette-independent relief')
# Engine ground normals must win over both material bump and mesh triangulation.
p=program(vert,prefix+'''
void main(){vec3 n=rainGeometryNormal(vec2(.5),false,vec3(1,0,0));gl_FragColor=vec4(n*.5+.5,1);}
''')
use(p);u2=fn(G,'glUniform2f',None,I,F,F)
um=fn(G,'glUniformMatrix4fv',None,I,I,U,P)
um(loc(p,b'viewProjectionInv'),1,0,(F*16)(1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1))
u2(loc(p,b'terrainNormalScale'),1/8192,1/8192)
ui(loc(p,b'terrainNormalTex'),0)
texture(0,(-.6,0,0,.0))
ui(loc(p,b'mapDepthTex'),1);texture(1,(.5,0,0,0))
a=render(p)
assert max(abs(a[i]-[.2,.9,.5,1][i])for i in range(4))<.005,'smooth geometric normal not used'
print('PASS: unperturbed terrain normal texture supplies drainage direction independently of shading normals')

texture(1,(1,0,0,0));a=render(p)
assert max(abs(a[i]-[1,.5,.5,1][i])for i in range(4))<.005,'missing depth lost the normal fallback'
print('PASS: missing deferred depth retains the populated shading-normal fallback')
