"""Production channel waves: static network, transported crests, rounded relief."""
from world_rain_gpu import *
p=program(vert,prefix+'''
void main(){
 vec2 at=gl_FragCoord.xy*.12;
 vec4 frame=terrainChannelFrame(at,.12);
 float h=terrainWaterFilm(at,.12);
 gl_FragColor=vec4(frame.x,h,frame.y*.05,1);
}
''')
use(p);uf(loc(p,b'terrainWetness'),.7)
frames=[]
for t in [0,.12,.24,.36]:
 uf(loc(p,b'terrainFlowTime'),t);frames.append(render(p))
for a,b in zip(frames,frames[1:]):
 assert a[::4]==b[::4], 'moving channel footprint'
 assert a[2::4]==b[2::4], 'moving channel phase coordinates'
 assert max(abs(x-y) for x,y in zip(a[1::4],b[1::4]))>.04, 'weak travelling relief'
 for mask,x,y in zip(a[::4],a[1::4],b[1::4]):
  if mask==0: assert x==y, 'ripples escaping channels'
# Across a time interval, different parts must rise AND fall, not globally flash.
a,b=frames[:2]
delta=[y-x for mask,x,y in zip(a[::4],a[1::4],b[1::4]) if mask>.9]
assert max(delta)>.04 and min(delta)<-.04, 'synchronized flashing'
print('PASS: fixed channel coordinates, localized travelling relief and simultaneous crests/troughs')
if __name__=='__main__':
 from PIL import Image
 p=program(vert,prefix+'''
 void main(){vec2 at=gl_FragCoord.xy*.12;
 float h=terrainWaterFilm(at,.12);
 vec3 n=normalize(vec3(-dFdx(h)*12.0,-dFdy(h)*12.0,1));
 float light=dot(n,normalize(vec3(-.5,.8,1)));
 gl_FragColor=vec4(vec3(.15,.22,.27)*(.4+light)+vec3(pow(max(light,0.0),16.0))*.45,1);}
 ''')
 use(p);uf(loc(p,b'terrainWetness'),.7)
 images=[]
 for t in [0,.12,.24,.36]:
  uf(loc(p,b'terrainFlowTime'),t)
  raw=bytes(round(max(0,min(1,x))*255) for x in render(p))
  images.append(Image.frombytes('RGBA',(64,64),raw).convert('RGB').transpose(Image.Transpose.FLIP_TOP_BOTTOM).resize((256,256)))
 sheet=Image.new('RGB',(1024,256))
 for i,im in enumerate(images):sheet.paste(im,(i*256,0))
 sheet.save('/tmp/channel-wave-frames.png')
