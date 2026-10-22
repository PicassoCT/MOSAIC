-- Orbital rendering belongs exclusively to LuaUI after gameframe > 0.
-- LuaIntro uses only the lightweight artwork handoff. No camera state changes.
local M = {}
M.configKey = "MosaicOrbitalArrivalHandoff"
M.phaseKey = "MosaicOrbitalArrivalPhase"
M.artSeconds, M.fadeSeconds = 3, 1.25
M.blendSeconds, M.stepSeconds, M.revealSeconds = 0.5, 0.5, 0.9
M.maxBlendFrameSeconds = 0.05 -- preserve the handover through slow startup draws
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
  if x >= 1 then return 1 end -- preserve an exact terminal state despite 0.9 rounding
  return M.clamp((M.clamp(x) * M.descentSeconds - M.revealStart) / M.revealSeconds)
end

-- This is the same optical transform used by the ground survey in the Earth
-- shader. A selected patch therefore grows around one destination through all
-- four cuts; the telemetry never selects a different patch between shots.
function M.surveyZoom(progress)
  local opticalDescent = M.snapDescent(progress)
  return 2 ^ (3.28 * (1 - opticalDescent))
end

local stageLabels = {"ORBIT", "REGION", "CITY", "DISTRICT", "CLOUD TRANSIT", "MAP LOCK"}
local stageAltitudes = {"600 KM", "80 KM", "8 KM", "2 KM", "CLOUD LAYER", "SURFACE"}
function M.targetFrame(progress, width, height)
  local _, stage = M.snapDescent(progress)
  local clouds = M.cloudDescent(progress)
  if clouds > 0 then stage = clouds < 0.55 and 5 or 6 end
  local zoom = M.surveyZoom(progress)
  -- Fixed final-image footprint in screen UV, divided by the optical zoom.
  -- A small minimum keeps the orbital selection readable at modest resolutions.
  local halfWidth = math.max(6, width * 0.105 / zoom)
  local halfHeight = math.max(6, height * 0.095 / zoom)
  local cx, cy = width * 0.5, height * 0.5
  return {left = cx - halfWidth, bottom = cy - halfHeight,
    right = cx + halfWidth, top = cy + halfHeight, cx = cx, cy = cy,
    stage = stage, label = stageLabels[stage], altitude = stageAltitudes[stage]}
end
function M.advanceTime(elapsed, delta)
  delta = math.max(0, delta)
  if elapsed < M.blendSeconds then
    -- The hologram exists only strictly between the artwork/orbit endpoints.
    -- A post-warmup startup stall must not jump straight from fade 0 to 1.
    -- Keep at least ten progress steps, discarding stall time rather than
    -- catching it up on the next draw. At >=20 display FPS the blend is 0.5s.
    local nextTime = math.min(M.blendSeconds,
      elapsed + math.min(delta, M.maxBlendFrameSeconds))
    if M.blendSeconds - nextTime < 1e-7 then return M.blendSeconds end
    return nextTime
  end
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

local function finite(value)
  return type(value) == "number" and value == value and math.abs(value) < math.huge
end

-- Fit screen UV -> map UV from four projected ground-plane corners. Partial
-- pivoting handles perspective and rotated cameras; a degenerate view simply
-- keeps the procedural fallback. This runs once per viewport, never per pixel.
function M.surveyRows(corners)
  if not corners or #corners ~= 4 then return end
  local matrix = {}
  for i, corner in ipairs(corners) do
    local x, y, u, v = unpack(corner)
    if not (finite(x) and finite(y) and finite(u) and finite(v)) then return end
    matrix[2 * i - 1] = {x, y, 1, 0, 0, 0, -u * x, -u * y, u}
    matrix[2 * i] = {0, 0, 0, x, y, 1, -v * x, -v * y, v}
  end
  for column = 1, 8 do
    local pivot = column
    for row = column + 1, 8 do
      if math.abs(matrix[row][column]) > math.abs(matrix[pivot][column]) then pivot = row end
    end
    if math.abs(matrix[pivot][column]) < 1e-10 then return end
    matrix[column], matrix[pivot] = matrix[pivot], matrix[column]
    local divisor = matrix[column][column]
    for j = column, 9 do matrix[column][j] = matrix[column][j] / divisor end
    for row = 1, 8 do
      if row ~= column then
        local factor = matrix[row][column]
        for j = column, 9 do matrix[row][j] = matrix[row][j] - factor * matrix[column][j] end
      end
    end
  end
  local values = {}
  for i = 1, 8 do
    values[i] = matrix[i][9]
    if not finite(values[i]) then return end
  end
  return {values[1], values[2], values[3]}, {values[4], values[5], values[6]},
    {values[7], values[8], 1}
end

local function projectMap(width, height)
  if not (Spring.WorldToScreenCoords and Spring.GetGroundHeight
    and Game and finite(Game.mapSizeX) and finite(Game.mapSizeZ)
    and Game.mapSizeX > 0 and Game.mapSizeZ > 0) then return end
  -- The minimap is authored ground imagery, not a live minimap with unit/LOS
  -- markers. Project a flat plane at the map's centre height into the existing
  -- camera. Terrain relief remains an approximation until the clean live frame.
  local level = Spring.GetGroundHeight(Game.mapSizeX * 0.5, Game.mapSizeZ * 0.5)
  if not finite(level) then return end
  local corners = {}
  for _, uv in ipairs({{0, 0}, {1, 0}, {1, 1}, {0, 1}}) do
    local x, y = Spring.WorldToScreenCoords(uv[1] * Game.mapSizeX, level, uv[2] * Game.mapSizeZ)
    if not (finite(x) and finite(y)) then return end
    -- Recoil returns viewport-local, bottom-left pixels. Do not subtract the
    -- window's viewport origin, and do not flip the raw minimap texture.
    corners[#corners + 1] = {x / width, y / height, uv[1], uv[2]}
  end
  return M.surveyRows(corners)
end

function M.newRenderer()
  local r = {uniforms = {}, regionOffset = {M.regionOffset()}}
  function r:destroy()
    if self.earth then gl.DeleteShader(self.earth); self.earth = nil end
    if self.composite then gl.DeleteShader(self.composite); self.composite = nil end
    if self.survey then gl.DeleteShader(self.survey); self.survey = nil end
    if self.orbitTexture then gl.DeleteTexture(self.orbitTexture); self.orbitTexture = nil end
    if self.surveyTexture then gl.DeleteTexture(self.surveyTexture); self.surveyTexture = nil end
  end
  if not gl.CreateShader or not gl.RenderToTexture then return end
  local vertex = [[#version 150 compatibility
    void main() { gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
      gl_TexCoord[0] = gl_MultiTexCoord0; }
  ]]
  r.earth = gl.CreateShader({vertex = vertex,
    fragment = VFS.LoadFile("luaui/widgets_mosaic/shaders/orbital_arrival_earth.frag"),
    uniformInt = {surveyTex = 0}})
  r.composite = gl.CreateShader({vertex = vertex,
    fragment = VFS.LoadFile("luaui/widgets_mosaic/shaders/orbital_arrival_composite.frag"),
    uniformInt = {orbitTex = 0, artworkTex = 1, liveTex = 2}})
  if not r.earth or not r.composite then
    Spring.Echo("[MOSAIC arrival] Shader unavailable: " .. (gl.GetShaderLog() or ""))
    r:destroy(); return
  end
  for _, name in ipairs({"descent", "cloudDescent", "regionOffset", "aspect", "hasSurvey"}) do
    r.uniforms[name] = gl.GetUniformLocation(r.earth, name)
  end
  for _, name in ipairs({"descent", "fade", "hasArtwork", "hasLive", "artScale"}) do
    r.uniforms["c_" .. name] = gl.GetUniformLocation(r.composite, name)
  end

  -- Optional: clean authored map geography replaces invented late-shot ground.
  -- A missing map texture or unsupported projection must never abort arrival.
  if Spring.WorldToScreenCoords and Spring.GetGroundHeight then
    local source = VFS.LoadFile("luaui/widgets_mosaic/shaders/orbital_arrival_survey.frag")
    if source then
      local ok, shader = pcall(gl.CreateShader,
        {vertex = vertex, fragment = source, uniformInt = {mapTex = 0}})
      if ok then r.survey = shader end
      if r.survey then
        for i = 0, 2 do r.uniforms["mapRow" .. i] = gl.GetUniformLocation(r.survey, "mapRow" .. i) end
      end
    end
  end

  function r:prepareSurvey(width, height, rw, rh)
    if self.surveyTexture then gl.DeleteTexture(self.surveyTexture); self.surveyTexture = nil end
    if not self.survey then return end
    local infoOK, info = pcall(gl.TextureInfo, "$minimap")
    if not infoOK then return end
    if not info or not info.xsize or not info.ysize or info.xsize <= 0 or info.ysize <= 0 then return end
    local projectionOK, row0, row1, row2 = pcall(projectMap, width, height)
    if not projectionOK or not row0 then return end
    local textureOK, target = pcall(gl.CreateTexture, rw, rh, {fbo = true,
      min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
      wrap_s = GL.CLAMP_TO_EDGE, wrap_t = GL.CLAMP_TO_EDGE})
    if not textureOK or not target then return end
    local drawn = false
    local renderOK, result = pcall(gl.RenderToTexture, target, function()
      local projectionPushed, modelPushed = false, false
      -- The survey is optional. Restore draw state even if a driver/API rejects
      -- this extra pass, then use the detailed generated ground beneath clouds.
      local drawOK = pcall(function()
        gl.MatrixMode(GL.PROJECTION); gl.PushMatrix(); projectionPushed = true; gl.LoadIdentity()
        gl.MatrixMode(GL.MODELVIEW); gl.PushMatrix(); modelPushed = true; gl.LoadIdentity()
        gl.Clear(0, 0, 0, 0)
        gl.Blending(false)
        if gl.Texture(0, "$minimap") == false then return end
        gl.UseShader(self.survey)
        gl.Uniform(self.uniforms.mapRow0, unpack(row0))
        gl.Uniform(self.uniforms.mapRow1, unpack(row1))
        gl.Uniform(self.uniforms.mapRow2, unpack(row2))
        gl.Color(1, 1, 1, 1)
        gl.TexRect(-1, -1, 1, 1, 0, 0, 1, 1)
        drawn = true
      end)
      drawn = drawn and drawOK
      gl.UseShader(0)
      gl.Texture(0, false)
      gl.Blending(true)
      if modelPushed then gl.MatrixMode(GL.MODELVIEW); gl.PopMatrix() end
      if projectionPushed then gl.MatrixMode(GL.PROJECTION); gl.PopMatrix() end
      gl.MatrixMode(GL.MODELVIEW)
    end)
    if renderOK and result ~= false and drawn then self.surveyTexture = target
    else gl.DeleteTexture(target) end
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
    if self.surveyWidth ~= width or self.surveyHeight ~= height
      or (self.lastDrawAge and age < self.lastDrawAge) then
      self:prepareSurvey(width, height, rw, rh)
      self.surveyWidth, self.surveyHeight = width, height
      self.lastAge = nil
    end
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
      if self.surveyTexture then gl.Texture(0, self.surveyTexture) end
      gl.UseShader(self.earth)
      gl.UniformInt(self.uniforms.hasSurvey, self.surveyTexture and 1 or 0)
      gl.Uniform(self.uniforms.descent, visualDescent)
      gl.Uniform(self.uniforms.cloudDescent, cloudDescent)
      gl.Uniform(self.uniforms.regionOffset, self.regionOffset[1], self.regionOffset[2])
      gl.Uniform(self.uniforms.aspect, width / height)
      gl.Color(1, 1, 1, 1)
      gl.TexRect(-1, -1, 1, 1, 0, 0, 1, 1)
      gl.UseShader(0)
      gl.Texture(0, false)
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
    self.artworkAvailable = not not info
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
    gl.TexRect(0, 0, width, height, 0, 0, 1, 1)
    gl.UseShader(0)
    for unit = 0, 2 do gl.Texture(unit, false) end
    return true
  end
  return r
end
return M
