"""Render production splashback against synthetic ground/roof/depth/light buffers.
Run python tests/rain_splashback_gpu.py; imports the existing EGL regressions.
"""
from world_rain_gpu import *

splash=program(vert,prefix.replace('uniform vec3 eyePos;', 'vec3 eyePos;')+'''
uniform float testDistance;
uniform float testHeight;
void main(){
 uv=gl_FragCoord.xy/viewPortSize;
 depthAtPixel=vec4(0.5);
 vec3 surface=GetWorldPosAtUV(uv,0.5);
 eyePos=surface+vec3(0,testHeight,0);
 bool g,u,p,s;
 vec3 n=GetGroundVertexNormal(uv,g,u,p,s);
 gl_FragColor=drawRainSplashback(surface,n,vec3(0,-1,0),testDistance,s);
}
''')
use(splash)
u2=fn(G,'glUniform2f',None,I,F,F)
um=fn(G,'glUniformMatrix4fv',None,I,I,U,P)
def sf(name,value): uf(loc(splash,name.encode()),value)
def sv(name,value): u3(loc(splash,name.encode()),*value)
def mat(name,rows):
    values=[rows[r][c] for c in range(4) for r in range(4)]
    um(loc(splash,name.encode()),1,0,(F*16)(*values))
def camera(x=128,zero_to_one=True):
    sf('clipZeroToOne',int(zero_to_one))
    if zero_to_one:
        mat('viewProjection',[[1/8,0,0,-x/8],[0,0,1/8,-16],[0,-.01,0,.5],[0,0,0,1]])
        mat('viewProjectionInv',[[8,0,0,x],[0,0,-100,50],[0,8,0,128],[0,0,0,1]])
    else:
        mat('viewProjection',[[1/8,0,0,-x/8],[0,0,1/8,-16],[0,-.02,0,0],[0,0,0,1]])
        mat('viewProjectionInv',[[8,0,0,x],[0,0,-50,0],[0,8,0,128],[0,0,0,1]])
for slot,name in enumerate(['normaltex','normalunittex','mapDepthTex','modelDepthTex',
                             'dephtCopyTex','rainRadianceTex','rainOccupancyTex']):
    if slot>=len(textures):
        t=U(); gen(1,C.byref(t)); textures.append(t)
        active(0x84C0+slot); bind(0x0DE1,t.value)
        param(0x0DE1,0x2801,0x2600); param(0x0DE1,0x2800,0x2600)
    ui(loc(splash,name.encode()),slot)
texture(0,up); texture(1,empty); texture(2,(.5,0,0,0)); texture(3,(1,0,0,0))
texture(4,(.5,0,0,0)); texture(5,(1,0,0,0)); texture(6,empty)
u2(loc(splash,b'viewPortSize'),64,64)
camera()
for name,value in [('rainPercent',1),('testDistance',50),('testHeight',50),('time',3),
                   ('timePercent',.5),('rainLightActive',0)]: sf(name,value)
sv('sunCol',(.2,.2,.2)); sv('skyCol',(.1,.1,.1))
a=render(splash)
assert max(a[3::4])>0,'no splash droplets'
assert sum(v>0 for v in a[3::4])<len(a[3::4])*.1,'continuous water skin'
assert a==render(splash),'unstable stationary frame'
sf('time',3.05); b=render(splash)
assert a!=b and max(b[3::4])>0,'no ballistic animation'
sf('time',3)
# Identical roof and ground surfaces must produce identical droplets, regardless of alpha.
texture(1,up); texture(3,(.4,0,0,0)); assert render(splash)==a,'unit normal alpha'
texture(1,wall); assert max(render(splash)[3::4])==0,'wall splashes'
texture(0,empty); texture(1,empty); assert max(render(splash)[3::4])==0,'sky splashes'
texture(0,up); texture(3,(1,0,0,0))
for name,value,restore in [('rainPercent',0,1),('testDistance',40,50),('testHeight',2800,50)]:
    sf(name,value); assert max(render(splash)[3::4])==0,name
    sf(name,restore)
# The source is hidden by another surface or unavailable, even though the
# destination's plane remains valid. It must not seed a droplet through that edge.
for depth in [.2,1]:
    texture(4,(depth,0,0,0)); assert max(render(splash)[3::4])==0,'hidden source'
texture(4,(.5,0,0,0))
camera(zero_to_one=False); assert render(splash)==a,'legacy clip depth'
camera(128.25)
b=render(splash)
for y in range(4,60):
    for x in range(4,59):
        ia=(y*64+x+1)*4; ib=(y*64+x)*4
        assert max(abs(c-d) for c,d in zip(a[ia:ia+4],b[ib:ib+4]))<.005,'camera pan'
camera()
sf('rainLightActive',1); sf('rainLightIntensity',1); sf('rainLightStrength',2)
u2(loc(splash,b'rainMapSize'),512,512); u2(loc(splash,b'rainLightHeight'),0,128)
b=render(splash)
visible=[i for i in range(0,len(a),4) if a[i+3]>0]
assert sum(b[i]-a[i] for i in visible)>0,'radiance not lighting splash'
assert all(b[i+1:i+4]==a[i+1:i+4] for i in visible),'radiance changed coverage or wrong colour'
texture(6,(1,0,0,0)); assert render(splash)==a,'occupied radiance cell'
print('PASS: sparse animated splashback; ground/alpha-zero roofs; wall/sky/dry/distance rejection; source and foreground depth; both clip conventions; camera pan; radiance colour and occupancy')

# Perspective projection and a tilted plane exercise actual reconstructed
# positions and the normal-expansion path rather than only vertical test rays.
perspective=program(vert,prefix+'''
void main(){
 uv=gl_FragCoord.xy/viewPortSize;
 depthAtPixel=texture2D(dephtCopyTex,uv);
 vec3 surface=GetWorldPosAtUV(uv,depthAtPixel.r);
 bool g,u,p,s;
 vec3 n=GetGroundVertexNormal(uv,g,u,p,s);
 gl_FragColor=drawRainSplashback(surface,n,normalize(surface-eyePos),length(surface-eyePos),s);
}
''')
splash=perspective
use(splash)
for slot,name in enumerate(['normaltex','normalunittex','mapDepthTex','modelDepthTex','dephtCopyTex']):
    ui(loc(splash,name.encode()),slot)
u2(loc(splash,b'viewPortSize'),64,64)
sf('clipZeroToOne',1); sf('rainPercent',1); sf('time',3); sf('rainLightActive',0)
sv('eyePos',(128,50,128)); sv('sunCol',(.2,.2,.2)); sv('skyCol',(.1,.1,.1))
mat('viewProjection',[[6.25,0,0,-800],[0,0,6.25,-800],[0,-1,0,49],[0,-1,0,50]])
mat('viewProjectionInv',[[.16,0,-128,128],[0,0,-50,49],[0,.16,-128,128],[0,0,-1,1]])
for slope in [0,.25]:
    normal=(-slope/math.sqrt(1+slope*slope),1/math.sqrt(1+slope*slope),0)
    texture(0,tuple(v*.5+.5 for v in normal)+(0,))
    depths=[]
    for y in range(64):
        for x in range(64):
            dx=((x+.5)/64*2-1)/6.25
            ray_height=50/(1+slope*dx)
            depths.extend((1-1/ray_height,0,0,0))
    for slot in [2,4]:
        active(0x84C0+slot); bind(0x0DE1,textures[slot].value)
        upload(0x0DE1,0,0x8814,64,64,0,0x1908,0x1406,(F*len(depths))(*depths))
    pixels=render(splash)
    assert max(pixels[3::4])>0,('perspective/slope coverage',slope)
    assert all(math.isfinite(v) for v in pixels)
print('PASS: perspective reconstruction and splashback on tilted surfaces')
