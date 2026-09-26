"""Check the shore fade in the complete rain pass, not only its scalar mask.
Run python tests/rain_shore_cutoff_gpu.py (Mesa EGL + Pillow).
"""
from rain_shore_visibility_gpu import *

# The only reference change removes the proposed handover, leaving master's
# channel shapes, material response and existing visibility clipping intact.
rule='return smoothstep(TERRAIN_SHORE_CLEAR_HEIGHT,TERRAIN_SHORE_FULL_HEIGHT,height);'
assert frag.count(rule)==1
reference=program(vert,frag.replace(rule,'return 1.0;'))
production=p

# Retain bright additive highlights until the final straight-alpha composite.
fbo=U();fn(G,'glGenFramebuffers',None,I,P)(1,C.byref(fbo))
fn(G,'glBindFramebuffer',None,U,U)(0x8D40,fbo.value)
out=U();gen(1,C.byref(out));active(0x84C0+15);bind(0x0DE1,out.value)
param(0x0DE1,0x2801,0x2600);param(0x0DE1,0x2800,0x2600)
upload(0x0DE1,0,0x881A,64,64,0,0x1908,0x1406,None)
fn(G,'glFramebufferTexture2D',None,U,U,U,U,I)(0x8D40,0x8CE0,0x0DE1,out.value,0)
assert fn(G,'glCheckFramebufferStatus',U,U)(0x8D40)==0x8CD5

for shader in [production,reference]:
 use(shader)
 for slot,name in enumerate(['normaltex','normalunittex','mapDepthTex','modelDepthTex','dephtCopyTex','screentex','noisetex']):
  ui(loc(shader,name.encode()),slot)
 u2(loc(shader,b'viewPortSize'),64,64)
 u3(loc(shader,b'eyePos'),128,100,128)
 u3(loc(shader,b'sunCol'),.5,.4,.3);u3(loc(shader,b'skyCol'),.2,.3,.5)
 u3(loc(shader,b'sunPos'),.4,.8,.3)
 uf(loc(shader,b'time'),1.7);uf(loc(shader,b'terrainFlowTime'),1.7)

def scene(clip,centre,slope,building=False):
 heights=[centre+slope*((x+.5)/64*32-16) for y in range(64) for x in range(64)]
 depths=[(50-h)/200 for h in heights]
 depth_texture(2,[d+.1 if building else d for d in depths])
 depth_texture(3,depths if building else [1]*4096)
 depth_texture(4,depths)
 texture(1,(.9,.6,.5,0) if building else empty)
 rows=[[16,0,0,128],[0,0,-200,50],[0,16,0,128],[0,0,0,1]]
 if not clip: rows=[[r[0],r[1],r[2]*.5,r[3]+r[2]*.5] for r in rows]
 values=(F*16)(*[rows[r][c] for c in range(4) for r in range(4)])
 for shader in [production,reference]:
  use(shader);um(loc(shader,b'viewProjectionInv'),1,0,values)
  uf(loc(shader,b'clipZeroToOne'),clip)
 return heights

def fade(height):
 t=max(0,min(1,(height-2)/6))
 return t*t*(3-2*t)

visible_inner=visible_outer=0
for clip in [0,1]:
 for wetness in [.3,1]:
  for shader in [production,reference]:
   use(shader);uf(loc(shader,b'rainPercent'),0)
   uf(loc(shader,b'terrainWetness'),wetness);uf(loc(shader,b'rainDetailDebug'),0)
  for slope in [0,.2,1.5]:
   for height in [-2,0,1,2,3,5,8,12,32]:
    heights=scene(clip,height,slope)
    old=render(reference);new=render(production)
    for j,h in enumerate(heights):
     i=j*4;mask=fade(h)
     assert abs(new[i+3]-old[i+3]*mask)<.001,('alpha',clip,slope,h)
     for c in range(3):
      assert abs(new[i+c]*new[i+3]-old[i+c]*old[i+3]*mask)<.003,('glint/foam leak or new rim',clip,slope,h)
     if h<=2:
      assert max(abs(v) for v in new[i:i+4])<1e-6,('inner surf band',h)
      visible_inner+=old[i+3]>.001
     if h>=8 and old[i+3]>.001: visible_outer+=1
assert visible_inner>100 and visible_outer>100,'vacuous cutoff comparison'
print('PASS: full production alpha, glints and foam fade together; no new rim, clear below 2 and unchanged above 8, both clip conventions')

# The diagnostic follows the same shore mask.
heights=scene(1,4,.2)
for shader in [production,reference]:
 use(shader);uf(loc(shader,b'rainDetailDebug'),2)
old=render(reference);new=render(production)
assert max(old[::4])>.05
for j,h in enumerate(heights):
 assert abs(new[j*4]-old[j*4]*fade(h))<.001

# Even low roofs retain their existing response, with real rain enabled.
roof_visible=0
for shader in [production,reference]:
 use(shader);uf(loc(shader,b'rainPercent'),1);uf(loc(shader,b'rainDetailDebug'),0)
for clip in [0,1]:
 for slope in [0,.2,1.5]:
  for height in [1,4,16]:
   scene(clip,height,slope,True)
   old=render(reference);new=render(production)
   assert max(abs(a-b) for a,b in zip(old,new))<.002,('roof/precipitation changed',clip,slope,height)
   roof_visible+=max(old[3::4])>.01
assert roof_visible>0
print('PASS: runoff diagnostic shares the fade; low roofs and precipitation keep their original composition')
