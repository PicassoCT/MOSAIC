"""A depth step is not a reflecting wall; a continuous plane remains a valid hit."""
from world_rain_gpu import *
u2=fn(G,'glUniform2f',None,I,F,F)
um=fn(G,'glUniformMatrix4fv',None,I,I,U,P)
p=program(vert,prefix+'''
void main(){gl_FragColor=rayMarchForReflection(vec3(-40,0,-50),normalize(vec3(1,0,-0.1)));}
''')
use(p)
def mat(name,rows):
 um(loc(p,name),1,0,(F*16)(*[rows[r][c] for c in range(4) for r in range(4)]))
mat(b'viewProjection',[[.01,0,0,0],[0,.01,0,0],[0,0,-.01,0],[0,0,0,1]])
mat(b'viewProjectionInv',[[100,0,0,0],[0,100,0,0],[0,0,-100,0],[0,0,0,1]])
mat(b'viewMatrix',[[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]])
uf(loc(p,b'clipZeroToOne'),0)
u2(loc(p,b'viewPortSize'),64,64)
ui(loc(p,b'dephtCopyTex'),2);ui(loc(p,b'screentex'),0)
texture(0,(1,.5,.2,1))
def depths(values):
 active(0x84C0+2);bind(0x0DE1,textures[2].value)
 data=[v for d in values for v in ((d/100+1)*.5,0,0,0)]
 upload(0x0DE1,0,0x8814,64,64,0,0x1908,0x1406,(F*len(data))(*data))
# The ray never touches either plane: its apparent crossing is a 4-unit jump.
depths([56 if x<32 else 52 for y in range(64) for x in range(64)])
a=render(p)
print('discontinuous hit alpha:',max(a[3::4]))
assert max(a[3::4])==0,'depth-edge false reflection accepted'
# The same ray really intersects an unbroken plane at depth 56.
depths([56]*4096);b=render(p)
assert max(b[3::4])>.9,'valid planar reflection lost'
print('PASS: false depth-edge hit rejected; continuous plane still reflected')

# Quantized samples of a continuous tilted plane must not be confused with a
# silhouette step. This is the ordinary nearest-filtered depth-buffer case.
for slope in [.03,.06,-.03]:
 depths([56+slope*((x+.5)/64*200-100) for y in range(64) for x in range(64)])
 assert max(render(p)[3::4])>.5,('valid tilted reflection lost',slope)
print('PASS: continuous tilted planes survive depth quantization')
