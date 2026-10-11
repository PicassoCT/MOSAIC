"""Actual Lua 5.1 capture calls under inherited compatibility GL state.

Run with numpy, lupa and Mesa EGL:
  python tests/radiance_capture_state_gpu.py
  python tests/radiance_capture_state_gpu.py --source-ref a91c124f

The second command reproduces the unprotected captures at the offending commit.
An inherited alpha test is an independently reproduced failure mode; this test
does not assert that the user's unobserved driver state had that setting.
"""
import argparse
from pathlib import Path
import subprocess

import numpy as np
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--source-ref")
args = parser.parse_args()
exec((ROOT / "tests/world_rain_gpu.py").read_text().split("root=Path(__file__)")[0])


def read_file(path):
    if args.source_ref:
        return subprocess.check_output(["git", "show", args.source_ref + ":" + path],
                                       cwd=ROOT, text=True)
    return (ROOT / path).read_text()


use = fn(G, "glUseProgram", None, U)
uniform_location = fn(G, "glGetUniformLocation", I, U, C.c_char_p)
enable = fn(G, "glEnable", None, U)
disable = fn(G, "glDisable", None, U)
alpha_func = fn(G, "glAlphaFunc", None, U, F)
active = fn(G, "glActiveTexture", None, U)
bind = fn(G, "glBindTexture", None, U, U)
bind_fbo = fn(G, "glBindFramebuffer", None, U, U)
viewport = fn(G, "glViewport", None, I, I, I, I)
get_int = fn(G, "glGetIntegerv", None, U, P)
matrix = fn(G, "glMatrixMode", None, U)
push = fn(G, "glPushMatrix", None)
pop = fn(G, "glPopMatrix", None)
identity = fn(G, "glLoadIdentity", None)
begin = fn(G, "glBegin", None, U)
end = fn(G, "glEnd", None)
vertex = fn(G, "glVertex3f", None, F, F, F)
texcoord = fn(G, "glTexCoord4f", None, F, F, F, F)
textures, fbos = {}, {}


def create_shader(desc):
    p = create_program()
    for name, kind in (("vertex", 0x8B31), ("geometry", 0x8DD9), ("fragment", 0x8B30)):
        if desc[name]:
            attach(p, shader(kind, desc[name]))
    link(p)
    ok = I()
    get_program(p, 0x8B82, C.byref(ok))
    assert ok.value, "actual Lua shader description failed to link"
    use(p)
    if desc["uniformInt"]:
        for name, value in desc["uniformInt"].items():
            fn(G, "glUniform1i", None, I, I)(uniform_location(p, name.encode()), value)
    use(0)
    fn(G, "glValidateProgram", None, U)(p)
    get_program(p, 0x8B83, C.byref(ok))
    assert ok.value, "actual Lua shader description failed engine-style validation"
    return p


def framebuffer(attachments, depth=None):
    fbo = U()
    fn(G, "glGenFramebuffers", None, I, P)(1, C.byref(fbo))
    bind_fbo(0x8D40, fbo.value)
    for index, texture in enumerate(attachments):
        fn(G, "glFramebufferTexture2D", None, U, U, U, U, I)(0x8D40, 0x8CE0 + index, 0x0DE1, texture, 0)
    if depth:
        fn(G, "glFramebufferTexture2D", None, U, U, U, U, I)(0x8D40, 0x8D00, 0x0DE1, depth, 0)
    fn(G, "glDrawBuffers", None, I, P)(len(attachments), (U * len(attachments))(*range(0x8CE0, 0x8CE0 + len(attachments))))
    assert fn(G, "glCheckFramebufferStatus", U, U)(0x8D40) == 0x8CD5
    bind_fbo(0x8D40, 0)
    return fbo.value


def create_texture(width, height, options):
    width, height = int(width), int(height)
    tex = U()
    fn(G, "glGenTextures", None, I, P)(1, C.byref(tex))
    active(0x84C0)
    bind(0x0DE1, tex.value)
    for key in (0x2800, 0x2801):
        fn(G, "glTexParameteri", None, U, U, I)(0x0DE1, key, 0x2600)
    for key in (0x2802, 0x2803):
        fn(G, "glTexParameteri", None, U, U, I)(0x0DE1, key, 0x812F)
    fmt = int(options["format"] or 0x8814)
    external = 0x1902 if fmt == 0x81A6 else 0x1908
    fn(G, "glTexImage2D", None, U, I, I, I, I, I, U, U, P)(0x0DE1, 0, fmt, width, height, 0, external, 0x1406, None)
    name = "!" + str(tex.value)
    textures[name] = {"id": tex.value, "width": width, "height": height,
                      "fbo": framebuffer([tex.value]) if options["fbo"] else None}
    return name


def create_fbo(desc):
    color = textures[desc["color0"]]
    depth = textures[desc["depth"]]["id"] if desc["depth"] else None
    handle = framebuffer([color["id"]], depth)
    fbos[handle] = dict(color, fbo=handle)
    return handle


def activate(target, callback, *values, restore_fbo=True):
    old_viewport = (I * 4)()
    previous = I()
    get_int(0x0BA2, old_viewport)
    get_int(0x8CA6, C.byref(previous))
    bind_fbo(0x8D40, target["fbo"])
    viewport(0, 0, target["width"], target["height"])
    if not restore_fbo:  # Recoil RenderToTexture supplies identity matrices.
        for mode in (0x1701, 0x1700):
            matrix(mode)
            push()
            identity()
    callback(*values)
    if not restore_fbo:
        for mode in (0x1701, 0x1700):
            matrix(mode)
            pop()
    bind_fbo(0x8D40, previous.value if restore_fbo else 0)
    viewport(*old_viewport)
    assert fn(G, "glGetError", U)() == 0, "capture produced an OpenGL error"


def pixels(name):
    tex = textures[name]
    fbo = tex["fbo"] or framebuffer([tex["id"]])
    bind_fbo(0x8D40, fbo)
    result = np.empty((tex["height"], tex["width"], 4), "f4")
    fn(G, "glReadPixels", None, I, I, I, I, U, U, P)(0, 0, tex["width"], tex["height"], 0x1908, 0x1406, result.ctypes.data)
    bind_fbo(0x8D40, 0)
    assert np.isfinite(result).all()
    return result


def bind_texture(*values):
    slot, name = values if len(values) == 2 else (0, values[0])
    active(0x84C0 + int(slot))
    found = textures.get(name)
    bind(0x0DE1, found["id"] if found else 0)
    active(0x84C0)
    return bool(found)


def clear(mask, *values):
    if mask == 0x4000:
        fn(G, "glClearColor", None, F, F, F, F)(*values)
    elif mask == 0x0100:
        fn(G, "glClearDepth", None, C.c_double)(values[0])
    fn(G, "glClear", None, U)(mask)


def depth_test(value):
    (disable if value is False else enable)(0x0B71)
    if value is not False:
        fn(G, "glDepthFunc", None, U)(0x0201 if value is True else value)


def blend(*values):
    if values[0] is False:
        disable(0x0BE2)
    else:
        enable(0x0BE2)
        fn(G, "glBlendFunc", None, U, U)(*values)


def texrect(x0, y0, x1, y1, u0=0, v0=0, u1=1, v1=1):
    begin(7)
    for x, y, u, v in ((x0, y0, u0, v0), (x1, y0, u1, v0), (x1, y1, u1, v1), (x0, y1, u0, v1)):
        texcoord(u, v, 0, 1)
        vertex(x, y, 0)
    end()


def piece(*_):
    begin(4)
    for x, z in ((92, 56), (108, 56), (108, 72), (92, 56), (108, 72), (92, 72)):
        vertex(x, 64, z)
    end()


lua = LuaRuntime(unpack_returned_tuples=True)
g = lua.globals()
g.readFile = read_file
g.gl = lua.table_from({
    "CreateShader": create_shader, "CreateTexture": create_texture, "CreateFBO": create_fbo,
    "IsValidFBO": lambda *_: True, "GetShaderLog": lambda: "",
    "DeleteShader": lambda p: fn(G, "glDeleteProgram", None, U)(p),
    "DeleteTexture": lambda *_: None, "DeleteFBO": lambda *_: None,
    "RenderToTexture": lambda name, callback, *v: activate(textures[name], callback, *v, restore_fbo=False),
    "ActiveFBO": lambda fbo, callback, *v: activate(fbos[fbo], callback, *v),
    "GetUniformLocation": lambda p, n: uniform_location(p, n.encode()),
    "Uniform": lambda loc, *v: fn(G, "glUniform" + str(len(v)) + "f", None, I, *([F] * len(v)))(loc, *v),
    "UniformInt": lambda loc, *v: fn(G, "glUniform" + str(len(v)) + "i", None, I, *([I] * len(v)))(loc, *v),
    "UseShader": use, "Texture": bind_texture, "Clear": clear, "Viewport": viewport,
    "MatrixMode": matrix, "PushMatrix": push, "PopMatrix": pop, "LoadIdentity": identity,
    "Ortho": fn(G, "glOrtho", None, *([C.c_double] * 6)),
    "Rotate": fn(G, "glRotatef", None, F, F, F, F),
    "Color": fn(G, "glColor4f", None, F, F, F, F),
    "TexCoord": lambda x, y=0, z=0, w=1: texcoord(x, y, z, w),
    "Vertex": lambda x, y, z=0: vertex(x, y, z), "TexRect": texrect,
    "BeginEnd": lambda mode, callback, *v: (begin(mode), callback(*v), end()),
    "DepthMask": lambda value: fn(G, "glDepthMask", None, C.c_ubyte)(bool(value)),
    "DepthTest": depth_test, "Blending": blend,
    "AlphaTest": lambda value: (enable if value else disable)(0x0BC0),
    "Culling": lambda value: (enable if value else disable)(0x0B44),
    "PointSize": fn(G, "glPointSize", None, F),
    "GetViewSizes": lambda: (128, 128), "UnitMultMatrix": lambda *_: None,
    "UnitPieceMultMatrix": lambda *_: None, "UnitPiece": piece,
})
g.GL = lua.table_from(dict(PROJECTION=0x1701, MODELVIEW=0x1700, POINTS=0, QUADS=7,
                          COLOR_BUFFER_BIT=0x4000, DEPTH_BUFFER_BIT=0x0100, ONE=1,
                          LESS=0x0201, RGBA8=0x8058, RGBA16F=0x881A, RGBA32F=0x8814))
lua.execute("""
widget={};WG={};UnitDefs={};Game={mapSizeX=128,mapSizeZ=128,gameSpeed=30}
Spring={GetGameFrame=function()return 1 end,GetDrawFrame=function()return 1 end,
  ValidUnitID=function()return true end,GetUnitIsDead=function()return false end,
  GetUnitDefID=function()return 1 end,GetGroundHeight=function()return 0 end}
VFS={LoadFile=readFile}
function VFS.Include(path,env)
  local fn=assert(loadstring(readFile(path),path));if env then setfenv(fn,env)end;return fn()
end
function upvalue(fn,wanted,value,replace)
  for i=1,100 do local name,current=debug.getupvalue(fn,i)
    if not name then break end
    if name==wanted then if replace then debug.setupvalue(fn,i,value)end;return current end
  end
  error('missing production closure '..wanted)
end
VFS.Include('luaui/widgets_mosaic/gfx_neonlights_radiancecascade.lua')
neonCapture=upvalue(widget.DrawWorldPreUnit,'drawNeonPieces')
upvalue(neonCapture,'neonUnitTables',{[1]={1}},true)
upvalue(neonCapture,'neonLightPercent',1,true)
""")
path = "luaui/widgets_mosaic/shaders/radiancecascade/"
description = {"vertex": read_file(path + "emission_slice.vert"),
               "geometry": read_file(path + "emission_slice.geom"),
               "fragment": read_file(path + "emission_slice.frag")}


def set_mesh_shader(old_alpha=False):
    desc = dict(description)
    if old_alpha:
        desc["fragment"] = desc["fragment"].replace("vec4(color,luminance*sourceHeight/2048.0)", "vec4(color,1.0)")
    p = create_shader(lua.table_from(desc))
    values = {"emissionShader": p}
    for key, uniform in dict(atlasSizeLoc="atlasSize", heightLoc="heightRange",
                             projectToBandLoc="projectToBand", texturedLoc="textured",
                             materialMaskedLoc="materialMasked", emissionStrengthLoc="emissionStrength").items():
        values[key] = uniform_location(p, uniform.encode())
    g.upvalue(g.neonCapture, "propagation", lua.table_from(values), True)


def inherited_alpha(on):
    alpha_func(0x0204, .5)  # GL_GREATER: common cutout-material state.
    (enable if on else disable)(0x0BC0)


target = create_texture(128, 128, lua.table_from({"format": 0x8814, "fbo": True}))


def capture_mesh(alpha):
    inherited_alpha(alpha)
    activate(textures[target], g.neonCapture, 1, restore_fbo=False)
    return pixels(target)


set_mesh_shader()
clean = capture_mesh(False)
affected = capture_mesh(True)
set_mesh_shader(old_alpha=True)
control = capture_mesh(True)
assert clean[:, :, :3].sum() > 0 and np.allclose(control[:, :, :3], clean[:, :, :3])
checks = [("actual Lua neon mesh capture", np.allclose(affected, clean), float(affected[:, :, :3].sum()))]
print("Mesh RGB sums: alpha off", float(clean[:, :, :3].sum()), "inherited alpha", checks[-1][2], "old alpha=1 control", float(control[:, :, :3].sum()))

# The real live-atlas and combat renderer use their own capture entry points.
lua.execute("""
local sources={Collect=function()return {{x=64,y=14,z=64,radius=60,strength=1,color={1,.3,.1}}}end}
combat=VFS.Include('luaui/widgets_mosaic/include/combat_light_renderer.lua')(sources)
live=VFS.Include('luaui/widgets_mosaic/include/headlight_live_field.lua')()
function liveCapture(bottom,top,gain)combat:Capture(bottom,top,gain,1)end
""")
inherited_alpha(False)
g.live.Draw(g.live, g.liveCapture, 0, 128, None, True)
clean_live = pixels(g.live.texture)
inherited_alpha(True)
g.live.Update(g.live, .2)
g.live.Draw(g.live, g.liveCapture, 0, 128, None, True)
affected_live = pixels(g.live.texture)
checks.append(("actual Lua live/combat capture", np.allclose(affected_live, clean_live), float(affected_live[:, :, :3].sum())))
assert clean_live[:, :, :3].sum() > 0

# Run the production data upload, with only the CPU collector replaced by one
# known unit. All shader creation, points, TexCoord payload, targets and GL state
# go through actual compatibility OpenGL. Owner/cell texels have alpha zero.
lua.execute("""
local include=VFS.Include
function VFS.Include(path,env)
  if path=='luaui/widgets_mosaic/include/mobile_shadow_sources.lua' then
    return {New=function()return {Shutdown=function()end,Invalidate=function()end,
      Collect=function()return {{unitID=4095,shape=1,center={64,12,64},
        axisX={1,0,0},axisY={0,1,0},axisZ={0,0,1},half={8,10,8},
        minX=56,maxX=72,minZ=56,maxZ=72}},{minY=2,maxY=22}end}end}
  end
  return include(path,env)
end
mobile=VFS.Include('luaui/widgets_mosaic/include/mobile_shadow_field.lua').New({})
domain={x=0,z=0,span=128}
""")
inherited_alpha(True)
g.mobile.Update(g.mobile, g.domain)
packed = pixels(g.mobile.texture).reshape(-1, 4)
checks.append(("actual Lua mobile owner/grid upload", packed[4, 0] == 4095 and packed[1280:, :].max() == 1,
               float(packed[4, 0])))
inherited_alpha(True)
g.mobile.CaptureSources(g.mobile, lua.eval("function(b,t,gain,metadata)combat:Capture(b,t,gain,1,metadata)end"),
                        0, 128, g.domain, None)
metadata = pixels(g.mobile.sourceAtlas)[:, 512:]
checks.append(("actual Lua unowned direct metadata capture", bool((metadata[:, :, 3] == .5).any()),
               float(metadata[:, :, 3].max())))
for label, passed, metric in checks:
    print(("PASS" if passed else "FAIL") + ": " + label + " | metric=" + str(metric))
assert all(passed for _, passed, _ in checks), "inherited alpha test suppressed a production radiance capture"
print("PASS: real Lua 5.1 capture callbacks remain correct under inherited GL_ALPHA_TEST; fragment-only and full shader descriptions link/validate")

# A shader that can draw a manually supplied lamp is not sufficient: the police
# provider must first survive the actual LuaUI sandbox. Route the real widget,
# central profile, source collector and Lua renderer into this same GL context,
# then apply its direct field through the actual scene renderer. Only engine
# world queries below are fixtures; no source/capture/scene module is replaced.
def create_list(callback):
    handle = fn(G, "glGenLists", U, I)(1)
    fn(G, "glNewList", None, U, U)(handle, 0x1300)
    callback()
    fn(G, "glEndList", None)()
    return handle


projection_inverse = np.array([[256, 0, 0, 0], [0, 0, 100, -200],
                               [0, 256, 0, 0], [0, 0, 0, 1]], "f4")
view_inverse = np.eye(4, dtype="f4")
view_inverse[:3, 3] = (256, 200, 256)


def uniform_matrix(location, name):
    assert name in ("projectioninverse", "viewinverse")
    matrix_value = projection_inverse if name == "projectioninverse" else view_inverse
    values = matrix_value.T.copy()
    fn(G, "glUniformMatrix4fv", None, I, I, C.c_ubyte, P)(location, 1, False, values.ctypes.data)


def copy_texture(name, x_offset, y_offset, x, y, width, height):
    active(0x84C0)
    bind(0x0DE1, textures[name]["id"])
    fn(G, "glCopyTexSubImage2D", None, U, I, I, I, I, I, I, I)(
        0x0DE1, 0, x_offset, y_offset, x, y, width, height)


g.gl.CreateList = create_list
g.gl.DeleteList = lambda handle: fn(G, "glDeleteLists", None, U, I)(handle, 1)
g.gl.UniformMatrix = uniform_matrix
g.gl.CopyToTexture = copy_texture
g.GL.TRIANGLE_STRIP = 5
g.GL.SRC_ALPHA = 0x0302
g.GL.ONE_MINUS_SRC_ALPHA = 0x0303
g.GL.DEPTH_COMPONENT24 = 0x81A6
lua.execute("""
policeState={frame=0,drawFrame=10,x=256,z=256,hidden=false}
Game={mapSizeX=512,mapSizeZ=512,gameSpeed=30}
UnitDefs={[1]={name='policetruck'}}
WeaponDefs={}
Spring={
  Echo=print,GetGameFrame=function()return policeState.frame end,
  GetDrawFrame=function()return policeState.drawFrame end,
  GetFrameTimeOffset=function()return 0 end,
  GetAllUnits=function()return {71}end,GetUnitDefID=function()return 1 end,
  GetCameraPosition=function()return 256,200,256 end,
  GetViewGeometry=function()return 256,256,0,0 end,
  GetGroundHeight=function()return 0 end,
  GetSpectatingState=function()return false,false end,
  GetMyAllyTeamID=function()return 0 end,
  GetUnitLosState=function()return {los=not policeState.hidden}end,
  IsPosInLos=function()return false end,
  ValidUnitID=function()return true end,GetUnitIsDead=function()return false end,
  GetUnitIsCloaked=function()return false end,GetUnitNoDraw=function()return false end,
  GetUnitTransporter=function()end,
  GetUnitPosition=function()return policeState.x,0,policeState.z end,
  GetUnitViewPosition=function()return policeState.x,0,policeState.z end,
  GetUnitVectors=function()return {0,0,1},{0,1,0},{1,0,0}end,
  GetUnitPieceMap=function()return {LightEmit01=0,LightEmit2=1}end,
  GetUnitPiecePosDir=function(_,piece)
    return policeState.x+(piece==0 and 5.967846 or -4.372424),
      28.78328,policeState.z+5.24158,0,1,0
  end,
  GetVisibleProjectiles=function()return {}end,
}
VFS={LoadFile=readFile}
function VFS.Include(path,env)
  local chunk=assert(loadstring(readFile(path),path))
  return setfenv(chunk,env or getfenv(2))()
end
VFS.Include('luaui/system.lua')
policeWG={}
policeWidget={}
for key,value in pairs(System) do policeWidget[key]=value end
policeWidget.widget,policeWidget.WG=policeWidget,policeWG
policeWidget.widgetHandler={RegisterGlobal=function()end,DeregisterGlobal=function()end}
assert(policeWidget.pairs and not policeWidget._G,'fixture no longer matches LuaUI System')
VFS.Include('luaui/widgets_mosaic/gfx_light_effects.lua',policeWidget)
policeWidget:Initialize()
assert(policeWG.HasCombatLightEmission(0),'police provider missing after real widget startup')
assert(policeWG.lighteffects.getPoliceLightStats().emitted==1)
policeLive=VFS.Include('luaui/widgets_mosaic/include/headlight_live_field.lua')()
function policeCapture(bottom,top,gain,metadata)
  policeWG.CaptureCombatLightEmission(bottom,top,gain,0,metadata)
end
policeScene=assert(VFS.Include('luaui/widgets_mosaic/include/radiance_scene.lua')())
policeDomain={x=0,z=0,span=512}
""")
black = create_texture(1, 1, lua.table_from({"format": 0x8814, "fbo": True}))
activate(textures[black], lambda: clear(0x4000, 0, 0, 0, 0))
scene_color = create_texture(256, 256, lua.table_from({"format": 0x8814, "fbo": True}))
scene_depth = create_texture(256, 256, lua.table_from({"format": 0x81A6}))
scene_target = dict(textures[scene_color], fbo=framebuffer(
    [textures[scene_color]["id"]], textures[scene_depth]["id"]))


def police_scene(mobile_shadows=None):
    def draw():
        clear(0x4000, 0, 0, 0, 0)
        g.gl.DepthMask(True)
        clear(0x0100, .5)  # Ground plane reconstructed by the real depth-copy path.
        g.policeScene.Draw(g.policeScene, black, black, 0, 128, 2, 1,
                           None, g.policeLive, 1, None, None, mobile_shadows)

    activate(scene_target, draw)
    return pixels(scene_color)[:, :, :3]


def police_step(frame, x=256, hidden=False):
    g.policeState.frame = frame
    g.policeState.drawFrame += 1
    g.policeState.x = x
    g.policeState.hidden = hidden
    enabled = g.policeWG.HasCombatLightEmission(0)
    g.policeLive.Update(g.policeLive, .2)
    inherited_alpha(True)
    g.policeLive.Draw(g.policeLive, g.policeCapture if enabled else None,
                      0, 128, g.policeDomain, enabled)
    return police_scene()


red_scene = police_step(0)
blue_scene = police_step(5)
road_x, road_z = np.meshgrid((np.arange(256) + .5) * 2, (np.arange(256) + .5) * 2)
outside_vehicle = (np.abs(road_x - 256) > 20) | (np.abs(road_z - 256) > 47)
assert red_scene[outside_vehicle, 0].sum() > 100, 'real police provider produced no outward red scene light'
assert blue_scene[outside_vehicle, 2].sum() > 100, 'real police provider produced no outward blue scene light'
assert red_scene[..., 0].sum() > red_scene[..., 2].sum() * 10
assert blue_scene[..., 2].sum() > blue_scene[..., 0].sum() * 5

# Retain the actual owner in the direct-source atlas and the optional shadow
# pass. The engine-world fixture is a box around the car, plus a separate box
# between its blue lamp and the road. Both use the production upload/ray code.
lua.execute("""
function mobile.collector:Collect()
  local records={}
  local function box(id,x,z,hx,hy,hz)
    records[#records+1]={unitID=id,shape=1,center={x,hy,z},half={hx,hy,hz},
      axisX={1,0,0},axisY={0,1,0},axisZ={0,0,1},
      minX=x-hx,maxX=x+hx,minZ=z-hz,maxZ=z+hz}
  end
  box(71,256,256,20,17,47)
  box(72,312,256,8,17,8)
  return records,{minY=0,maxY=34}
end
mobile:Update(policeDomain)
mobile:CaptureSources(policeCapture,0,128,policeDomain,nil)
""")
police_metadata = pixels(g.mobile.sourceAtlas)[:, 512:]
assert (police_metadata[:, :, 3] == 72).any(), 'police source owner lost before mobile shadows'
shadowed_scene = police_scene(g.mobile)
front = (road_x < 240) & (road_x > 210) & (np.abs(road_z - 256) < 8)
behind = (road_x > 330) & (road_x < 360) & (np.abs(road_z - 256) < 6)
assert np.allclose(shadowed_scene[front], blue_scene[front], atol=.001), 'own police proxy erased outward illumination'
assert shadowed_scene[behind].sum() < blue_scene[behind].sum() * .1, 'separate mobile blocker did not cast a police-light shadow'
moving_scene = police_step(10, x=360)
assert moving_scene[:, :80].max() == 0, 'police direct field left a stale footprint after movement'
assert moving_scene[:, 190:, 0].sum() > red_scene[:, 190:, 0].sum() * 5
assert police_step(15, x=360, hidden=True).max() == 0, 'hidden police retained scene lighting'
g.policeWidget.Shutdown(g.policeWidget)
assert g.policeWG.CaptureCombatLightEmission is None
print('PASS: real LuaUI startup -> central police profile -> live red/blue GL capture -> outward scene light, source ownership, finite mobile shadow, movement and LOS cleanup')
