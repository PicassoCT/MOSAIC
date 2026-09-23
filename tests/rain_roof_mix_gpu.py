"""Check production rain-driven conversion from bead to rivulet clusters."""
from world_rain_gpu import *
p=program(vert,prefix+'''
void main(){
 vec2 id=floor(gl_FragCoord.xy)-vec2(32);
 float runoff=roofClusterRivulet(id,rainPercent);
 gl_FragColor=vec4(runoff);
}
''')
use(p)
previous=None
for rain in [0,.1,.25,.5,.75,1]:
 uf(loc(p,b'rainPercent'),rain)
 values=render(p)[::4]
 fraction=sum(values)/len(values)
 t=max(0,min(1,(rain-.1)/.9))
 expected=.8*t*t*(3-2*t)
 assert abs(fraction-expected)<.025,(rain,fraction,expected)
 if previous is not None:
  assert all(a<=b for a,b in zip(previous,values)), 'rain moved existing cluster selection'
 previous=values
 print('rain %.2f: %.1f%% rivulet clusters'%(rain,100*fraction))
assert .77<sum(previous)/len(previous)<.83
print('PASS: stable monotone bead-to-rivulet conversion reaches approximately 80% at full rain')
