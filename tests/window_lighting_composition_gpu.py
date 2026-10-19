"""Narrow atlas-composition benchmark with production copy.frag and EGL.

Run from the repository root: python3 tests/window_lighting_composition_gpu.py
Needs numpy and Mesa EGL. This is not a Recoil frame-rate benchmark. On
llvmpipe the OpenGL elapsed-time query measures the software renderer, not a
physical GPU. No projection work, scene composition, or Lua overhead is timed.
"""
import argparse
import ctypes as C
import json
import statistics
import time
from pathlib import Path

import numpy as np

# Reuse the existing, small compatibility-context/shader setup only.
exec(Path('tests/world_rain_gpu.py').read_text().split('root=Path(__file__)')[0])

ATLAS, FIELD = 1024, 256
use = fn(G, 'glUseProgram', None, U)
loc = fn(G, 'glGetUniformLocation', I, U, C.c_char_p)
ui = fn(G, 'glUniform1i', None, I, I)
uf = fn(G, 'glUniform1f', None, I, F)
bind = fn(G, 'glBindTexture', None, U, U)
clear = fn(G, 'glClear', None, U)
begin = fn(G, 'glBegin', None, U)
end = fn(G, 'glEnd', None)
vertex = fn(G, 'glVertex2f', None, F, F)
uv = fn(G, 'glTexCoord2f', None, F, F)
call = fn(G, 'glCallList', None, U)
finish = fn(G, 'glFinish', None)
error = fn(G, 'glGetError', U)
begin_query = fn(G, 'glBeginQuery', None, U, U)
end_query = fn(G, 'glEndQuery', None, U)
query_result = fn(G, 'glGetQueryObjectui64v', None, U, U, P)


def texture(w, h, data=None):
    tex = U()
    fn(G, 'glGenTextures', None, I, P)(1, C.byref(tex))
    bind(0x0DE1, tex.value)
    for key in [0x2800, 0x2801]:
        fn(G, 'glTexParameteri', None, U, U, I)(0x0DE1, key, 0x2601)
    for key in [0x2802, 0x2803]:
        fn(G, 'glTexParameteri', None, U, U, I)(0x0DE1, key, 0x812F)
    fn(G, 'glTexImage2D', None, U, I, I, I, I, I, U, U, P)(
        0x0DE1, 0, 0x881A, w, h, 0, 0x1908, 0x1406,
        None if data is None else data.ctypes.data)
    return tex.value


atlas = texture(ATLAS, ATLAS)
fbo = U()
fn(G, 'glGenFramebuffers', None, I, P)(1, C.byref(fbo))
fn(G, 'glBindFramebuffer', None, U, U)(0x8D40, fbo.value)
fn(G, 'glFramebufferTexture2D', None, U, U, U, U, I)(
    0x8D40, 0x8CE0, 0x0DE1, atlas, 0)
assert fn(G, 'glCheckFramebufferStatus', U, U)(0x8D40) == 0x8CD5
fn(G, 'glViewport', None, I, I, I, I)(0, 0, ATLAS, ATLAS)
flat_vertex = ('#version 150 compatibility\n'
               'void main(){gl_Position=gl_Vertex;gl_TexCoord[0]=gl_MultiTexCoord0;}')
copy_program = program(flat_vertex, Path(
    'luaui/widgets_mosaic/shaders/windowlight/copy.frag').read_text())
ui(loc(copy_program, b'sourceTex'), 0)
ui(loc(copy_program, b'channel'), -1)
uf(loc(copy_program, b'gain'), 1)
uf(loc(copy_program, b'minimumLight'), 0.002)
fn(G, 'glActiveTexture', None, U)(0x84C0)
fn(G, 'glEnable', None, U)(0x0BE2)
fn(G, 'glBlendFunc', None, U, U)(1, 1)
fn(G, 'glDisable', None, U)(0x0B71)
fn(G, 'glDisable', None, U)(0x0B44)
fn(G, 'glClearColor', None, F, F, F, F)(0, 0, 0, 0)
yy, xx = np.indices((FIELD, FIELD))
profile = np.maximum(0, 1 - ((xx-127.5)**2+(yy-127.5)**2)/128**2)
fields = []
for index in range(32):
    data = np.zeros((FIELD, FIELD, 4), dtype='f4')
    data[:, :, :3] = profile[:, :, None] * np.array(
        [0.15 + index/200, 0.07, 0.025], dtype='f4')
    fields.append(texture(FIELD, FIELD, data))


def composition_list(count, footprint):
    """Exact copy shader; finite square fields spread across the map atlas.

    Display lists avoid timing hundreds of Python/ctypes vertex calls. They
    intentionally exclude Spring/Lua submission overhead and framebuffer binds.
    """
    listing = fn(G, 'glGenLists', U, I)(1)
    fn(G, 'glNewList', None, U, U)(listing, 0x1300)
    clear(0x4000)
    for index in range(count):
        cx = ((index % 8) + 0.5) / 8
        cy = ((index // 8) + 0.5) / 4
        half = footprint / (2*ATLAS)
        x0, y0 = 2*(cx-half)-1, 2*(cy-half)-1
        x1, y1 = 2*(cx+half)-1, 2*(cy+half)-1
        bind(0x0DE1, fields[index])
        begin(7)
        for x, y, u, v in [(x0,y0,0,0), (x1,y0,1,0),
                           (x1,y1,1,1), (x0,y1,0,1)]:
            uv(u, v)
            vertex(x, y)
        end()
    fn(G, 'glEndList', None)()
    return listing


query = U()
fn(G, 'glGenQueries', None, I, P)(1, C.byref(query))
bits = I()
fn(G, 'glGetQueryiv', None, U, U, P)(0x88BF, 0x8864, C.byref(bits))
assert bits.value > 0, 'GL_TIME_ELAPSED unsupported'


def measure(sequence, repetitions):
    finish()
    begin_query(0x88BF, query.value)
    start = time.perf_counter_ns()
    for _ in range(repetitions):
        for listing in sequence:
            call(listing)
    submitted = time.perf_counter_ns()
    end_query(0x88BF)
    elapsed = C.c_uint64()
    query_result(query.value, 0x8866, C.byref(elapsed))
    done = time.perf_counter_ns()
    assert error() == 0
    return {'gl_elapsed_ms': elapsed.value / 1e6 / repetitions,
            'submission_ms': (submitted-start) / 1e6 / repetitions,
            'wall_ms': (done-start) / 1e6 / repetitions}


def pixels():
    out = np.empty((ATLAS, ATLAS, 4), dtype='f4')
    fn(G, 'glReadPixels', None, I, I, I, I, U, U, P)(
        0, 0, ATLAS, ATLAS, 0x1908, 0x1406, out.ctypes.data)
    assert error() == 0
    return out


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--rounds', type=int, default=11)
parser.add_argument('--repetitions', type=int, default=4)
parser.add_argument('--case', choices=['cold_32', 'warm_32_rebuild', 'removal_3_to_2'])
args = parser.parse_args()
assert args.rounds > 0 and args.repetitions > 0
report = {'renderer': fn(G, 'glGetString', C.c_char_p, U)(0x1F01).decode(),
          'version': fn(G, 'glGetString', C.c_char_p, U)(0x1F02).decode(),
          'atlas': '1024x1024 RGBA16F', 'fields': '32 x 256x256 RGBA16F',
          'filter': 'LINEAR', 'gain': 1, 'minimumLight': 0.002,
          'rounds': args.rounds, 'repetitions': args.repetitions,
          'timing_scope': 'Atlas clears and exact production copy.frag draws; '
                          'display lists exclude Lua, engine and most Python overhead. '
                          'Software-renderer timing is not a hardware GPU/FPS claim.',
          'timing_caution': 'On llvmpipe, GL elapsed queries do not represent all '
                            'software-driver costs. Compare completed wall time as well. '
                            'Small query deltas with quartiles spanning zero are unresolved.',
          'cases': []}
for footprint in [128, 256]:
    listings = {n: composition_list(n, footprint) for n in range(1, 33)}
    cases = [('cold_32', list(range(1,33)), list(range(1,33))),
             ('warm_32_rebuild', list(range(1,33)), [32]),
             ('removal_3_to_2', [1,2], [2,2])]
    for name, baseline_counts, patched_counts in cases:
        if args.case and name != args.case:
            continue
        sequences = {'baseline': [listings[n] for n in baseline_counts],
                     'patched': [listings[n] for n in patched_counts]}
        # Warm both paths, and verify matching completed output outside timing.
        outputs = []
        for sequence in sequences.values():
            measure(sequence, 2)
            outputs.append(pixels())
        assert np.array_equal(*outputs), (name, 'final composition differs')
        assert outputs[0][:,:,:3].max() > 0, 'empty benchmark output'
        samples = {key: [] for key in sequences}
        for round_index in range(args.rounds):
            order = ['baseline', 'patched'] if round_index % 2 == 0 else ['patched', 'baseline']
            for key in order:
                samples[key].append(measure(sequences[key], args.repetitions))
        medians = {key: {metric: statistics.median(s[metric] for s in values)
                         for metric in values[0]} for key, values in samples.items()}
        paired_deltas = {metric: [b[metric]-a[metric] for a,b in
                                 zip(samples['baseline'], samples['patched'])]
                         for metric in samples['baseline'][0]}
        report['cases'].append({'case': name, 'field_footprint_atlas_pixels': footprint,
                                'atlas_passes': [len(baseline_counts),len(patched_counts)],
                                'quad_copies': [sum(baseline_counts),sum(patched_counts)],
                                'medians': medians,
                                'gl_patched_minus_baseline_ms': medians['patched']['gl_elapsed_ms']-
                                                               medians['baseline']['gl_elapsed_ms'],
                                'paired_delta_medians_ms': {metric: statistics.median(values)
                                                            for metric,values in paired_deltas.items()},
                                'paired_gl_delta_p25_p75_ms': np.percentile(
                                    paired_deltas['gl_elapsed_ms'], [25,75]).tolist(),
                                'final_pixels_identical': True})
    for listing in listings.values():
        fn(G, 'glDeleteLists', None, U, I)(listing, 1)
assert error() == 0
print(json.dumps(report, indent=2))
