-- Orbital rendering belongs exclusively to LuaUI after gameframe > 0.
-- LuaIntro uses only the lightweight artwork handoff. No camera API.
local M = {}
M.configKey = "MosaicOrbitalArrivalHandoff"
M.phaseKey = "MosaicOrbitalArrivalPhase"
M.artSeconds, M.fadeSeconds = 3, 1.25
M.blendSeconds, M.stepSeconds, M.revealSeconds = 0.5, 0.35, 0.6
M.latestStartFrame = 300 -- late LuaUI initialization is OK; mid-game reloads are not
M.holdDescent = 0.16

function M.clamp(x) return math.max(0, math.min(1, x)) end
-- Four held planetary snapshots, followed by a separate cloud descent.
-- Keep the first scale through the artwork blend so none of the four shots
-- is spent underneath the loading picture. These are optical scales only;
-- reaching the fourth stop must not reveal the live city yet.
local snapStops = {0.0, 0.30, 0.64, 1.0}
M.snapshotCount = #snapStops
M.revealStart = M.blendSeconds + M.snapshotCount * M.stepSeconds
M.descentSeconds = M.revealStart + M.revealSeconds
function M.snapDescent(x)
  local elapsed = M.clamp(x) * M.descentSeconds
  local beat = math.max(0, elapsed - M.blendSeconds) / M.stepSeconds
  local stage = math.min(M.snapshotCount, math.floor(beat + 1e-7) + 1)
  return snapStops[stage], stage
end
function M.cloudDescent(x)
  return M.clamp((M.clamp(x) * M.descentSeconds - M.revealStart) / M.revealSeconds)
end
function M.advanceTime(elapsed, delta)
  local nextTime = math.min(M.descentSeconds, elapsed + math.max(0, delta))
  -- A slow city-startup frame must not consume an unseen snapshot. Stop at
  -- each shot boundary at least once; normal frame pacing only adds rounding
  -- to display frames, while a stall extends the presentation safely.
  for beat = 0, M.snapshotCount do
    local boundary = M.blendSeconds + beat * M.stepSeconds
    if elapsed < boundary - 1e-7 then return math.min(nextTime, boundary) end
  end
  return nextTime
end
function M.loadingState(age)
  -- Legacy helper retained for tests and compatibility. LuaIntro no longer
  -- calls this: it renders static loading artwork until shutdown.
  return M.clamp((age - M.artSeconds) / M.fadeSeconds), 0
end

function M.beginHandoff()
  Spring.SetConfigString(M.configKey, "", true)
  Spring.SetConfigString(M.phaseKey, (Game.mapName or "") .. "\npending", true)
end

function M.finishIntro()
  -- A late LuaIntro shutdown must not undo a completed arrival.
  if M.introPhase() == "played" then return end
  Spring.SetConfigString(M.phaseKey, (Game.mapName or "") .. "\nfinished", true)
end

function M.introPhase()
  local raw = Spring.GetConfigString(M.phaseKey, "")
  local mapName, phase = raw:match("^(.-)\n([^\n]+)$")
  if mapName ~= (Game.mapName or "") then return nil end
  return phase
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

function M.clearHandoff()
  Spring.SetConfigString(M.configKey, "", true)
  Spring.SetConfigString(M.phaseKey, (Game.mapName or "") .. "\nplayed", true)
end

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
  for _, name in ipairs({"descent", "cloudDescent", "elapsed", "aspect"}) do
    r.uniforms[name] = gl.GetUniformLocation(r.earth, name)
  end
  for _, name in ipairs({"descent", "fade", "hasArtwork", "hasLive", "artScale"}) do
    r.uniforms["c_" .. name] = gl.GetUniformLocation(r.composite, name)
  end

  function r:draw(width, height, texture, age, fade, descent, live)
    local visualDescent, stage = M.snapDescent(descent)
    local cloudDescent = M.cloudDescent(descent)
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
    -- The procedural Earth has multiple FBM layers; rendering it every
    -- screen refresh can collapse low-end GPUs. Reuse the FBO between
    -- samples, at 12 Hz during holds and the cloud reveal. Refresh immediately
    -- on optical cuts so a short snapshot is never swallowed by the cache.
    -- Composite the artwork and clean live framebuffer every display frame.
    local aspect = width / height
    local rerender = self.lastAge == nil or age < self.lastAge
      or (age - self.lastAge) >= (1 / 12)
      or self.lastAspect ~= aspect
      or self.lastStage ~= stage
      or (cloudDescent > 0 and self.lastCloudDescent == 0)
      or (cloudDescent >= 1 and self.lastCloudDescent ~= 1)
    if rerender then
      gl.RenderToTexture(self.orbitTexture, function()
      gl.MatrixMode(GL.PROJECTION); gl.PushMatrix(); gl.LoadIdentity()
      gl.MatrixMode(GL.MODELVIEW); gl.PushMatrix(); gl.LoadIdentity()
      gl.Clear(0, 0, 0, 0)
      gl.Blending(false)
      gl.UseShader(self.earth)
      gl.Uniform(self.uniforms.descent, visualDescent)
      gl.Uniform(self.uniforms.cloudDescent, cloudDescent)
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
      self.lastAge, self.lastStage, self.lastAspect = age, stage, aspect
      self.lastCloudDescent = cloudDescent
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
    gl.Uniform(self.uniforms.c_descent, cloudDescent)
    gl.Uniform(self.uniforms.c_fade, fade)
    gl.UniformInt(self.uniforms.c_hasArtwork, info and 1 or 0)
    -- The cached image must have reached the full-cloud scene before the
    -- display-rate compositor can expose a different projection underneath.
    gl.UniformInt(self.uniforms.c_hasLive, live and self.lastCloudDescent >= 0.55 and 1 or 0)
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
