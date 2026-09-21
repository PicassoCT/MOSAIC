"""Production stream density, nested selection, and absence of animation."""
from world_rain_gpu import *
p=program(vert,prefix+'''
void main(){float id=floor(gl_FragCoord.x)+64.0*floor(gl_FragCoord.y)-2048.0;
float enabled=permanentStreamEnabled(id,rainPercent);gl_FragColor=vec4(enabled);}
''')
use(p)
frames=[]
for rain in [0,.25,1]:
 uf(loc(p,b'rainPercent'),rain);frames.append(render(p)[::4])
assert max(frames[0])==0 and min(frames[2])>.5
fraction=sum(frames[1])/len(frames[1])
assert abs(fraction-.25**1.35)<.025,('quarter-rain density',fraction)
assert all(a<=b for a,b in zip(frames[1],frames[2]))
print('PASS: deterministic stream selection: quarter rain %.3f, full rain art-directed stream coverage'%fraction)
p=program(vert,prefix+'''
void main(){vec4 w=permanentRoofStreams(gl_FragCoord.xy*.125,.125);
gl_FragColor=vec4(abs(w.xyz),w.w);}
''')
use(p);uf(loc(p,b'rainPercent'),1);uf(loc(p,b'time'),0);a=render(p)
uf(loc(p,b'time'),12);b=render(p)
assert a==b and max(a)>0,'permanent stream moves or missing'
print('PASS: permanent stream shape and shading gradient are time-independent')
