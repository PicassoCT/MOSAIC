"""Actual depth-derived drainage normals, including misleading material normals."""
from world_rain_gpu import *
p=program(vert,prefix+'''
void main(){
 vec2 at=gl_FragCoord.xy/viewPortSize;
 bool g,u,w,s;
 vec3 encoded=GetGroundVertexNormal(at,g,u,w,s);
 vec3 n=rainGeometryNormal(at,u,normalize(encoded*2.0-1.0));
 vec2 water=surfaceWaterWeights(n.y);
 gl_FragColor=vec4(n*0.5+0.5,water.x*(1.0-water.y));
}
''')
use(p)
u2=fn(G,'glUniform2f',None,I,F,F)
um=fn(G,'glUniformMatrix4fv',None,I,I,U,P)
for slot,name in enumerate(['normaltex','normalunittex','mapDepthTex','modelDepthTex']):
 ui(loc(p,name.encode()),slot)
u2(loc(p,b'viewPortSize'),64,64)
u3(loc(p,b'eyePos'),128,50,128)
def matrix(rows):
 values=[rows[r][c] for c in range(4) for r in range(4)]
 um(loc(p,b'viewProjectionInv'),1,0,(F*16)(*values))
def depth_texture(slot,values):
 active(0x84C0+slot);bind(0x0DE1,textures[slot].value)
 data=[v for d in values for v in (d,0,0,0)]
 upload(0x0DE1,0,0x8814,64,64,0,0x1908,0x1406,(F*len(data))(*data))
wrong=(.9,.6,.5,0) # intentionally unsuitable shading normal, alpha zero
for perspective in [False,True]:
 for clip in [0,1]:
  uf(loc(p,b'clipZeroToOne'),clip)
  if perspective:
   rows=[[.16,0,-128,128],[0,0,-50,49],[0,.16,-128,128],[0,0,-1,1]]
  else:
   rows=[[8,0,0,128],[0,0,-100,50],[0,8,0,128],[0,0,0,1]]
  if not clip: # substitute depth=(ndc+1)/2 in inverse projection
   rows=[[r[0],r[1],r[2]*.5,r[3]+r[2]*.5] for r in rows]
  matrix(rows)
  for slope in [0,.2,1.5,6]:
   depths=[]
   for y in range(64):
    for x in range(64):
     sx=(x+.5)/64*2-1
     depths.append(1-(1+slope*sx/6.25)/50 if perspective else .5-slope*sx*8/100)
   expected=(-slope/math.sqrt(1+slope*slope),1/math.sqrt(1+slope*slope),0)
   renders=[]
   for unit in [False,True]:
    texture(0,empty if unit else wrong);texture(1,wrong if unit else empty)
    texture(3 if not unit else 2,(1,0,0,0))
    depth_texture(3 if unit else 2,depths)
    pixels=render(p);renders.append(pixels)
    for y in range(1,63):
     for x in range(1,63):
      i=(y*64+x)*4
      assert max(abs(pixels[i+c]*2-1-expected[c]) for c in range(3))<.012,(perspective,clip,slope,x,y,pixels[i:i+4])
      if slope==0: assert pixels[i+3]==0,'runoff on flat geometry'
      else: assert pixels[i+3]>.04,'runoff missing on bank'
   assert renders[0]==renders[1],'map/model drainage mismatch'
# A roof silhouette next to ground must not manufacture a sloped runoff edge.
uf(loc(p,b'clipZeroToOne'),1)
matrix([[8,0,0,128],[0,0,-100,50],[0,8,0,128],[0,0,0,1]])
texture(0,wrong);texture(1,wrong);texture(2,(.5,0,0,0))
depth_texture(3,[1 if x<32 else .42 for y in range(64) for x in range(64)])
a=render(p)
assert all(v==0 for v in a[3::4]),'silhouette created false slope'
# Unavailable geometry depth keeps the populated legacy normal path alive.
texture(0,up);texture(1,empty);texture(2,(1,0,0,0))
a=render(p)
assert max(abs(a[i]-[.5,1,.5,0][i]) for i in range(4))<.005
print('PASS: identical map/model geometry normals; flat roof vs shallow/steep banks despite incorrect shading normals; perspective/orthographic, both clip conventions, silhouettes, missing-depth fallback')
