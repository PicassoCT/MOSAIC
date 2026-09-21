"""Render production surface water on bright/dark floors and tilted roofs.
Optional --preview writes temporary synthetic shader renders, not engine captures.
"""
from world_rain_gpu import *
import sys
p=program(vert,prefix+'''
uniform vec3 testNormal;
uniform float testScale;
void main(){
 uv=gl_FragCoord.xy/64.0;
 vec2 xy=(gl_FragCoord.xy-32.0)*testScale;
 vec3 pos=vec3(xy.x,-dot(xy,testNormal.xz)/max(testNormal.y,0.01),xy.y);
 vertexNormal=testNormal*0.5+0.5;
 NormalIsWaterPuddle=testNormal.y>.99;
 vec4 wet=GetGroundReflectionRipples(pos);
 gl_FragColor=vec4(wet.rgb*wet.a+texture2D(screentex,uv).rgb*(1.0-wet.a)+runoffEnergy,1);
}
''')
use(p)
for slot,name in [(4,'screentex'),(5,'noisetex')]:
 t=U();gen(1,C.byref(t));textures.append(t)
 active(0x84C0+slot);bind(0x0DE1,t.value)
 param(0x0DE1,0x2801,0x2600);param(0x0DE1,0x2800,0x2600)
 ui(loc(p,name.encode()),slot)
texture(5,(1,1,1,1)) # isolate the actual surface treatment from SSR
u3(loc(p,b'eyePos'),0,30,20)
uf(loc(p,b'rainPercent'),1);uf(loc(p,b'rainLightActive'),0)
uf(loc(p,b'time'),1.7)
for label,background,sun,sky in [('day',.7,(.8,.7,.5),(.5,.6,.8)),('night',.12,(.02,.03,.05),(.08,.15,.4))]:
 texture(4,(background,background,background,1))
 u3(loc(p,b'sunCol'),*sun);u3(loc(p,b'skyCol'),*sky)
 for slope in [0,.2,1.5]:
  normal=(-slope/math.sqrt(1+slope*slope),1/math.sqrt(1+slope*slope),0)
  u3(loc(p,b'testNormal'),*normal)
  uf(loc(p,b'testScale'),.05 if slope==0 else .3)
  a=render(p)
  brightness=[sum(a[i:i+3])/3 for i in range(0,len(a),4)]
  contrast=max(brightness)-min(brightness)
  # Soft, interrupted ridges intentionally have lower contrast than closed cells.
  assert contrast>(.008 if slope==0 else .012),(label,slope,contrast)
  if slope==0: assert contrast<.15,("outlined/cartoon ripple contrast",label,contrast)
  if slope==0: assert min(brightness)<background,'missing dark wet substrate/trough'
  uf(loc(p,b'time'),1.9);b=render(p)
  assert a!=b,('static water',label,slope)
  uf(loc(p,b'time'),1.7)
  if '--preview' in sys.argv:
   from PIL import Image
   raw=bytes(round(max(0,min(1,x))*255) for x in a)
   im=Image.frombytes('RGBA',(64,64),raw).convert('RGB').transpose(Image.Transpose.FLIP_TOP_BOTTOM)
   im.resize((512,512),Image.Resampling.NEAREST).save('/tmp/rain-surface-'+label+'-'+str(slope)+'.png')
print('PASS: animated softly shaded rings and runoff on bright/day and dark/night surfaces, including steep roofs; no radiance required')

# Reversing the light must exchange raised/dark ridge faces, not just tint rings.
use(p)
texture(4,(.5,.5,.5,1))
u3(loc(p,b'testNormal'),0,1,0);uf(loc(p,b'testScale'),.05)
u3(loc(p,b'eyePos'),0,30,0)
u3(loc(p,b'sunCol'),.7,.7,.7);u3(loc(p,b'skyCol'),.3,.3,.3)
u3(loc(p,b'sunPos'),.8,.6,0);a=render(p)
u3(loc(p,b'sunPos'),-.8,.6,0);b=render(p)
delta=[a[i]-b[i] for i in range(0,len(a),4)]
assert max(delta)>.015 and min(delta)<-.015,('no directional ripple relief',min(delta),max(delta))
print('PASS: ripple light/dark faces reverse with illumination direction')

# Render the complete surface composition with/without the extra roof bead layer.
# A nonzero mask alone does not prove that a bead survives shading and blending.
body='''
uniform float testPixel;
void main(){
 uv=gl_FragCoord.xy/64.0;
 vec2 xz=(gl_FragCoord.xy-32.0)*testPixel;
 vec3 pos=vec3(xz.x,-xz.x*.4,xz.y);
 vertexNormal=normalize(vec3(.4,1,0))*.5+.5;
 NormalIsOnUnit=true;NormalIsWaterPuddle=false;
 vec4 wet=GetGroundReflectionRipples(pos);
 gl_FragColor=vec4(wet.rgb*wet.a+texture2D(screentex,uv).rgb*(1.0-wet.a)+runoffEnergy,1);
}
'''
without=prefix.replace('vec4 roofWaterBeads(', 'vec4 unusedRoofWaterBeads(').replace('return roofWaterBeads(', 'return unusedRoofWaterBeads(')
without=without.replace('vec4 GetGroundReflectionRipples(', 'vec4 roofWaterBeads(vec3 p,vec3 n,bool b){return vec4(0);}\nvec4 GetGroundReflectionRipples(')
bead_programs=[program(vert,without+body),program(vert,prefix+body)]
for background in [.12,.7]:
 texture(4,(background,background,background,1))
 for pixel in [.6,1.2,2.0]:
  frames=[]
  for q in bead_programs:
   use(q);ui(loc(q,b'screentex'),4);ui(loc(q,b'noisetex'),5)
   uf(loc(q,b'testPixel'),pixel);uf(loc(q,b'time'),1.7)
   u3(loc(q,b'eyePos'),0,30,20);u3(loc(q,b'sunPos'),.4,.8,.3)
   u3(loc(q,b'sunCol'),.1,.1,.1);u3(loc(q,b'skyCol'),.08,.16,.4)
   frames.append(render(q))
  delta=max(abs(a-b) for a,b in zip(*frames))
  assert delta>.003,('beads disappear in final composition',background,pixel,delta)
print('PASS: roof beads visibly affect final day/night composition at gameplay pixel footprints')
