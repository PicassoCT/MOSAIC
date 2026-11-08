"""Production wet-film eligibility and final building-water shading."""
from world_rain_gpu import *
import sys
film=program(vert,prefix+'''
uniform int building;
uniform float height;
void main(){vec3 p=vec3(gl_FragCoord.x,height,gl_FragCoord.y);
 float f=roofWetFilm(p,normalize(vec3(.4,1,0)),building!=0);
 gl_FragColor=vec4(f);}
''')
use(film);ui(loc(film,b'building'),1);uf(loc(film,b'height'),20)
uf(loc(film,b'rainPercent'),0);assert max(render(film))==0
uf(loc(film,b'rainPercent'),1);a=render(film)
assert 0<min(a)<max(a)<.23, 'film should be connected, subtle and varied'
ui(loc(film,b'building'),0);assert max(render(film))==0
ui(loc(film,b'building'),1);uf(loc(film,b'height'),-1);assert max(render(film))==0
print('PASS: faint continuous film only on eligible above-water buildings in rain')

p=program(vert,prefix+'''
void main(){uv=gl_FragCoord.xy/64.0;
 vec2 xz=(gl_FragCoord.xy-32.0)*.18;
 vec3 pos=vec3(xz.x,20.0-xz.x*.4,xz.y);
 vertexNormal=normalize(vec3(.4,1,0))*.5+.5;
 NormalIsOnUnit=true;NormalIsWaterPuddle=false;
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
texture(5,(1,1,1,1))
uf(loc(p,b'rainPercent'),1);uf(loc(p,b'time'),30)
u3(loc(p,b'eyePos'),0,50,20);u3(loc(p,b'sunPos'),.4,.8,.3)
for label,background,sun,sky in [('day',.5,(1,.94,.59),(.6,.56,.4)),('night',.12,(.02,.03,.05),(.08,.15,.4))]:
 texture(4,(background,background,background,1))
 u3(loc(p,b'sunCol'),*sun);u3(loc(p,b'skyCol'),*sky)
 a=render(p)
 assert all(math.isfinite(v) for v in a)
 brightness=[sum(a[i:i+3])/3 for i in range(0,len(a),4)]
 assert min(brightness)<background and max(brightness)>background
 if '--preview' in sys.argv:
  from PIL import Image
  raw=bytes(round(max(0,min(1,v))*255) for v in a)
  Image.frombytes('RGBA',(64,64),raw).transpose(Image.Transpose.FLIP_TOP_BOTTOM).resize((512,512)).save('/tmp/roof-film-'+label+'.png')
print('PASS: composed roof water retains lit and shaded faces in day/night lighting')
