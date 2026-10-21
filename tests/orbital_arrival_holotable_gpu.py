"""Check the actual transition compositor against the pre-feature compositor.

Requires NumPy, libEGL and libGL; Pillow is optional for image previews.
Run from any directory. No engine, camera, shader transpilation or concept art
is involved. Optional images are inputs to the production compositor only.

python3 tests/orbital_arrival_holotable_gpu.py --width 1280 --height 720
python3 tests/orbital_arrival_holotable_gpu.py --art loading.png --orbit orbit.png --preview-dir /tmp/holo
"""
import argparse
import ctypes as C
import hashlib
import os
from pathlib import Path

import numpy as np


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--width', type=int, default=640)
    parser.add_argument('--height', type=int, default=360)
    parser.add_argument('--preview-dir', type=Path)
    parser.add_argument('--art', type=Path)
    parser.add_argument('--orbit', type=Path)
    args = parser.parse_args()
    if not (0 < args.width <= 4096 and 0 < args.height <= 4096):
        parser.error('dimensions must be between 1 and 4096')
    if bool(args.art) != bool(args.orbit):
        parser.error('--art and --orbit must be supplied together')
    width, height = args.width, args.height
    os.environ.setdefault('EGL_PLATFORM', 'surfaceless')
    egl, gl = C.CDLL('libEGL.so.1'), C.CDLL('libGL.so.1')
    I, U, F, P = C.c_int, C.c_uint, C.c_float, C.c_void_p

    def bind(lib, name, result, arguments):
        function = getattr(lib, name)
        function.restype, function.argtypes = result, arguments
        return function

    for name, result, arguments in (
        ('eglGetDisplay', P, [P]),
        ('eglInitialize', U, [P, C.POINTER(I), C.POINTER(I)]),
        ('eglBindAPI', U, [U]),
        ('eglChooseConfig', U, [P, C.POINTER(I), C.POINTER(P), I, C.POINTER(I)]),
        ('eglCreateContext', P, [P, P, P, C.POINTER(I)]),
        ('eglCreatePbufferSurface', P, [P, P, C.POINTER(I)]),
        ('eglMakeCurrent', U, [P, P, P, P]),
    ):
        bind(egl, name, result, arguments)
    display = egl.eglGetDisplay(None)
    assert egl.eglInitialize(display, C.byref(I()), C.byref(I())), 'EGL initialization failed'
    assert egl.eglBindAPI(0x30A2), 'OpenGL API unavailable'
    config, count = P(), I()
    attributes = (I * 13)(0x3033, 1, 0x3040, 8, 0x3024, 8, 0x3023, 8, 0x3022, 8, 0x3021, 8, 0x3038)
    assert egl.eglChooseConfig(display, attributes, C.byref(config), 1, C.byref(count)) and count.value
    context = egl.eglCreateContext(display, config, None, (I * 7)(0x3098, 3, 0x30FB, 3, 0x30FD, 2, 0x3038))
    surface = egl.eglCreatePbufferSurface(display, config, (I * 5)(0x3057, 1, 0x3056, 1, 0x3038))
    assert context and surface and egl.eglMakeCurrent(display, surface, surface, context)
    for name, result, arguments in (
        ('glCreateShader', U, [U]), ('glShaderSource', None, [U, I, C.POINTER(C.c_char_p), P]),
        ('glCompileShader', None, [U]), ('glGetShaderiv', None, [U, U, C.POINTER(I)]),
        ('glGetShaderInfoLog', None, [U, I, P, C.c_char_p]), ('glCreateProgram', U, []),
        ('glAttachShader', None, [U, U]), ('glLinkProgram', None, [U]),
        ('glGetProgramiv', None, [U, U, C.POINTER(I)]),
        ('glGetProgramInfoLog', None, [U, I, P, C.c_char_p]), ('glUseProgram', None, [U]),
        ('glGetUniformLocation', I, [U, C.c_char_p]), ('glUniform1f', None, [I, F]),
        ('glUniform1i', None, [I, I]), ('glUniform2f', None, [I, F, F]),
        ('glGenTextures', None, [I, C.POINTER(U)]), ('glBindTexture', None, [U, U]),
        ('glTexImage2D', None, [U, I, I, I, I, I, U, U, P]),
        ('glTexParameteri', None, [U, U, I]), ('glActiveTexture', None, [U]),
        ('glGenFramebuffers', None, [I, C.POINTER(U)]), ('glBindFramebuffer', None, [U, U]),
        ('glFramebufferTexture2D', None, [U, U, U, U, I]),
        ('glCheckFramebufferStatus', U, [U]), ('glViewport', None, [I, I, I, I]),
        ('glBegin', None, [U]), ('glEnd', None, []), ('glTexCoord2f', None, [F, F]),
        ('glVertex2f', None, [F, F]), ('glReadPixels', None, [I, I, I, I, U, U, P]),
        ('glDisable', None, [U]), ('glGetError', U, []), ('glGetString', C.c_char_p, [U]),
    ):
        bind(gl, name, result, arguments)
    print('GL:', gl.glGetString(0x1F02).decode(), gl.glGetString(0x1F01).decode(), flush=True)

    def compile_shader(kind, source):
        shader = gl.glCreateShader(kind)
        pointer = C.c_char_p(source.encode())
        gl.glShaderSource(shader, 1, C.byref(pointer), None)
        gl.glCompileShader(shader)
        status = I()
        gl.glGetShaderiv(shader, 0x8B81, C.byref(status))
        if not status.value:
            log = C.create_string_buffer(65536)
            gl.glGetShaderInfoLog(shader, len(log), None, log)
            raise AssertionError(log.value.decode())
        return shader

    vertex = '#version 150 compatibility\nvoid main(){gl_Position=gl_Vertex;gl_TexCoord[0]=gl_MultiTexCoord0;}'

    def program(source):
        result = gl.glCreateProgram()
        gl.glAttachShader(result, compile_shader(0x8B31, vertex))
        gl.glAttachShader(result, compile_shader(0x8B30, source))
        gl.glLinkProgram(result)
        status = I()
        gl.glGetProgramiv(result, 0x8B82, C.byref(status))
        if not status.value:
            log = C.create_string_buffer(65536)
            gl.glGetProgramInfoLog(result, len(log), None, log)
            raise AssertionError(log.value.decode())
        return result

    root = Path(__file__).resolve().parents[1]
    production_source = (root / 'luaui/widgets_mosaic/shaders/orbital_arrival_composite.frag').read_text()
    baseline_bytes = (root / 'tests/fixtures/orbital_arrival_composite_before_holotable.frag').read_bytes()
    # Lock the comparison to the exact approved compositor from master 473e16e.
    header = b'blob ' + str(len(baseline_bytes)).encode() + b'\0'
    assert hashlib.sha1(header + baseline_bytes).hexdigest() == '560904b32713e5028c57184e79cb43db0c0caec4'
    production, baseline = program(production_source), program(baseline_bytes.decode())

    def texture(data):
        data = np.ascontiguousarray(data, dtype='f4')
        result = U()
        gl.glGenTextures(1, C.byref(result))
        gl.glBindTexture(0x0DE1, result.value)
        gl.glTexImage2D(0x0DE1, 0, 0x8814, data.shape[1], data.shape[0], 0, 0x1908, 0x1406, data.ctypes.data)
        for key, value in ((0x2801, 0x2601), (0x2800, 0x2601), (0x2802, 0x812F), (0x2803, 0x812F)):
            gl.glTexParameteri(0x0DE1, key, value)
        return result.value

    y, x = np.mgrid[0:height, 0:width]
    orbit = np.ones((height, width, 4), dtype='f4')
    orbit[:, :, 0], orbit[:, :, 1], orbit[:, :, 2] = x / width, y / height, ((x // 23 + y // 17) % 2) * .5
    orbit[:, :, 3] = .31
    artwork = orbit.copy()
    artwork[:, :, :3] = artwork[:, :, :3][:, :, ::-1] * .72 + .12
    live = np.ones_like(orbit)
    live[:, :, :3] = np.roll(orbit[:, :, :3], width // 3, axis=1) * .82
    textures = [texture(data) for data in (orbit, artwork, live)]
    other_art = texture(np.full_like(orbit, .02))
    other_live = texture(np.full_like(orbit, .91))
    output = texture(np.zeros_like(orbit))
    fbo = U()
    gl.glGenFramebuffers(1, C.byref(fbo))
    gl.glBindFramebuffer(0x8D40, fbo.value)
    gl.glFramebufferTexture2D(0x8D40, 0x8CE0, 0x0DE1, output, 0)
    assert gl.glCheckFramebufferStatus(0x8D40) == 0x8CD5, 'Incomplete framebuffer'
    gl.glViewport(0, 0, width, height)
    gl.glDisable(0x0BE2)
    gl.glDisable(0x0B71)

    def render(shader, fade=1., descent=0., has_art=1, has_live=1, art_scale=(1., 1.), inputs=None):
        gl.glUseProgram(shader)
        for unit, tex in enumerate(inputs or textures):
            gl.glActiveTexture(0x84C0 + unit)
            gl.glBindTexture(0x0DE1, tex)
        for name, value in (('orbitTex', 0), ('artworkTex', 1), ('liveTex', 2), ('hasArtwork', has_art), ('hasLive', has_live)):
            gl.glUniform1i(gl.glGetUniformLocation(shader, name.encode()), value)
        for name, value in (('fade', fade), ('descent', descent)):
            gl.glUniform1f(gl.glGetUniformLocation(shader, name.encode()), value)
        gl.glUniform2f(gl.glGetUniformLocation(shader, b'artScale'), *art_scale)
        gl.glBegin(7)
        for px, py, u, v in ((-1, -1, 0, 0), (1, -1, 1, 0), (1, 1, 1, 1), (-1, 1, 0, 1)):
            gl.glTexCoord2f(u, v)
            gl.glVertex2f(px, py)
        gl.glEnd()
        data = np.empty_like(orbit)
        gl.glReadPixels(0, 0, width, height, 0x1908, 0x1406, data.ctypes.data)
        assert gl.glGetError() == 0
        assert np.isfinite(data).all() and np.all(data[:, :, 3] == 1), 'Invalid output pixels'
        return data

    # Loading/art endpoints, absence of artwork, every cloud/reveal stage,
    # alternate crops and terminal live texels are compared bit for bit.
    comparisons = 0
    for scale in ((1., 1.), (.72, 1.), (1., .63)):
        for fade in (0., 1.):
            for descent in (0., .16, .43, .52, .65, .80, .96, .985, 1.):
                for has_live in (0, 1):
                    assert np.array_equal(render(production, fade, descent, art_scale=scale, has_live=has_live),
                                          render(baseline, fade, descent, art_scale=scale, has_live=has_live)), 'Changed an accepted endpoint/zoom/reveal frame'
                    comparisons += 1
        for fade in (.12, .45, .82):
            assert np.array_equal(render(production, fade, has_art=0, art_scale=scale),
                                  render(baseline, fade, has_art=0, art_scale=scale)), 'Missing-art fallback changed'
            comparisons += 1
    for fade in (.08, .20, .37, .55, .72, .86, .95):
        result = render(production, fade)
        assert result[:, :, :3].min() >= 0 and result[:, :, :3].max() <= 1
        assert np.array_equal(result, render(production, fade)), 'Transition is not deterministic'
        assert np.array_equal(result, render(production, fade, inputs=[*textures[:2], other_live])), 'Hologram leaked live-map pixels'
        assert np.mean(np.abs(result - render(baseline, fade))) > .005, 'Transition reverted to a simple crossfade'
    # Only sparse survivors still depend on the outgoing picture at late time.
    late = render(production, .74)
    changed = render(production, .74, inputs=[textures[0], other_art, textures[2]])
    affected = np.max(np.abs(late[:, :, :3] - changed[:, :, :3]), axis=2) > .001
    assert .015 < affected.mean() < .30, 'Late artwork is absent or no longer sparse stay-behind tiles'
    assert np.array_equal(render(production, .92), render(production, .92, inputs=[textures[0], other_art, textures[2]])), 'Artwork fragments survive after stabilization'
    # Approach to both endpoints must be continuous, not a final projection snap.
    for endpoint, nearby in ((0., .00001), (1., .99999)):
        assert np.max(np.abs(render(production, endpoint) - render(production, nearby))) < .001, 'Endpoint discontinuity'
    assert np.array_equal(render(production, 1., 1.), live), 'Final native live texels changed'
    print(f'PASS {width}x{height}: {comparisons} exact baseline comparisons; deterministic tiled handover; no live leakage; sparse late tiles {affected.mean():.1%}; clean endpoints', flush=True)

    if args.preview_dir:
        from PIL import Image
        args.preview_dir.mkdir(parents=True, exist_ok=True)

        def read_image(path, framebuffer):
            with Image.open(path) as image:
                data = np.asarray(image.convert('RGBA').resize((width, height)), dtype='f4') / 255.
            return texture(data[::-1] if framebuffer else data)

        preview_inputs = list(textures)
        if args.art:
            preview_inputs[0] = read_image(args.orbit, True)
            preview_inputs[1] = read_image(args.art, False)
        for index, fade in enumerate(np.linspace(0., 1., 31)):
            image = render(production, float(fade), inputs=preview_inputs)
            Image.fromarray((np.clip(image[::-1, :, :3], 0, 1) * 255).astype('uint8')).save(args.preview_dir / f'frame_{index:03d}.png')
        print('Production compositor previews:', args.preview_dir)


if __name__ == '__main__':
    main()
