"""Render the production orbital shaders using headless EGL/Mesa.

No Python GL packages are required. Numpy is required; Pillow is needed only
for PNG previews or image inputs. Examples:
  python3 tests/orbital_arrival_gpu.py --preview-dir /tmp/arrival-preview
  python3 tests/orbital_arrival_gpu.py --width 1920 --height 1080 --region 19.25 41.5
  python3 tests/orbital_arrival_gpu.py --survey-image survey.png --live-image game.png

Image inputs are optional preview sources, never replacements for the asymmetric
regression fixtures. A survey image represents the clean minimap already
projected into the saved final camera view. Transparent pixels are outside the
map. Ordinary file images are converted to the required texture orientation;
raw minimap images retain map-world coordinates. These are actual GLSL renders, not artist previews.
Timing includes readback on the host GL implementation; it is not target-GPU FPS.
"""
import argparse, ctypes as C, hashlib, json, os, time
from pathlib import Path
import numpy as np
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--preview-dir')
parser.add_argument('--live-image',type=Path,help='Optional final framebuffer image for previews')
survey_options=parser.add_mutually_exclusive_group()
survey_options.add_argument('--survey-image',type=Path,help='Optional preprojected clean map image for previews')
survey_options.add_argument('--minimap-image',type=Path,help='Optional raw map texture, projected by the production survey shader')
parser.add_argument('--survey-rows',type=float,nargs=9,
                    default=(1.,0.,0.,0.,-1.,1.,0.,0.,1.),
                    help='Three screen-to-map homography rows for --minimap-image (default: north-up)')
parser.add_argument('--metrics-json',type=Path,help='Write descriptive image metrics and render timings')
parser.add_argument('--width',type=int,default=960,help='Render width (default: 960)')
parser.add_argument('--height',type=int,default=540,help='Render height (default: 540)')
parser.add_argument('--region',type=float,nargs=2,default=(0.,0.),metavar=('X','Y'),
                    help='Generated Earth region offset (default: 0 0)')
args=parser.parse_args()
if args.width<=0 or args.height<=0:parser.error('width and height must be positive')
if not np.isfinite(args.region).all():parser.error('region coordinates must be finite')
if not np.isfinite(args.survey_rows).all():parser.error('survey rows must be finite')
W,H=args.width,args.height
REGION=tuple(args.region)
os.environ.setdefault('EGL_PLATFORM','surfaceless')
os.environ.setdefault('MESA_SHADER_CACHE_DISABLE','true')
egl=C.CDLL('libEGL.so.1'); gl=C.CDLL('libGL.so.1')
def bind(lib,name,restype,args):
 f=getattr(lib,name); f.restype=restype; f.argtypes=args; return f
I=C.c_int; U=C.c_uint; F=C.c_float; P=C.c_void_p
bind(egl,'eglGetDisplay',P,[P]); bind(egl,'eglInitialize',U,[P,C.POINTER(I),C.POINTER(I)])
bind(egl,'eglBindAPI',U,[U]); bind(egl,'eglChooseConfig',U,[P,C.POINTER(I),C.POINTER(P),I,C.POINTER(I)])
bind(egl,'eglCreateContext',P,[P,P,P,C.POINTER(I)]); bind(egl,'eglCreatePbufferSurface',P,[P,P,C.POINTER(I)])
bind(egl,'eglMakeCurrent',U,[P,P,P,P])
display=egl.eglGetDisplay(None); major=I(); minor=I()
assert egl.eglInitialize(display,C.byref(major),C.byref(minor))
assert egl.eglBindAPI(0x30A2)
attrs=(I*13)(0x3033,1,0x3040,8,0x3024,8,0x3023,8,0x3022,8,0x3021,8,0x3038)
config=P(); count=I(); assert egl.eglChooseConfig(display,attrs,C.byref(config),1,C.byref(count)) and count.value
context=egl.eglCreateContext(display,config,None,(I*7)(0x3098,3,0x30FB,3,0x30FD,2,0x3038)); assert context
surface=egl.eglCreatePbufferSurface(display,config,(I*5)(0x3057,W,0x3056,H,0x3038)); assert surface
assert egl.eglMakeCurrent(display,surface,surface,context)
for n,ret,argtypes in [
 ('glCreateShader',U,[U]),('glShaderSource',None,[U,I,C.POINTER(C.c_char_p),P]),
 ('glCompileShader',None,[U]),('glGetShaderiv',None,[U,U,C.POINTER(I)]),
 ('glGetShaderInfoLog',None,[U,I,P,C.c_char_p]),('glCreateProgram',U,[]),
 ('glAttachShader',None,[U,U]),('glLinkProgram',None,[U]),('glGetProgramiv',None,[U,U,C.POINTER(I)]),
 ('glGetProgramInfoLog',None,[U,I,P,C.c_char_p]),('glUseProgram',None,[U]),
 ('glGetUniformLocation',I,[U,C.c_char_p]),('glUniform1f',None,[I,F]),('glUniform1i',None,[I,I]),
 ('glUniform2f',None,[I,F,F]),('glUniform3f',None,[I,F,F,F]),('glGenTextures',None,[I,C.POINTER(U)]),
 ('glBindTexture',None,[U,U]),('glTexImage2D',None,[U,I,I,I,I,I,U,U,P]),
 ('glTexParameteri',None,[U,U,I]),('glCopyTexSubImage2D',None,[U,I,I,I,I,I,I,I]),('glActiveTexture',None,[U]),
 ('glGenFramebuffers',None,[I,C.POINTER(U)]),('glBindFramebuffer',None,[U,U]),
 ('glFramebufferTexture2D',None,[U,U,U,U,I]),('glViewport',None,[I,I,I,I]),
 ('glBegin',None,[U]),('glEnd',None,[]),('glTexCoord2f',None,[F,F]),('glVertex2f',None,[F,F]),
 ('glReadPixels',None,[I,I,I,I,U,U,P]),('glDisable',None,[U]),('glGetError',U,[]),
 ('glGetString',C.c_char_p,[U])]: bind(gl,n,ret,argtypes)
GL_VERSION=gl.glGetString(0x1F02).decode()
GL_RENDERER=gl.glGetString(0x1F01).decode()
print('GL:',GL_VERSION,';',GL_RENDERER,f'; render {W}x{H}; region {REGION}',flush=True)
timings={'earth':[], 'composite':[], 'survey':[]}
metrics=[]
def compile_stage(kind,source):
 shader=gl.glCreateShader(kind); src=C.c_char_p(source.encode())
 gl.glShaderSource(shader,1,C.byref(src),None); gl.glCompileShader(shader)
 status=I(); gl.glGetShaderiv(shader,0x8B81,C.byref(status))
 if not status.value:
  log=C.create_string_buffer(65536); gl.glGetShaderInfoLog(shader,len(log),None,log); raise AssertionError(log.value.decode())
 return shader
vertex='#version 150 compatibility\nvoid main(){gl_Position=gl_ModelViewProjectionMatrix*gl_Vertex;gl_TexCoord[0]=gl_MultiTexCoord0;}'
root=Path(__file__).resolve().parents[1]/'luaui/widgets_mosaic/shaders'
shader_digests={}
def program(path):
 p=gl.glCreateProgram()
 source=path.read_text()
 shader_digests[path.name]=hashlib.sha256(source.encode()).hexdigest()
 gl.glAttachShader(p,compile_stage(0x8B31,vertex));gl.glAttachShader(p,compile_stage(0x8B30,source));gl.glLinkProgram(p)
 status=I();gl.glGetProgramiv(p,0x8B82,C.byref(status))
 if not status.value:
  log=C.create_string_buffer(65536);gl.glGetProgramInfoLog(p,len(log),None,log);raise AssertionError(log.value.decode())
 return p
earth=program(root/'orbital_arrival_earth.frag'); composite=program(root/'orbital_arrival_composite.frag')
survey_projector=program(root/'orbital_arrival_survey.frag')
def uniform(p,n,v,integer=False):
 gl.glUseProgram(p);loc=gl.glGetUniformLocation(p,n.encode())
 assert loc>=0, f'Missing production shader uniform: {n}'
 if isinstance(v,tuple):
  if len(v)==3:gl.glUniform3f(loc,*v)
  else:gl.glUniform2f(loc,*v)
 elif integer:gl.glUniform1i(loc,v)
 else:gl.glUniform1f(loc,v)
def texture(data=None):
 t=U();gl.glGenTextures(1,C.byref(t));gl.glBindTexture(0x0DE1,t.value)
 tw,th=(W,H) if data is None else (data.shape[1],data.shape[0])
 gl.glTexImage2D(0x0DE1,0,0x8814,tw,th,0,0x1908,0x1406,None if data is None else data.ctypes.data)
 for key,val in [(0x2801,0x2601),(0x2800,0x2601),(0x2802,0x812F),(0x2803,0x812F)]:gl.glTexParameteri(0x0DE1,key,val)
 return t.value
fbo=U();gl.glGenFramebuffers(1,C.byref(fbo)); orbit=texture();out=texture()
y,x=np.mgrid[0:H,0:W]; live_data=np.ones((H,W,4),dtype='f4')
live_data[:,:,0]=x/W;live_data[:,:,1]=y/H;live_data[:,:,2]=((x//24+y//24)%2)*0.5
# The screen and survey have independent, asymmetric fixtures. X and Y gradients
# expose either mirror; a non-centred landmark makes a 180-degree flip visible.
# Exercise the real framebuffer-copy operation. Recoil's CopyToTexture is a
# direct glCopyTexSubImage2D: it preserves the framebuffer's bottom-left origin.
source_framebuffer=texture(live_data);live=texture()
gl.glBindFramebuffer(0x8D40,fbo.value)
gl.glFramebufferTexture2D(0x8D40,0x8CE0,0x0DE1,source_framebuffer,0)
gl.glBindTexture(0x0DE1,live)
gl.glCopyTexSubImage2D(0x0DE1,0,0,0,0,0,W,H)
assert gl.glGetError()==0,'Synthetic framebuffer capture failed'
other=texture(np.full_like(live_data,0.05)); art=texture(np.full_like(live_data,0.25))
survey_data=live_data.copy()
survey_data[:,:,:3]=survey_data[:,:,:3]*0.65+0.10
survey_data[H//6:H//3,W//7:W//4,:3]=(0.80,0.18,0.07)
survey=texture(survey_data)
other_survey_data=np.full_like(survey_data,0.04);other_survey_data[:,:,3]=1.
other_survey=texture(other_survey_data)
transparent_survey_data=survey_data.copy();transparent_survey_data[:,:,3]=0.
transparent_survey=texture(transparent_survey_data)

preview_image_data={}
def image_texture(path,screen_texture=False,resize=True):
 if path is None:return None
 from PIL import Image
 with Image.open(path) as source:
  source=source.convert('RGBA')
  if resize:source=source.resize((W,H),Image.Resampling.LANCZOS)
  pixels=np.asarray(source,dtype='f4')/255.
 # Image files start at their top row. Screen render targets and framebuffer
 # copies start at their bottom row; raw SMF minimaps start at world Z=0.
 if screen_texture:pixels=pixels[::-1]
 pixels=np.ascontiguousarray(pixels)
 image_input=texture(pixels)
 preview_image_data[image_input]=pixels
 return image_input
preview_live=image_texture(args.live_image,screen_texture=True) or live
preview_survey=image_texture(args.survey_image,screen_texture=True) or survey
gl.glDisable(0x0BE2);gl.glDisable(0x0B71)
def quad(p,target):
 gl.glBindFramebuffer(0x8D40,fbo.value);gl.glFramebufferTexture2D(0x8D40,0x8CE0,0x0DE1,target,0)
 gl.glViewport(0,0,W,H);gl.glUseProgram(p);started=time.perf_counter();gl.glBegin(7)
 for px,py,u,v in [(-1,-1,0,0),(1,-1,1,0),(1,1,1,1),(-1,1,0,1)]:gl.glTexCoord2f(u,v);gl.glVertex2f(px,py)
 gl.glEnd();assert gl.glGetError()==0
 data=np.empty((H,W,4),dtype='f4');gl.glReadPixels(0,0,W,H,0x1908,0x1406,data.ctypes.data)
 timings['earth' if p==earth else 'survey' if p==survey_projector else 'composite'].append((time.perf_counter()-started)*1000.)
 assert np.isfinite(data).all(),'Production shader produced NaN or infinite pixels'
 assert np.all((data[:,:,3]>=0.)&(data[:,:,3]<=1.)), 'Shader alpha outside [0,1]'
 return data
def project_survey(map_input,rows,target=None):
 if target is None:target=texture()
 gl.glActiveTexture(0x84C0);gl.glBindTexture(0x0DE1,map_input)
 uniform(survey_projector,'mapTex',0,True)
 for index,row in enumerate(np.asarray(rows).reshape(3,3)):
  uniform(survey_projector,f'mapRow{index}',tuple(row))
 return target,quad(survey_projector,target)

# The survey shader is tested independently of its Lua homography solver.
# A known analytic gradient supplies UV ground truth rather than computing
# expected pixels by copying the production GLSL into a second implementation.
map_data=np.ones_like(live_data)
map_data[:,:,0]=(x+0.5)/W;map_data[:,:,1]=(y+0.5)/H
# A smooth off-centre landmark avoids amplifying sub-ULP interpolator error
# across a discontinuity while retaining unmistakable corner orientation.
map_data[:,:,2]=0.15+0.6*np.exp(-(((x+0.5)/W-0.21)/0.08)**2-(((y+0.5)/H-0.71)/0.10)**2)
map_input=texture(map_data)
_,identity=project_survey(map_input,np.eye(3))
assert np.allclose(identity[:,:,:3],map_data[:,:,:3],atol=2e-6),'Survey identity projection moved map pixels'
pixel_uv=map_data[:,:,:2]
edge_distance=np.minimum(pixel_uv,1.-pixel_uv).min(axis=2)
edge_progress=np.clip(edge_distance/.07,0.,1.)
edge_coverage=edge_progress*edge_progress*(3.-2.*edge_progress)
assert np.allclose(identity[:,:,3],edge_coverage,atol=2e-5),'Survey map-edge feather changed its defined coverage'
assert np.all(identity[edge_distance>=.07,3]==1.),'Survey feather erodes the map interior'
edge_run=identity[H//2,:max(2,int(W*.08)),3]
assert np.all(np.diff(edge_run)>=0.),'Survey edge coverage is not monotonic toward the map interior'
assert np.any((edge_run>0.)&(edge_run<1.)),'Survey edge reverted to a hard rectangular stamp'
_,north_up=project_survey(map_input,((1.,0.,0.),(0.,-1.,1.),(0.,0.,1.)))
assert np.allclose(north_up[:,:,:3],map_data[::-1,:,:3],atol=2e-6),'Survey north-up projection mirrored X or inverted map Z'
assert np.allclose(north_up[:,:,3],identity[::-1,:,3],atol=2e-5),'Survey north-up projection moved the map-edge feather'
# This inverse maps a rotated trapezoid to the whole map, with a finite
# vanishing line outside it. Nonzero cross-axis terms exercise every matrix
# coefficient. Away from edges, R/G must equal the known map UV.
rows=np.array(((1.6,0.17,-0.25),(-0.21,-1.6,1.3),(0.12,0.35,0.8)))
_,perspective=project_survey(map_input,rows)
q=np.stack(((x+0.5)/W,(y+0.5)/H,np.ones((H,W))),axis=2)
mapped=q@rows.T
uv=mapped[:,:,:2]/mapped[:,:,2:3]
inside=((uv>=0.)&(uv<=1.)).all(axis=2)
interior=((uv>.01)&(uv<.99)).all(axis=2)
assert np.allclose(perspective[interior,:2],uv[interior],atol=3e-5), 'Perspective survey shifted the known map coordinates'
opaque_interior=((uv>=.07)&(uv<=.93)).all(axis=2)
assert np.all(perspective[opaque_interior,3]==1.),'Survey dropped interior map coverage'
projected_edge=np.minimum(uv,1.-uv).min(axis=2)
projected_progress=np.clip(projected_edge/.07,0.,1.)
projected_coverage=projected_progress**2*(3.-2.*projected_progress)
assert np.allclose(perspective[:,:,3],projected_coverage,atol=3e-5),'Perspective survey shifted the map-edge feather'
assert np.all(perspective[~inside]==0.),'Survey smeared map borders into the outside area'
_,singular=project_survey(map_input,np.zeros((3,3)))
assert np.array_equal(singular,np.zeros_like(singular)),'Singular survey projection must return transparent finite pixels'
if args.minimap_image:
 raw_minimap=image_texture(args.minimap_image,resize=False)
 preview_survey,preview_survey_data=project_survey(raw_minimap,args.survey_rows)

uniform(earth,'aspect',W/H)
uniform(earth,'surveyTex',0,True)
for n,v in [('orbitTex',0),('artworkTex',1),('liveTex',2),('hasArtwork',1),('hasLive',1)]:uniform(composite,n,v,True)
uniform(composite,'artScale',(1.,1.));uniform(composite,'fade',1.)
def render(descent,cloud_descent=0.,live_input=live,fade=1.,region=REGION,
           survey_input=survey,has_survey=True,has_live=True,artwork_input=art,has_artwork=True):
 uniform(earth,'descent',descent);uniform(earth,'cloudDescent',cloud_descent)
 uniform(earth,'regionOffset',tuple(region))
 uniform(earth,'hasSurvey',int(has_survey),True)
 gl.glActiveTexture(0x84C0);gl.glBindTexture(0x0DE1,survey_input)
 e=quad(earth,orbit)
 for unit,tex in enumerate((orbit,artwork_input,live_input)):gl.glActiveTexture(0x84C0+unit);gl.glBindTexture(0x0DE1,tex)
 uniform(composite,'descent',cloud_descent);uniform(composite,'fade',fade)
 uniform(composite,'hasLive',int(has_live),True)
 uniform(composite,'hasArtwork',int(has_artwork),True)
 return e,quad(composite,out)
def preview(result,name):
 rgb=result[:,:,:3]
 brightness=rgb.mean(axis=2)
 # Descriptive metrics, not a claim to measure realism. Cold-white coverage
 # makes the previous blank-cloud failure easy to compare before/after.
 coldwhite=(rgb.min(axis=2)>.65)&((rgb.max(axis=2)-rgb.min(axis=2))<.12)
 warm=(rgb[:,:,0]-rgb[:,:,2]>.07)&(brightness>.25)
 metrics.append({'name':name,'cold_white_fraction':float(coldwhite.mean()),
                 'warm_fraction':float(warm.mean()),'luma_stddev':float(brightness.std()),
                 'rgb_min':float(rgb.min()),'rgb_max':float(rgb.max())})
 if args.preview_dir:
  from PIL import Image
  directory=Path(args.preview_dir);directory.mkdir(parents=True,exist_ok=True)
  Image.fromarray(np.uint8(np.clip(result[::-1,:,:3],0,1)*255)).save(directory/f'{name}.png')

def preview_stage(descent,cloud_descent,name,region=REGION,rendered=None):
 if args.live_image or args.survey_image or args.minimap_image:
  result=render(descent,cloud_descent,live_input=preview_live,
                survey_input=preview_survey,region=region)[1]
  if args.live_image and cloud_descent>=.98:
   assert np.array_equal(result[:,:,:3],preview_image_data[preview_live][:,:,:3]),'Terminal preview changed the supplied live-image pixels or orientation'
 else:
  result=rendered if rendered is not None else render(descent,cloud_descent,region=region)[1]
 preview(result,name)

# The four optical snapshots all precede atmospheric transit. The shader takes
# no time input: a chosen region's terrain and clouds must stay fixed while the
# apparent altitude changes. Noon lighting is reviewed in the production source;
# output bounds deliberately allow dark water and a bright atmospheric limb.
orbit_stages=[]
for index,descent in enumerate([0.,0.30,0.64,1.],1):
 e,result=render(descent,cloud_descent=0.)
 orbit_stages.append(e[:,:,:3].copy())
 assert result[:,:,:3].min()>=0 and result[:,:,:3].max()<=3.5
 assert np.allclose(e[:,:,3],0.),f'Planetary snapshot {index} entered atmospheric transit early'
 repeated_e,other_result=render(descent,cloud_descent=0.,live_input=other)
 assert np.array_equal(e,repeated_e),f'Planetary snapshot {index} changes between identical renders'
 assert np.array_equal(result,other_result),f'Planetary snapshot {index} exposes live-city pixels'
 changed_survey=render(descent,survey_input=other_survey)[0]
 survey_difference=float(np.mean(np.abs(e[:,:,:3]-changed_survey[:,:,:3])))
 if descent==0.:
  assert np.array_equal(e,changed_survey),f'Planetary snapshot {index} exposes survey imagery too early'
 elif descent>=0.64:
  assert survey_difference>1./255.,f'City snapshot {index} does not contain the map survey'
 print(f'Snapshot {index} survey mean RGB contribution: {survey_difference:.6f}',flush=True)
 preview_stage(descent,0.,f'{index:02d}_planet_{descent:.2f}',rendered=result)
assert all(np.mean(np.abs(a-b)) > 0.015 for a,b in zip(orbit_stages,orbit_stages[1:])), (
 'Orbital image has insufficient magnification across the four planetary snapshots')

# Unavailable imagery must fall back to deterministic generated terrain. Even
# arbitrary RGB data in invalid survey pixels must not leak into the planet.
for descent in (0.64,1.):
 unavailable=render(descent,has_survey=False)[0]
 unavailable_other=render(descent,survey_input=other_survey,has_survey=False)[0]
 transparent=render(descent,survey_input=transparent_survey)[0]
 assert np.array_equal(unavailable,unavailable_other),'Unavailable survey changes fallback terrain'
 assert np.allclose(unavailable,transparent,atol=2e-6),'Transparent survey RGB leaks outside map coverage'
 preview(unavailable,f'fallback_planet_{descent:.2f}')

# A changed map landmark must enlarge around the same target centre, following
# the optical scale. This probes the Earth sampler itself: an upside-down map
# or a second hidden zoom can still pass the projector's independent UV test.
landmark_data=np.full_like(live_data,.20);landmark_data[:,:,3]=1.
landmark_base=texture(landmark_data)
mark_x=(.63,.83);mark_y=(.59,.77)
landmark_data[int(H*mark_y[0]):int(H*mark_y[1]),int(W*mark_x[0]):int(W*mark_x[1]),:3]=(.82,.10,.06)
landmark_changed=texture(landmark_data)
for descent in (.64,1.):
 before=render(descent,survey_input=landmark_base)[0]
 after=render(descent,survey_input=landmark_changed)[0]
 difference=np.abs(after[:,:,:3]-before[:,:,:3]).max(axis=2)
 scale=2.**(3.28*(1.-descent))
 sample_x=((x+.5)/W-.5)*scale+.5
 sample_y=((y+.5)/H-.5)*scale+.5
 # Pad two source texels for rounding and the linear filter's footprint.
 expected_area=(sample_x>=mark_x[0]-2./W)&(sample_x<=mark_x[1]+2./W)&(sample_y>=mark_y[0]-2./H)&(sample_y<=mark_y[1]+2./H)
 assert np.any(difference[expected_area]>1./255.),f'Map landmark disappeared at optical stop {descent}'
 assert np.all(difference[~expected_area]<2e-6),f'Map landmark moved away from the target-centred optical scale at {descent}'

# A region changes the generated surface and weather, without depending on any
# previously rendered region or stage. Test fully opaque transit clouds as well
# as the orbital image, so terrain differences cannot disguise fixed weather.
regional_orbit,regional_scene=render(0.64)
regional_cloud,cloud_scene=render(1.,cloud_descent=0.52)
region_differences=[]
for index,(dx,dy) in enumerate([(19.25,41.5),(-31.75,7.125),(73.875,-18.625)],1):
 region=(REGION[0]+dx,REGION[1]+dy)
 changed_orbit,changed_scene=render(0.64,region=region)
 changed_cloud,changed_cloud_scene=render(1.,cloud_descent=0.52,region=region)
 orbit_difference=float(np.mean(np.abs(regional_orbit[:,:,:3]-changed_orbit[:,:,:3])))
 cloud_difference=float(np.mean(np.abs(regional_cloud[:,:,:3]-changed_cloud[:,:,:3])))
 assert orbit_difference>1./255.,f'Region {region} did not change the visible Earth'
 assert cloud_difference>1./255.,f'Region {region} did not change its cloud field'
 assert np.array_equal(changed_cloud[:,:,3],regional_cloud[:,:,3]), (
  'Generated weather changed the guaranteed opaque projection handoff')
 region_differences.append((round(orbit_difference,4),round(cloud_difference,4)))
 preview_stage(0.64,0.,f'region_{index:02d}_planet_0.64',region=region,rendered=changed_scene)
 preview_stage(1.,0.52,f'region_{index:02d}_cloud_0.52',region=region,rendered=changed_cloud_scene)
 repeated_orbit,repeated_scene=render(0.64)
 repeated_cloud,repeated_cloud_scene=render(1.,cloud_descent=0.52)
 assert np.array_equal(regional_orbit,repeated_orbit) and np.array_equal(regional_scene,repeated_scene), (
  'Orbital terrain or clouds moved between identical fixed-stage renders')
 assert np.array_equal(regional_cloud,repeated_cloud) and np.array_equal(cloud_scene,repeated_cloud_scene), (
  'Transit cloud density changed without camera descent or regional movement')
print('Region mean RGB differences (Earth, cloud):',region_differences,flush=True)

# Only after the final planetary snapshot do near-camera clouds take over and
# open onto the live framebuffer. Optical magnification stays at its last stop.
for index,cloud_descent in enumerate([0.16,0.34,0.43,0.52,0.65,0.8,0.96,1.],5):
 e,result=render(1.,cloud_descent=cloud_descent)
 assert result[:,:,:3].min()>=0 and result[:,:,:3].max()<=1.5
 if 0.42<=cloud_descent<=0.55:
  assert np.allclose(e[:,:,3],1.),'Handoff cloud is not fully opaque'
  other_result=render(1.,cloud_descent=cloud_descent,live_input=other)[1]
  assert np.array_equal(result,other_result),'Cloud handoff exposes underlying projection switch'
 if cloud_descent==1.:
  expected=live_data.copy()
  assert np.array_equal(result,expected),'Final composite changed captured framebuffer pixels or orientation'
  assert np.allclose(result[:,:,0],expected[:,:,0],atol=2e-6),'Live handoff inverted X / performed a 180-degree rotation'
  regional_result=render(1.,cloud_descent=1.,region=(REGION[0]+19.25,REGION[1]+41.5))[1]
  assert np.array_equal(result,regional_result), (
   f'Generated region altered the final live-city pixels: max error {np.max(np.abs(result-regional_result))}')
 preview_stage(1.,cloud_descent,f'{index:02d}_cloud_{cloud_descent:.2f}',rendered=result)
# The display-rate composite must release a deliberately stale, fully opaque
# cloud texture once .98 is reached, even before the cached Earth pass refreshes.
stale_cloud,_=render(1.,cloud_descent=.55)
assert np.all(stale_cloud[:,:,3]==1.),'Stale-cache regression fixture is not opaque'
uniform(composite,'descent',.985)
assert np.array_equal(quad(composite,out),live_data),'Terminal .985 frame retained cached cloud alpha or rounded live pixels'
uniform(composite,'hasArtwork',0,True);uniform(composite,'fade',0.)
assert np.array_equal(quad(composite,out),live_data),'Absent artwork blocked the exact terminal live frame'
# With no live input the shader remains a valid scene through the entire
# reveal instead of mixing unbound texture data. Final orientation checks above
# always used the asymmetric fixture, regardless of optional preview images.
for cloud_descent in (0.,0.43,0.8,1.):
 unavailable=render(1.,cloud_descent=cloud_descent,has_live=False)[1]
 unavailable_other=render(1.,cloud_descent=cloud_descent,live_input=other,has_live=False)[1]
 assert np.array_equal(unavailable,unavailable_other),'Unavailable live texture changes compositor output'
assert np.allclose(render(0,fade=0)[1][:,:,:3],0.25,atol=1e-6),'Artwork continuity failed'
# File artwork alone needs the image-loader Y correction. The explicit-UV
# screen targets and captured framebuffer must never inherit that correction.
art_probe_data=np.ones_like(live_data)
art_probe_data[:,:,0]=(x+0.5)/W;art_probe_data[:,:,1]=(y+0.5)/H
art_probe_data[:,:,2]=0.2
art_probe=texture(art_probe_data)
art_result=render(0,fade=0,artwork_input=art_probe)[1]
assert np.allclose(art_result,art_probe_data[::-1],atol=2e-6),'Artwork file orientation changed'
no_art=render(0,fade=0,has_artwork=False)[1]
no_art_other=render(0,fade=0,has_artwork=False,artwork_input=art_probe)[1]
assert np.array_equal(no_art,no_art_other),'Unavailable artwork affects the orbital scene'
if args.minimap_image:
 preview(preview_survey_data,'source_projected_survey')
report={'gl_version':GL_VERSION,'gl_renderer':GL_RENDERER,'width':W,'height':H,
        'shader_sha256':shader_digests,
        'region':REGION,'inputs':{'survey':str(args.survey_image or args.minimap_image) if (args.survey_image or args.minimap_image) else 'asymmetric fixture',
                                'live':str(args.live_image) if args.live_image else 'asymmetric fixture'},
        'survey_rows':list(args.survey_rows) if args.minimap_image else None,
        'timing_note':'Host GL wall time including readback; not target-hardware frame rate',
        'timings_ms':{key:{'samples':len(values),'median':float(np.median(values)),
                           'p95':float(np.percentile(values,95))} for key,values in timings.items()},
        'images':metrics}
if args.metrics_json:
 args.metrics_json.parent.mkdir(parents=True,exist_ok=True)
 args.metrics_json.write_text(json.dumps(report,indent=2)+'\n')
print('Host render/readback timings (ms):',report['timings_ms'],flush=True)
print('Cold-white coverage at four stops:',
      [round(m['cold_white_fraction']*100.,2) for m in metrics[:4]],flush=True)
print('PASS: shaders compile; four planetary snapshots hide live pixels; orbital scale advances; '
      'clean map survey source boundaries; perspective survey and alpha coverage; unavailable/transparent survey fallback; '
      'target-centred map landmark magnification; '
      'stationary repeat renders; different regional terrain and clouds; opaque cloud handoff; '
      'exact copied live pixels across regions; unavailable live fallback; artwork orientation/continuity')
