"""Small dependency-free EGL compatibility context for the railgun GPU regression.

Uses Mesa EGL/GL and NumPy already used by the effect tests. It deliberately
submits the compatibility vertex attributes used by Spring's Lua GL API.
"""
import ctypes as C
import os

os.environ.setdefault('LIBGL_ALWAYS_SOFTWARE', '1')
os.environ.setdefault('MESA_GL_VERSION_OVERRIDE', '3.3COMPAT')
os.environ.setdefault('MESA_SHADER_CACHE_DISABLE', 'true')
import numpy as np


class HeadlessGL:
    def __init__(self, width=512, height=256):
        self.width, self.height = width, height
        self.egl = C.CDLL('libEGL.so.1')
        self.gl = C.CDLL('libGL.so.1')
        e, g = self.egl, self.gl
        def bind(lib, name, result, *args):
            f = getattr(lib, name)
            f.restype, f.argtypes = result, list(args)
            return f
        self.bind = bind
        bind(e, 'eglGetProcAddress', C.c_void_p, C.c_char_p)
        address = e.eglGetProcAddress(b'eglGetPlatformDisplayEXT')
        if not address:
            raise RuntimeError('EGL surfaceless display extension unavailable')
        getdisplay = C.CFUNCTYPE(C.c_void_p, C.c_uint, C.c_void_p, C.POINTER(C.c_int))(address)
        self.display = getdisplay(0x31DD, None, None)
        bind(e, 'eglInitialize', C.c_uint, C.c_void_p, C.POINTER(C.c_int), C.POINTER(C.c_int))
        major, minor = C.c_int(), C.c_int()
        if not e.eglInitialize(self.display, C.byref(major), C.byref(minor)):
            raise RuntimeError('EGL initialization failed')
        bind(e, 'eglBindAPI', C.c_uint, C.c_uint)
        assert e.eglBindAPI(0x30A2), 'OpenGL API unavailable'
        attrs = (C.c_int * 15)(0x3033, 1, 0x3040, 8, 0x3024, 8, 0x3023, 8, 0x3022, 8, 0x3021, 8, 0x3025, 24, 0x3038)
        config, count = C.c_void_p(), C.c_int()
        bind(e, 'eglChooseConfig', C.c_uint, C.c_void_p, C.POINTER(C.c_int), C.POINTER(C.c_void_p), C.c_int, C.POINTER(C.c_int))
        assert e.eglChooseConfig(self.display, attrs, C.byref(config), 1, C.byref(count)) and count.value, 'No EGL configuration'
        bind(e, 'eglCreatePbufferSurface', C.c_void_p, C.c_void_p, C.c_void_p, C.POINTER(C.c_int))
        surface_attrs = (C.c_int * 5)(0x3057, width, 0x3056, height, 0x3038)
        self.surface = e.eglCreatePbufferSurface(self.display, config, surface_attrs)
        bind(e, 'eglCreateContext', C.c_void_p, C.c_void_p, C.c_void_p, C.c_void_p, C.POINTER(C.c_int))
        context_attrs = (C.c_int * 7)(0x3098, 3, 0x30FB, 3, 0x30FD, 2, 0x3038)
        self.context = e.eglCreateContext(self.display, config, None, context_attrs)
        assert self.surface and self.context, 'OpenGL compatibility context unavailable'
        bind(e, 'eglMakeCurrent', C.c_uint, C.c_void_p, C.c_void_p, C.c_void_p, C.c_void_p)
        assert e.eglMakeCurrent(self.display, self.surface, self.surface, self.context)
        ui, i, f, d, ptr = C.c_uint, C.c_int, C.c_float, C.c_double, C.c_void_p
        for name, result, args in [
            ('glGetString', C.c_char_p, [ui]), ('glGetError', ui, []),
            ('glCreateShader', ui, [ui]), ('glShaderSource', None, [ui, i, C.POINTER(C.c_char_p), C.POINTER(i)]),
            ('glCompileShader', None, [ui]), ('glGetShaderiv', None, [ui, ui, C.POINTER(i)]),
            ('glGetShaderInfoLog', None, [ui, i, C.POINTER(i), ptr]), ('glDeleteShader', None, [ui]),
            ('glCreateProgram', ui, []), ('glAttachShader', None, [ui, ui]), ('glLinkProgram', None, [ui]),
            ('glGetProgramiv', None, [ui, ui, C.POINTER(i)]), ('glGetProgramInfoLog', None, [ui, i, C.POINTER(i), ptr]),
            ('glUseProgram', None, [ui]), ('glDeleteProgram', None, [ui]),
            ('glGetUniformLocation', i, [ui, C.c_char_p]), ('glUniform1f', None, [i, f]),
            ('glUniform2f', None, [i, f, f]), ('glUniform3f', None, [i, f, f, f]), ('glUniform4f', None, [i, f, f, f, f]),
            ('glGenTextures', None, [i, C.POINTER(ui)]), ('glBindTexture', None, [ui, ui]),
            ('glTexImage2D', None, [ui, i, i, i, i, i, ui, ui, ptr]), ('glTexParameteri', None, [ui, ui, i]),
            ('glGenFramebuffers', None, [i, C.POINTER(ui)]), ('glBindFramebuffer', None, [ui, ui]),
            ('glFramebufferTexture2D', None, [ui, ui, ui, ui, i]), ('glCheckFramebufferStatus', ui, [ui]),
            ('glGenRenderbuffers', None, [i, C.POINTER(ui)]), ('glBindRenderbuffer', None, [ui, ui]),
            ('glRenderbufferStorage', None, [ui, ui, i, i]), ('glFramebufferRenderbuffer', None, [ui, ui, ui, ui]),
            ('glDeleteTextures', None, [i, C.POINTER(ui)]), ('glDeleteFramebuffers', None, [i, C.POINTER(ui)]),
            ('glDeleteRenderbuffers', None, [i, C.POINTER(ui)]),
            ('glViewport', None, [i, i, i, i]), ('glClearColor', None, [f, f, f, f]),
            ('glClearDepth', None, [d]), ('glClear', None, [ui]), ('glEnable', None, [ui]), ('glDisable', None, [ui]),
            ('glBlendFunc', None, [ui, ui]), ('glDepthMask', None, [C.c_ubyte]), ('glDepthFunc', None, [ui]),
            ('glMatrixMode', None, [ui]), ('glLoadIdentity', None, []), ('glOrtho', None, [d, d, d, d, d, d]),
            ('glBegin', None, [ui]), ('glEnd', None, []), ('glVertex3f', None, [f, f, f]), ('glVertex4f', None, [f, f, f, f]),
            ('glColor4f', None, [f, f, f, f]), ('glMultiTexCoord4f', None, [ui, f, f, f, f]),
            ('glReadPixels', None, [i, i, i, i, ui, ui, ptr]), ('glFinish', None, []),
        ]:
            bind(g, name, result, *args)
        self.texture, self.fbo, self.depth = ui(), ui(), ui()
        g.glGenTextures(1, C.byref(self.texture)); g.glBindTexture(0x0DE1, self.texture)
        g.glTexParameteri(0x0DE1, 0x2801, 0x2600); g.glTexParameteri(0x0DE1, 0x2800, 0x2600)
        g.glTexImage2D(0x0DE1, 0, 0x8814, width, height, 0, 0x1908, 0x1406, None)
        g.glGenFramebuffers(1, C.byref(self.fbo)); g.glBindFramebuffer(0x8D40, self.fbo)
        g.glFramebufferTexture2D(0x8D40, 0x8CE0, 0x0DE1, self.texture, 0)
        g.glGenRenderbuffers(1, C.byref(self.depth)); g.glBindRenderbuffer(0x8D41, self.depth)
        g.glRenderbufferStorage(0x8D41, 0x81A6, width, height)
        g.glFramebufferRenderbuffer(0x8D40, 0x8D00, 0x8D41, self.depth)
        assert g.glCheckFramebufferStatus(0x8D40) == 0x8CD5, 'Float framebuffer incomplete'
        g.glViewport(0, 0, width, height)
        g.glEnable(0x0BE2); g.glBlendFunc(1, 0x0303)
        g.glEnable(0x0B71); g.glDepthFunc(0x0201)
        self.programs = []
        self.check()

    @property
    def renderer(self):
        return self.gl.glGetString(0x1F01).decode()

    def program(self, vertex, fragment):
        g = self.gl
        shaders = []
        for kind, source in [(0x8B31, vertex), (0x8B30, fragment)]:
            shader = g.glCreateShader(kind)
            text = C.c_char_p(source.encode())
            g.glShaderSource(shader, 1, C.byref(text), None); g.glCompileShader(shader)
            ok = C.c_int(); g.glGetShaderiv(shader, 0x8B81, C.byref(ok))
            if not ok.value:
                log = C.create_string_buffer(16384)
                g.glGetShaderInfoLog(shader, len(log), None, log)
                raise AssertionError(log.value.decode())
            shaders.append(shader)
        program = g.glCreateProgram()
        for shader in shaders:
            g.glAttachShader(program, shader)
        g.glLinkProgram(program)
        ok = C.c_int(); g.glGetProgramiv(program, 0x8B82, C.byref(ok))
        if not ok.value:
            log = C.create_string_buffer(16384)
            g.glGetProgramInfoLog(program, len(log), None, log)
            raise AssertionError(log.value.decode())
        for shader in shaders:
            g.glDeleteShader(shader)
        self.programs.append(program)
        return program

    def uniform(self, program, name, *values):
        self.gl.glUseProgram(program)
        location = self.gl.glGetUniformLocation(program, name.encode())
        assert location >= 0, 'Active uniform missing: ' + name
        getattr(self.gl, 'glUniform%df' % len(values))(location, *values)

    def ortho(self, left, right, bottom, top, near=-100, far=100):
        self.gl.glMatrixMode(0x1701); self.gl.glLoadIdentity()
        self.gl.glOrtho(left, right, bottom, top, near, far)
        self.gl.glMatrixMode(0x1700); self.gl.glLoadIdentity()

    def clear(self):
        self.gl.glDepthMask(1); self.gl.glClearDepth(1)
        self.gl.glClearColor(0, 0, 0, 0); self.gl.glClear(0x4000 | 0x0100)
        self.gl.glDepthMask(0)

    def read(self):
        result = np.zeros((self.height, self.width, 4), dtype=np.float32)
        self.gl.glFinish()
        self.gl.glReadPixels(0, 0, self.width, self.height, 0x1908, 0x1406, result.ctypes.data_as(C.c_void_p))
        self.check()
        assert np.isfinite(result).all(), 'Non-finite shader output'
        return result

    def check(self):
        error = self.gl.glGetError()
        assert error == 0, 'OpenGL error 0x%x' % error

    def close(self):
        for program in self.programs:
            self.gl.glDeleteProgram(program)
        self.gl.glDeleteRenderbuffers(1, C.byref(self.depth))
        self.gl.glDeleteFramebuffers(1, C.byref(self.fbo))
        self.gl.glDeleteTextures(1, C.byref(self.texture))
        self.egl.eglMakeCurrent(self.display, None, None, None)
        for name in ['eglDestroyContext', 'eglDestroySurface']:
            self.bind(self.egl, name, C.c_uint, C.c_void_p, C.c_void_p)
        self.egl.eglDestroyContext(self.display, self.context)
        self.egl.eglDestroySurface(self.display, self.surface)
        self.bind(self.egl, 'eglTerminate', C.c_uint, C.c_void_p)
        self.egl.eglTerminate(self.display)


if __name__ == '__main__':
    context = HeadlessGL()
    print('Headless OpenGL available:', context.renderer)
    context.close()
