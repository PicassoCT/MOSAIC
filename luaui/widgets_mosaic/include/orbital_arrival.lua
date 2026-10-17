-- Orbital rendering belongs exclusively to LuaUI after gameframe > 0.
-- LuaIntro uses only the lightweight artwork handoff. No camera API.
local M = {}
M.configKey = "MosaicOrbitalArrivalHandoff"
M.phaseKey = "MosaicOrbitalArrivalPhase"
M.artSeconds, M.fadeSeconds = 3, 1.25
M.blendSeconds, M.stepSeconds, M.revealSeconds = 0.5, 0.35, 0.6
M.latestStartFrame = 300 -- late LuaUI initialization is OK; mid-game reloads are not
M.holdDescent = 0.16
M.maxRenderWidth, M.maxRenderHeight = 1920, 1080

-- Choose a fixed region of the procedural planet without touching Lua's RNG.
-- Length-prefixed fields distinguish map/game identifiers even when they
-- contain separators. All products remain below 2^53, including Lua 5.1's
-- double-only number representation and a full 32-bit map checksum.
local regionModulus = 2147483647
local function hashRegionField(hash, value)
  local text = tostring(value or "")
  hash = (hash * 131 + #text) % regionModulus
  for i = 1, #text do
    hash = (hash * 131 + text:byte(i)) % regionModulus
  end
  return hash
end

function M.regionOffset(game)
  game = game or Game or {}
  local hash = 7
  for _, key in ipairs({"mapName", "mapChecksum", "gameID"}) do
    hash = hashRegionField(hash, game[key])
  end
  -- A missing gameID gives the same map its stable fallback region. With a
  -- gameID, another match can visit another region under the same noon sun.
  hash = (hash * 48271) % regionModulus
  local x = hash / regionModulus * 128
  hash = (hash * 48271) % regionModulus
  return x, hash / regionModulus * 128
end

local riskThemes = {
  {
    name = "CLIMATE",
    metrics = {
      {"RAINFALL DEFICIT", 34, 82},
      {"WILDFIRE LIKELIHOOD", 21, 74},
      {"WATER STRESS", 38, 89},
      {"HEAT ANOMALY", 18, 71},
      {"CROP FAILURE RISK", 14, 62},
      {"AIRBORNE PARTICULATE LOAD", 23, 77},
    },
    stamps = {"RESOURCE STRESSED", "WATER-RATIONED", "FIRE WEATHER"},
  },
  {
    name = "CONFLICT",
    metrics = {
      {"CONFLICT LIKELIHOOD", 26, 86},
      {"WAR DAMAGE", 5, 58},
      {"DISPLACEMENT PRESSURE", 9, 67},
      {"CIVIL ORDER FAILURE", 12, 69},
      {"ORDNANCE CONTAMINATION", 4, 42},
      {"MILITARY TRAFFIC", 18, 73},
    },
    stamps = {"MILITARIZED", "CONTESTED", "RECENT STRIKES"},
  },
  {
    name = "SYSTEMS",
    metrics = {
      {"GRID INSTABILITY", 23, 79},
      {"INFRASTRUCTURE LOSS", 10, 64},
      {"AIR TOXICITY", 19, 76},
      {"FOOD PRICE STRESS", 27, 84},
      {"INSURABILITY FAILURE", 31, 91},
      {"WATER SERVICE FAILURE", 13, 69},
    },
    stamps = {"AUSTERITY REGION", "CHRONIC OUTAGES", "INSURANCE EXCLUSION"},
  },
}

local function riskStep(hash, salt)
  hash = hashRegionField(hash, salt)
  return (hash * 48271) % regionModulus
end

-- A fictional orbital-survey aggregate for the arrival overlay. It is seeded
-- only from match identity, never Lua's RNG, so every client sees the same
-- terse risk packet while different matches can show different bad news.
function M.riskPacket(game)
  game = game or Game or {}
  local hash = 29
  for _, key in ipairs({"mapName", "mapChecksum", "gameID"}) do
    hash = hashRegionField(hash, game[key])
  end
  hash = riskStep(hash, "risk-theme")
  local theme = riskThemes[(hash % #riskThemes) + 1]
  local pool = {}
  for i = 1, #theme.metrics do pool[i] = i end
  local lines = {}
  for line = 1, 5 do
    hash = riskStep(hash, "metric-" .. line)
    local pick = (hash % #pool) + 1
    local metric = theme.metrics[pool[pick]]
    table.remove(pool, pick)
    hash = riskStep(hash, metric[1])
    local value = metric[2] + (hash % (metric[3] - metric[2] + 1))
    lines[#lines + 1] = {label = metric[1], value = value}
  end
  hash = riskStep(hash, "status")
  local status = theme.stamps[(hash % #theme.stamps) + 1]
  hash = riskStep(hash, "confidence")
  local confidence = 61 + (hash % 34)
  return {
    theme = theme.name,
    status = status,
    confidence = confidence,
    lines = lines,
  }
end

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
  local r = {uniforms = {}, regionOffset = {M.regionOffset()}}
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
  for _, name in ipairs({"descent", "cloudDescent", "regionOffset", "aspect"}) do
    r.uniforms[name] = gl.GetUniformLocation(r.earth, name)
  end
  for _, name in ipairs({"descent", "fade", "hasArtwork", "hasLive", "artScale"}) do
    r.uniforms["c_" .. name] = gl.GetUniformLocation(r.composite, name)
  end

  function r:draw(width, height, texture, age, fade, descent, live)
    local visualDescent, stage = M.snapDescent(descent)
    local cloudDescent = M.cloudDescent(descent)
    local factor = math.min(1, M.maxRenderWidth / width, M.maxRenderHeight / height)
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
    -- Earth and its cloud pattern are stationary at this distance: render
    -- each high-resolution snapshot only once, including the artwork blend.
    -- The cloud descent alone changes continuously, at a bounded 12 Hz.
    -- Cuts, resize, age resets and the first/final cloud frames invalidate
    -- immediately. Composite artwork and the clean live image every frame.
    local aspect = width / height
    local rerender = self.lastAge == nil or age < self.lastDrawAge
      or (cloudDescent > 0 and cloudDescent ~= self.lastCloudDescent
        and (age - self.lastAge) >= (1 / 12))
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
      gl.Uniform(self.uniforms.regionOffset, self.regionOffset[1], self.regionOffset[2])
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
    self.lastDrawAge = age
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
