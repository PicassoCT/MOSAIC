"""Compare published-window gain in the actual scene shader against git baseline.

Run from the repository root: python3 tests/window_lighting_scene_gpu.py
Uses the existing EGL helpers, numpy and Mesa. Timing on llvmpipe describes a
software-rendered synthetic scene, not Recoil or a physical GPU frame rate.
"""
import subprocess
from pathlib import Path

# Context setup and texture helpers only; do not execute the atlas benchmark.
exec(Path('tests/window_lighting_composition_gpu.py').read_text().split('atlas = texture')[0])

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--baseline-ref', default='d4895b9e623b372654693708549729f5dd4ccd04')
parser.add_argument('--rounds', type=int, default=11)
parser.add_argument('--repetitions', type=int, default=4)
args = parser.parse_args()
assert args.rounds > 0 and args.repetitions > 0
shader_path = 'luaui/widgets_mosaic/shaders/radiancecascade/scene.frag'
baseline_source = subprocess.check_output(['git', 'show', args.baseline_ref+':'+shader_path], text=True)
patched_source = Path(shader_path).read_text()
assert 'uniform int windowActive;' in baseline_source
assert 'uniform float windowGain;' in patched_source, 'scene gain patch not present'
mobile_source = Path('luaui/widgets_mosaic/shaders/radiancecascade/mobile_shadow.glsl').read_text()
flat_vertex = ('#version 150 compatibility\n'
               'void main(){gl_Position=gl_Vertex;gl_TexCoord[0]=gl_MultiTexCoord0;}')
programs = {}
for name, fragment in [('baseline', baseline_source), ('patched', patched_source)]:
    fragment = fragment.replace('#version 150 compatibility',
        '#version 150 compatibility\n#define MOBILE_SHADOWS_ENABLED 1', 1)
    fragment = fragment.replace('// MOBILE_SHADOWS', mobile_source)
    programs[name] = program(flat_vertex, fragment)

slots = [('radianceTex', [.2,.1,.05,0]), ('occupancyTex', [0,0,0,0]),
         ('mapDepthTex', [.5,0,0,0]), ('modelDepthTex', [1,0,0,0]),
         ('mapNormalTex', [.5,1,.5,1]), ('modelNormalTex', [.5,1,.5,1]),
         ('mapDiffuseTex', [1,1,1,1]), ('modelDiffuseTex', [1,1,1,1]),
         ('localRadianceTex', [0,0,0,0]), ('localOccupancyTex', [0,0,0,0]),
         ('headlightTex', [0,0,0,0]), ('headlightLocalTex', [0,0,0,0]),
         ('windowTex', [.3,.2,.1,0]), ('windowGroundTex', [0,0,0,0])]
textures = []
for slot, (name, rgba) in enumerate(slots):
    fn(G, 'glActiveTexture', None, U)(0x84C0+slot)
    data = np.empty((64,64,4), dtype='f4'); data[:] = rgba
    textures.append(texture(64,64,data))
    for p in programs.values():
        use(p); ui(loc(p, name.encode()), slot)

u2 = fn(G, 'glUniform2f', None, I, F, F)
m4 = fn(G, 'glUniformMatrix4fv', None, I, I, C.c_ubyte, P)
projection = np.zeros((4,4), dtype='f4')
projection[0,0] = 2048; projection[1,2] = 2048; projection[3,3] = 1
view = np.eye(4, dtype='f4'); view[3,:3] = [2048,0,2048]
for key,p in programs.items():
    use(p)
    for name, value in [('clipZeroToOne',1), ('deferred',1), ('smoothing',0),
                        ('localActive',0), ('headlightActive',0), ('objectiveLightCount',0),
                        ('mobileShadowActive',0), ('mobileCascadeSourceActive',0),
                        ('mobileDirectSourceActive',0)]:
        ui(loc(p,name.encode()),value)
    u2(loc(p,b'mapSize'),4096,4096); u2(loc(p,b'heightRange'),0,128)
    uf(loc(p,b'strength'),2); uf(loc(p,b'nightIntensity'),1)
    m4(loc(p,b'inverseProjection'),1,0,projection.ctypes.data)
    m4(loc(p,b'inverseView'),1,0,view.ctypes.data)
    if key == 'baseline': ui(loc(p,b'windowActive'),1)
    else: uf(loc(p,b'windowGain'),1)

fbo=U(); fn(G,'glGenFramebuffers',None,I,P)(1,C.byref(fbo))
fn(G,'glBindFramebuffer',None,U,U)(0x8D40,fbo.value)
fn(G,'glActiveTexture',None,U)(0x84C0+15)
fn(G,'glEnable',None,U)(0x0BE2); fn(G,'glBlendFunc',None,U,U)(1,1)
for state in [0x0B71,0x0B44,0x0BC0]: fn(G,'glDisable',None,U)(state)
fn(G,'glClearColor',None,F,F,F,F)(0,0,0,0)
quad=fn(G,'glGenLists',U,I)(1)
fn(G,'glNewList',None,U,U)(quad,0x1300)
clear(0x4000); begin(7)
for x,y,u,v in [(-1,-1,0,0),(1,-1,1,0),(1,1,1,1),(-1,1,0,1)]:
    uv(u,v); vertex(x,y)
end(); fn(G,'glEndList',None)()
query=U(); fn(G,'glGenQueries',None,I,P)(1,C.byref(query))


def target(w,h):
    output=texture(w,h)
    fn(G,'glFramebufferTexture2D',None,U,U,U,U,I)(0x8D40,0x8CE0,0x0DE1,output,0)
    assert fn(G,'glCheckFramebufferStatus',U,U)(0x8D40)==0x8CD5
    fn(G,'glViewport',None,I,I,I,I)(0,0,w,h)
    return output


def pixels(w,h):
    out=np.empty((h,w,4),dtype='f4')
    fn(G,'glReadPixels',None,I,I,I,I,U,U,P)(0,0,w,h,0x1908,0x1406,out.ctypes.data)
    assert error()==0
    return out


def measure(key, repetitions):
    use(programs[key]); finish()
    begin_query(0x88BF,query.value)
    start=time.perf_counter_ns()
    for _ in range(repetitions): call(quad)
    submitted=time.perf_counter_ns()
    end_query(0x88BF)
    elapsed=C.c_uint64(); query_result(query.value,0x8866,C.byref(elapsed))
    done=time.perf_counter_ns(); assert error()==0
    return {'gl_elapsed_ms':elapsed.value/1e6/repetitions,
            'submission_ms':(submitted-start)/1e6/repetitions,
            'wall_ms':(done-start)/1e6/repetitions}


target(128,128)
measure('baseline',1); original=pixels(128,128)
measure('patched',1); ratio_one=pixels(128,128)
assert np.array_equal(original,ratio_one), 'ratio 1 changed baseline output'
# Sample textures are RGBA16F. Account for their actual stored values.
cascade=np.asarray([.2,.1,.05],dtype='f2').astype('f4')
window=np.asarray([.3,.2,.1],dtype='f2').astype('f4')
checks=[]
for ratio in [0,0.5,1,2]:
    use(programs['patched']); uf(loc(programs['patched'],b'windowGain'),ratio)
    measure('patched',1); out=pixels(128,128)
    expected=1-np.exp(-(cascade+window*ratio)*2)
    assert np.allclose(out[:,:,:3],expected,atol=6e-4,rtol=0), (ratio,out[64,64],expected)
    assert np.isfinite(out).all() and out[:,:,:3].min()>=0
    checks.append({'gain_ratio':ratio,'linear_expected':(cascade+window*ratio).tolist(),
                   'output_rgb':out[64,64,:3].tolist()})
uf(loc(programs['patched'],b'windowGain'),1)
report={'baseline_ref':args.baseline_ref,
        'renderer':fn(G,'glGetString',C.c_char_p,U)(0x1F01).decode(),
        'version':fn(G,'glGetString',C.c_char_p,U)(0x1F02).decode(),
        'llvmpipe_threads':os.environ.get('LP_NUM_THREADS','driver default'),
        'rounds':args.rounds,'repetitions':args.repetitions,
        'scope':'Full production mobile-capable scene shaders; synthetic ground view, '
                'window contribution enabled; other optional lights disabled; '
                'fixed positive 64x64 textures; additive fullscreen draw into RGBA16F. '
                'These software-renderer timings are not physical-GPU/FPS measurements.',
        'ratio_one_bit_identical':True,'ratio_checks':checks,'timings':[]}
for width,height in [(1280,720),(1920,1080)]:
    target(width,height)
    for key in programs: measure(key,4)
    samples={key:[] for key in programs}
    for index in range(args.rounds):
        order=['baseline','patched'] if index%2==0 else ['patched','baseline']
        for key in order: samples[key].append(measure(key,args.repetitions))
    medians={key:{metric:statistics.median(s[metric] for s in values)
                  for metric in values[0]} for key,values in samples.items()}
    paired={metric:[b[metric]-a[metric] for a,b in zip(samples['baseline'],samples['patched'])]
            for metric in samples['baseline'][0]}
    report['timings'].append({'resolution':[width,height],'medians':medians,
        'paired_delta_medians_ms':{metric:statistics.median(v) for metric,v in paired.items()},
        'paired_wall_delta_p25_p75_ms':np.percentile(paired['wall_ms'],[25,75]).tolist()})
assert error()==0
print(json.dumps(report,indent=2))
