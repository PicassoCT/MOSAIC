"""Complete shader: curved bank, sea plane, and a foreground building."""
from rain_shore_visibility_gpu import *
import math
rows=[[16,0,0,128],[0,0,-50,25],[0,16,0,128],[0,0,0,1]]
um(loc(p,b'viewProjectionInv'),1,0,(F*16)(*[rows[r][c] for c in range(4) for r in range(4)]))
uf(loc(p,b'clipZeroToOne'),1)
heights=[6-.65*((x+.5)*.5-16)+2*math.sin(((y+.5)*.5-16)/4) for y in range(64) for x in range(64)]
terrain=[(25-h)/50 for h in heights]
building=[.08 if 20<x<35 and 38<y<53 else 1 for y in range(64) for x in range(64)]
visible=[min(a,b,.5) for a,b in zip(terrain,building)]
depth_texture(2,terrain);depth_texture(3,building);depth_texture(4,visible)
texture(1,(.5,1,.5,0))
frames=[]
for mode in [0,1,2,3]:
 uf(loc(p,b'rainIsolation'),mode)
 a=render(p);frames.append(a)
 assert all(math.isfinite(v) for v in a),'nonfinite shoreline fragment'
 for j,h in enumerate(heights):
  if h<=2 and building[j]==1:
   assert max(abs(v) for v in a[j*4:j*4+4])<1e-6,'surface contribution leaked into surf/water'
 assert max(a[3::4])>.1,'curved bank/building vanished'
assert sum(abs(a-b) for a,b in zip(frames[0],frames[2]))>.1,'relief isolation had no effect'
assert sum(abs(a-b) for a,b in zip(frames[0],frames[3]))>.1,'foam isolation had no effect'
print('PASS: curved bank + sea + building remain finite and clipped; relief and foam can be isolated independently')
