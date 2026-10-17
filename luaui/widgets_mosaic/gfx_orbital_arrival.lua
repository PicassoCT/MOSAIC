function widget:GetInfo()
  return {name = "Orbital Arrival", desc = "Screen-space loading-to-city descent",
    author = "MOSAIC", license = "GPL2", layer = 100000, enabled = true}
end

local Arrival = VFS.Include("luaui/widgets_mosaic/include/orbital_arrival.lua")
local renderer, liveTexture, modal
local width, height, offsetX, offsetY
local timer, texture, age, fade, descent
local riskPacket
local lastWallElapsed = 0
local guiWasHidden, hasCapture, started = false, false, false
local artworkReady = false
local savedEdges = {}
local finished = false

local function finish()
  if finished then return end
  finished = true
  if modal then modal.active = false end
  if WG.MosaicArrival == modal then WG.MosaicArrival = nil end
  if started and not guiWasHidden and Spring.IsGUIHidden() then
    Spring.SendCommands("hideinterface")
  end
  for key, value in pairs(savedEdges) do Spring.SetConfigInt(key, value, true) end
  savedEdges = {}
  Arrival.clearHandoff()
  if renderer then renderer:destroy(); renderer = nil end
  if liveTexture then gl.DeleteTexture(liveTexture); liveTexture = nil end
  riskPacket = nil
  -- VFS owns the static artwork texture. It may still be used by LuaIntro
  -- during a late shutdown; never delete the shared image handle here.
  WG.MosaicArrivalFinished = true
  Spring.Echo("[MOSAIC arrival] finished; released live map (started=" ..
      tostring(started) .. ")")
end

function widget:Initialize()
  -- Reloads, saved games and mid-match joins must never replay or lock the UI.
  if WG.MosaicArrivalFinished or Arrival.introPhase() == "played"
      or Spring.GetGameFrame() > Arrival.latestStartFrame then
    widgetHandler:RemoveWidget(self); return
  end
  -- Arm the screen-covering overlay NOW, but defer expensive shader creation
  -- until the game frame counter actually starts advancing.
  modal = {active = true, skip = finish}
  WG.MosaicArrival = modal
  Spring.Echo("[MOSAIC arrival] armed; holding loading artwork until gameframe > 0")
end

function widget:Shutdown() finish() end

local function readArtwork()
  if artworkReady then return end
  local image, handoffAge = Arrival.readHandoff()
  if image ~= nil then
    texture, age, artworkReady = image, handoffAge, true
  end
end

local function drawStaticArtwork()
  readArtwork()
  local w, h = Spring.GetViewGeometry()
  gl.Color(0, 0, 0, 1)
  gl.Rect(0, 0, w, h) -- never expose the live map between LuaIntro/LuaUI
  if texture and texture ~= "" then
    gl.Color(1, 1, 1, 1)
    gl.Texture(texture)
    gl.TexRect(0, 0, w, h)
    gl.Texture(false)
  end
  gl.Color(1, 1, 1, 1)
end

local function begin()
  readArtwork()
  texture, age = texture or "", age or 0
  -- Shader compilation here cannot slow down the loading screen.
  renderer = Arrival.newRenderer()
  if not renderer then finish(); return false end
  fade, descent = 0, 0
  riskPacket = Arrival.riskPacket(Game)
  lastWallElapsed = 0
  timer = Spring.GetTimer()
  Spring.Echo("[MOSAIC arrival] first advancing gameframe=" ..
      tostring(Spring.GetGameFrame()) .. "; starting four planetary snapshots, then cloud reveal")
  guiWasHidden = Spring.IsGUIHidden()
  started = true
  if not guiWasHidden then Spring.SendCommands("hideinterface") end
  for _, key in ipairs({"FullscreenEdgeMove", "WindowedEdgeMove"}) do
    savedEdges[key] = Spring.GetConfigInt(key, 1)
    Spring.SetConfigInt(key, 0, true)
  end
  return true
end

local function capture()
  local w, h, x, y = Spring.GetViewGeometry()
  if w ~= width or h ~= height or x ~= offsetX or y ~= offsetY then
    if liveTexture then gl.DeleteTexture(liveTexture) end
    width, height, offsetX, offsetY = w, h, x or 0, y or 0
    liveTexture = gl.CreateTexture(w, h, {min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
      wrap_s = GL.CLAMP_TO_EDGE, wrap_t = GL.CLAMP_TO_EDGE})
  end
  if not liveTexture then return false end
  gl.CopyToTexture(liveTexture, 0, 0, offsetX, offsetY, width, height)
  return true
end

local function drawRiskOverlay(progress)
  if not riskPacket or not width or not height then return end
  -- Cross the middle two optical cuts, then disappear before the live-map
  -- reveal. The moving card intentionally competes for attention while the
  -- procedural metropolitan target is doing the most perceptual work.
  local startP, endP = 0.32, 0.79
  if progress <= startP or progress >= endP then return end
  local sweep = Arrival.clamp((progress - startP) / (endP - startP))
  local fadeIn = Arrival.clamp((progress - startP) / 0.055)
  local fadeOut = Arrival.clamp((endP - progress) / 0.075)
  local alpha = math.min(fadeIn, fadeOut)
  if alpha <= 0 then return end

  local scale = math.max(0.72, math.min(1.35, height / 1080))
  local panelW = math.min(width * 0.36, 620 * scale)
  local panelH = math.min(height * 0.31, 318 * scale)
  local travel = width + panelW * 1.20
  local left = width + panelW * 0.05 - sweep * travel
  local bottom = height * 0.53 - panelH * 0.50
  local right, top = left + panelW, bottom + panelH
  local pad = 18 * scale

  -- Dirty glass / scan-card treatment. Muted grey-blue and one restrained
  -- amber warning accent keep the Earth sickly rather than cyber-neon.
  gl.Color(0.025, 0.032, 0.037, 0.31 * alpha)
  gl.Rect(left, bottom, right, top)
  gl.Color(0.42, 0.50, 0.53, 0.42 * alpha)
  gl.Rect(left, top - 2 * scale, right, top)
  gl.Rect(left, bottom, left + 2 * scale, top)

  local headerSize = 12 * scale
  local textSize = 11 * scale
  gl.Color(0.70, 0.76, 0.77, 0.88 * alpha)
  gl.Text("ORB-CIV // REGIONAL RISK AGGREGATE", left + pad, top - 25 * scale,
      headerSize, "o")
  gl.Color(0.56, 0.62, 0.63, 0.76 * alpha)
  gl.Text("MODEL ESTIMATE // " .. riskPacket.theme ..
      " // CONF " .. riskPacket.confidence .. "%", left + pad,
      top - 43 * scale, 9.5 * scale, "o")

  local y = top - 72 * scale
  local barLeft = left + panelW * 0.60
  local barMax = panelW * 0.24
  for _, line in ipairs(riskPacket.lines) do
    gl.Color(0.67, 0.72, 0.72, 0.82 * alpha)
    gl.Text(line.label, left + pad, y, textSize, "o")
    gl.Color(0.22, 0.27, 0.28, 0.60 * alpha)
    gl.Rect(barLeft, y + 2 * scale, barLeft + barMax, y + 6 * scale)
    gl.Color(0.57, 0.62, 0.61, 0.76 * alpha)
    gl.Rect(barLeft, y + 2 * scale,
        barLeft + barMax * line.value / 100, y + 6 * scale)
    gl.Color(0.72, 0.75, 0.72, 0.86 * alpha)
    gl.Text(string.format("%02d%%", line.value), right - pad,
        y, textSize, "or")
    y = y - 27 * scale
  end

  gl.Color(0.68, 0.53, 0.31, 0.90 * alpha)
  gl.Text(riskPacket.status, left + pad, bottom + 19 * scale,
      11.5 * scale, "o")

  -- A few short horizontal acquisition marks make the card feel like a
  -- transient machine-readout instead of a conventional menu panel.
  gl.Color(0.48, 0.55, 0.56, 0.34 * alpha)
  local tickY = bottom + 8 * scale
  for i = 0, 5 do
    local tx = right - pad - i * 16 * scale
    gl.Rect(tx, tickY, tx + 8 * scale, tickY + 1.5 * scale)
  end
  gl.Color(1, 1, 1, 1)
end

function widget:DrawScreenEffects()
  if finished then return end
  if not started then
    -- Keep displaying the SAME loading artwork after LuaIntro shuts down.
    -- Prevent the one-second glimpse of the unfinished live city.
    if Spring.GetGameFrame() <= 0 then drawStaticArtwork(); return end
    -- The only zoom trigger is the advancing game-frame counter.
    if not begin() then return end
  end
  local wallElapsed = Spring.DiffTimers(Spring.GetTimer(), timer)
  local elapsed = Arrival.advanceTime(modal.elapsed or 0, wallElapsed - lastWallElapsed)
  lastWallElapsed = wallElapsed
  fade = Arrival.clamp(elapsed / Arrival.blendSeconds)
  descent = Arrival.clamp(elapsed / Arrival.descentSeconds)
  modal.elapsed, modal.descent = elapsed, descent
  if not capture() then finish(); return end
  hasCapture = true
  if not renderer:draw(width, height, texture, age + elapsed, fade, descent, liveTexture) then
    finish(); return
  end
  drawRiskOverlay(descent)
  if descent >= 1 then finish() end
end

function widget:DrawScreenPost()
  if finished then return end
  -- Always cover the gap between LuaIntro shutdown and the first gameframe,
  -- including overlays drawn after DrawScreenEffects.
  if not started then drawStaticArtwork(); return end
  -- Reuse the CLEAN world capture after engine overlays/cursor. No feedback.
  if hasCapture then
    renderer:draw(width, height, texture, age + modal.elapsed, fade, descent, liveTexture)
    drawRiskOverlay(descent)
  end
end

-- Keep flex call-ins registered even when the other interface widgets are off.
function widget:MouseWheel() return not finished end
function widget:MousePress() return not finished end
function widget:MouseRelease() return -1 end
function widget:MouseMove() return not finished end
function widget:IsAbove() return not finished end
function widget:GetTooltip() return " " end
function widget:KeyPress(key)
  if key == 27 then finish() end
  return not finished
end
function widget:KeyRelease() return not finished end
function widget:TextInput() return not finished end
function widget:CommandNotify() return not finished end
