-- Shared by LuaIntro and LuaUI. All movement is texture-space; no camera API.
local M = {}
M.configKey = "MosaicOrbitalArrivalHandoff"
M.artSeconds, M.fadeSeconds, M.descentSeconds = 3, 1.25, 1.75
M.holdDescent = 0.16

function M.clamp(x) return math.max(0, math.min(1, x)) end
-- Deliberately staged rather than a long continuous zoom. Each plateau lets the
-- eye register a new scale, while the very short ramps read as optical snaps.
local snapStops = {0.0, 0.16, 0.34, 0.56, 0.78, 1.0}
function M.snapDescent(x)
  x = M.clamp(x)
  if x >= 1 then return 1 end
  local count = #snapStops - 1
  local scaled = x * count
  local index = math.min(count, math.floor(scaled) + 1)
  local phase = scaled - math.floor(scaled)
  local a, b = snapStops[index], snapStops[index + 1]
  -- Hold most of each beat, then jump to the next scale in ~18% of the beat.
  local jump = M.clamp((phase - 0.82) / 0.18)
  jump = jump * jump * (3 - 2 * jump)
  return a + (b - a) * jump
end
function M.loadingState(age)
  return M.clamp((age - M.artSeconds) / M.fadeSeconds),
    M.holdDescent * M.clamp((age - M.artSeconds - M.fadeSeconds) / 2)
end

-- Runtime-only config overlay (third argument true), never written to disk.
function M.writeHandoff(texture, age, fade, descent)
  Spring.SetConfigString(M.configKey, table.concat({Game.mapName or "", texture or "",
    string.format("%.6f", age), string.format("%.6f", fade),
    string.format("%.6f", descent)}, "\n"), true)
end

function M.readHandoff()
  local fields = {}
  for field in (Spring.GetConfigString(M.configKey, "") .. "\n"):gmatch("(.-)\n") do
    fields[#fields + 1] = field
  end
  if fields[1] ~= Game.mapName or #fields ~= 5 then return end
  local age, fade, descent = tonumber(fields[3]), tonumber(fields[4]), tonumber(fields[5])
  if not age or not fade or not descent then return end
  return fields[2], math.max(0, age), M.clamp(fade), math.min(M.holdDescent, M.clamp(descent))
end

function M.clearHandoff() Spring.SetConfigString(M.configKey, "", true) end

function M.newRenderer()
  local r = {uniforms = {}}
  function r:destroy()
    if self.earth then gl.DeleteShader(self.earth); self.earth = nil end
    if self.composite then gl.DeleteShader(self.composite); self.composite = nil end
    if self.orbitTexture then gl.DeleteTexture(self.orbitTexture); self.orbitTexture = nil end
  end
  if not gl.CreateShader or not gl.RenderToTexture then return end
  local vertex = [[#version 150 compatibility
    void main() { gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
      gl_TexCoord[0] = gl_MultiTexCoord0; }
  ]]
  r.earth = gl.CreateShader({vertex = vertex,
    fragment = VFS.LoadFile("luaui/widgets_mosaic/shaders/orbital_arrival_earth.frag")})
  r.composite = gl.CreateShader({vertex = vertex,
    fragment = VFS.LoadFile("luaui/widgets_mosaic/shaders/orbital_arrival_composite.frag"),
    uniformInt = {orbitTex = 0, artworkTex = 1, liveTex = 2}})
  if not r.earth or not r.composite then
    Spring.Echo("[MOSAIC arrival] Shader unavailable: " .. (gl.GetShaderLog() or ""))
    r:destroy(); return
  end
  for _, name in ipairs({"descent", "elapsed", "aspect"}) do
    r.uniforms[name] = gl.GetUniformLocation(r.earth, name)
  end
  for _, name in ipairs({"descent", "fade", "hasArtwork", "hasLive", "artScale"}) do
    r.uniforms["c_" .. name] = gl.GetUniformLocation(r.composite, name)
  end

  function r:draw(width, height, texture, age, fade, descent, live)
    local visualDescent = M.snapDescent(descent)
    local factor = math.min(1, 960 / width, 540 / height)
    local rw = math.max(1, math.floor(width * factor))
    local rh = math.max(1, math.floor(height * factor))
    if rw ~= self.width or rh ~= self.height then
      if self.orbitTexture then gl.DeleteTexture(self.orbitTexture) end
      self.orbitTexture = gl.CreateTexture(rw, rh, {fbo = true,
        min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
        wrap_s = GL.CLAMP_TO_EDGE, wrap_t = GL.CLAMP_TO_EDGE})
      self.width, self.height = rw, rh
      self.lastAge = nil
    end
    if not self.orbitTexture then return false end
    if self.lastAge ~= age or self.lastDescent ~= visualDescent or self.lastAspect ~= width / height then
      gl.RenderToTexture(self.orbitTexture, function()
      gl.MatrixMode(GL.PROJECTION); gl.PushMatrix(); gl.LoadIdentity()
      gl.MatrixMode(GL.MODELVIEW); gl.PushMatrix(); gl.LoadIdentity()
      gl.Clear(0, 0, 0, 0)
      gl.Blending(false)
      gl.UseShader(self.earth)
      gl.Uniform(self.uniforms.descent, visualDescent)
      gl.Uniform(self.uniforms.elapsed, age)
      gl.Uniform(self.uniforms.aspect, width / height)
      gl.Color(1, 1, 1, 1)
      gl.TexRect(-1, -1, 1, 1)
      gl.UseShader(0)
      gl.Blending(true)
      gl.PopMatrix()
      gl.MatrixMode(GL.PROJECTION); gl.PopMatrix()
      gl.MatrixMode(GL.MODELVIEW)
      end)
      self.lastAge, self.lastDescent, self.lastAspect = age, visualDescent, width / height
    end
    local info = texture and texture ~= "" and gl.TextureInfo(texture)
    local sx, sy = 1, 1
    if info then
      local ratio = (width / height) / (info.xsize / info.ysize)
      if ratio > 1 then sy = 1 / ratio else sx = ratio end
    end
    gl.Texture(0, self.orbitTexture)
    gl.Texture(1, info and texture or self.orbitTexture)
    gl.Texture(2, live or self.orbitTexture)
    gl.UseShader(self.composite)
    gl.Uniform(self.uniforms.c_descent, visualDescent)
    gl.Uniform(self.uniforms.c_fade, fade)
    gl.UniformInt(self.uniforms.c_hasArtwork, info and 1 or 0)
    gl.UniformInt(self.uniforms.c_hasLive, live and 1 or 0)
    gl.Uniform(self.uniforms.c_artScale, sx, sy)
    gl.Color(1, 1, 1, 1)
    gl.TexRect(0, 0, width, height)
    gl.UseShader(0)
    for unit = 0, 2 do gl.Texture(unit, false) end
    return true
  end
  return r
end
return M
