"""Channel-derived shading and actual airborne shoreline spray."""
from world_rain_gpu import *
p=program(vert,prefix+'''
uniform vec3 traits;
void main(){vec2 r=terrainFlowRegime(vec4(traits,1),terrainWetness);gl_FragColor=vec4(r,0,1);}
''')
use(p);uf(loc(p,b'terrainWetness'),1)
u3(loc(p,b'traits'),.6,0,1);fine=render(p)
u3(loc(p,b'traits'),3,1,.7);rough=render(p)
assert fine[1]==0 and rough[1]>.9 and rough[0]==0
uf(loc(p,b'terrainWetness'),0);assert render(p)[1]==0
query=program(vert,prefix+'''
uniform float altitude;
uniform float slope;
void main(){vec3 n=normalize(vec3(slope,1,0));
 vec3 p=vec3(gl_FragCoord.x*2,altitude,gl_FragCoord.y*2);
 gl_FragColor=vec4(terrainRunoffSpray(p,n));}
''')
use(query);uf(loc(query,b'terrainWetness'),1);uf(loc(query,b'slope'),.6);uf(loc(query,b'altitude'),4)
assert max(render(query))>.05,'no confluence shoreline sources'
for height in [-2,1,2,20]:
 uf(loc(query,b'altitude'),height);assert max(render(query))==0,'spray without impact cue'
uf(loc(query,b'altitude'),4);uf(loc(query,b'slope'),0)
assert max(render(query))==0,'flat ground spray'
print('PASS: fine tributaries stay clear; strong constriction foams and suppresses crests; spray requires shoreline impact')

p=program(vert,prefix.replace('uniform vec3 eyePos;', 'vec3 eyePos;')+'''
void main(){uv=gl_FragCoord.xy/viewPortSize;
 depthAtPixel=texture2D(dephtCopyTex,uv);
 vec3 surface=GetWorldPosAtUV(uv,texture2D(mapDepthTex,uv).r);
 eyePos=surface+vec3(0,50,0);
 bool g,u,w,s;vec3 n=GetGroundVertexNormal(uv,g,u,w,s);
 gl_FragColor=drawRunoffSpray(surface,n,vec3(0,-1,0),50,g);
}
''')
use(p)
u2=fn(G,'glUniform2f',None,I,F,F);um=fn(G,'glUniformMatrix4fv',None,I,I,U,P)
def mat(name,rows):
 um(loc(p,name.encode()),1,0,(F*16)(*[rows[r][c] for c in range(4) for r in range(4)]))
for slot,name in enumerate(['normaltex','normalunittex','mapDepthTex','modelDepthTex','dephtCopyTex']):
 if slot>=len(textures):
  t=U();gen(1,C.byref(t));textures.append(t)
  active(0x84C0+slot);bind(0x0DE1,t.value)
  param(0x0DE1,0x2801,0x2600);param(0x0DE1,0x2800,0x2600)
 ui(loc(p,name.encode()),slot)
n=(-.6/math.sqrt(1.36),1/math.sqrt(1.36),0)
texture(0,tuple(v*.5+.5 for v in n)+(0,));texture(1,empty);texture(3,(1,0,0,0))
u2(loc(p,b'viewPortSize'),64,64);uf(loc(p,b'clipZeroToOne'),1);uf(loc(p,b'terrainWetness'),1)
u3(loc(p,b'sunCol'),.6,.6,.6);u3(loc(p,b'skyCol'),.2,.3,.4)
# Orthographic camera over a shore bank; copied scene depth agrees with ground.
mat('viewProjection',[[1/8,0,0,-16],[0,0,1/8,-16],[0,-.01,0,.5],[0,0,0,1]])
mat('viewProjectionInv',[[8,0,0,128],[0,0,-100,50],[0,8,0,128],[0,0,0,1]])
depths=[]
for y in range(64):
 for x in range(64):
  h=3+.6*((x+.5)/64*16-8);depths.extend((.5-h*.01,0,0,0))
for slot in [2,4]:
 active(0x84C0+slot);bind(0x0DE1,textures[slot].value)
 upload(0x0DE1,0,0x8814,64,64,0,0x1908,0x1406,(F*len(depths))(*depths))
frames=[]
# Search several fixed coastline stretches: most locations are deliberately
# not confluences, so a single arbitrary camera need not contain an emitter.
for centreZ in [16,32,48,64,80,96,112,128,144,160,176,192,208,224,240]:
 mat('viewProjection',[[1/8,0,0,-16],[0,0,1/8,-centreZ/8],[0,-.01,0,.5],[0,0,0,1]])
 mat('viewProjectionInv',[[8,0,0,128],[0,0,-100,50],[0,8,0,centreZ],[0,0,0,1]])
 frames=[]
 for t in [0,.15,.3,.45,.6,.75,.9]:
  uf(loc(p,b'terrainFlowTime'),t);frames.append(render(p))
 if max(max(a[3::4]) for a in frames)>0:break
assert max(max(a[3::4]) for a in frames)>0,'no airborne spray rendered'
assert any(a!=frames[0] for a in frames[1:]),'spray does not animate'
assert all(math.isfinite(v) for a in frames for v in a)
uf(loc(p,b'terrainWetness'),.4);assert max(render(p)[3::4])==0,'light rain spray'
uf(loc(p,b'terrainWetness'),1);texture(4,(.1,0,0,0))
assert max(render(p)[3::4])==0,'spray emitted through hidden source'
print('PASS: actual ballistic shoreline droplets render, animate, and reject weak flow and hidden sources')
chart=program(vert,prefix+'''
void main(){gl_FragColor=terrainChartWater(gl_FragCoord.xy*2.0,.1);}
''')
use(chart);uf(loc(chart,b'terrainWetness'),1)
uf(loc(chart,b'terrainFlowTime'),0);a=render(chart)
uf(loc(chart,b'terrainFlowTime'),.7);b=render(chart)
assert max(a[2::4])>.05,'topology never produces foam'
assert a[::4]==b[::4],'foam animation changed channel coverage'
assert a[2::4]!=b[2::4],'foam is static'
uf(loc(chart,b'terrainWetness'),.3)
assert max(render(chart)[2::4])==0,'low-flow channels foam'
print('PASS: real channel topology produces moving foam without changing coverage; light flow remains clear')
