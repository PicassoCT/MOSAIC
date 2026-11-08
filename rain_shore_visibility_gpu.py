"""Production rain composition must not paint deferred banks through water.
Run with Python + Mesa/EGL, no engine required. Orthographic world fixture uses
misleading splat normals, a bank, flat ground, and an independently nearer depth.
"""
from world_rain_gpu import *
p=program(vert,frag)
use(p)
u2=fn(G,'glUniform2f',None,I,F,F)
um=fn(G,'glUniformMatrix4fv',None,I,I,U,P)
for slot,name in enumerate(['normaltex','normalunittex','mapDepthTex','modelDepthTex','dephtCopyTex','screentex','noisetex']):
 if slot>=len(textures):
  t=U();gen(1,C.byref(t));textures.append(t)
  active(0x84C0+slot);bind(0x0DE1,t.value)
  param(0x0DE1,0x2801,0x2600);param(0x0DE1,0x2800,0x2600)
 ui(loc(p,name.encode()),slot)
u2(loc(p,b'viewPortSize'),64,64)
u3(loc(p,b'eyePos'),128,100,128)
u3(loc(p,b'sunCol'),.5,.4,.3);u3(loc(p,b'skyCol'),.2,.3,.5)
u3(loc(p,b'sunPos'),.4,.8,.3)
uf(loc(p,b'rainPercent'),0);uf(loc(p,b'terrainWetness'),1)
uf(loc(p,b'time'),1.7);uf(loc(p,b'terrainFlowTime'),1.7)
texture(0,(.9,.6,.5,0));texture(1,empty);texture(3,(1,0,0,0))
texture(5,(.3,.3,.3,1));texture(6,(1,1,1,1))
def depth_texture(slot,values):
 active(0x84C0+slot);bind(0x0DE1,textures[slot].value)
 data=[v for d in values for v in (d,0,0,0)]
 upload(0x0DE1,0,0x8814,64,64,0,0x1908,0x1406,(F*len(data))(*data))
def matrix(clip):
 rows=[[16,0,0,128],[0,0,-100,100],[0,16,0,128],[0,0,0,1]]
 if not clip: rows=[[r[0],r[1],r[2]*.5,r[3]+r[2]*.5] for r in rows]
 values=[rows[r][c] for c in range(4) for r in range(4)]
 um(loc(p,b'viewProjectionInv'),1,0,(F*16)(*values))
 uf(loc(p,b'clipZeroToOne'),clip)
for clip in [0,1]:
 matrix(clip)
 for slope in [0,.2,1.5]:
  depths=[.5+slope*((x+.5)/64*2-1)*.16 for y in range(64) for x in range(64)]
  depth_texture(2,depths);depth_texture(4,depths)
  visible=render(p)
  assert max(visible[3::4])>.01,('visible water lost',clip,slope)
  # Move only copied scene depth forward: deferred terrain stays above sea level.
  depth_texture(4,[d-.1 for d in depths])
  hidden=render(p)
  assert max(abs(v) for v in hidden)<1e-6,('hidden bank leaked',clip,slope,max(hidden))
  # Crossing a water/land boundary must neither leak nor change the land side.
  depth_texture(4,[d-.1 if i%64<32 else d for i,d in enumerate(depths)])
  edge=render(p)
  for y in range(64):
   for x in range(64):
    i=(y*64+x)*4
    expected=[0]*4 if x<32 else visible[i:i+4]
    assert max(abs(a-b) for a,b in zip(edge[i:i+4],expected))<1e-5,('shore edge',clip,slope,x,y)
 # Even if copied depth does not contain water, submerged terrain contributes zero.
 texture(2,(.999,0,0,0));texture(4,(.999,0,0,0))
 # y=.1 still fades in; actual below-sea case uses a translated inverse matrix.
 rows=[[16,0,0,128],[0,0,-100,50],[0,16,0,128],[0,0,0,1]]
 if not clip: rows=[[r[0],r[1],r[2]*.5,r[3]+r[2]*.5] for r in rows]
 um(loc(p,b'viewProjectionInv'),1,0,(F*16)(*[rows[r][c] for c in range(4) for r in range(4)]))
 assert max(abs(v) for v in render(p))<1e-6,'submerged rings/energy'
print('PASS: full production rain pass rejects hidden/submerged surfaces; shoreline mask preserves visible banks and pools, both depth conventions')
