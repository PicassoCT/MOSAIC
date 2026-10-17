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

  -- Enter quickly, dwell while the city is most legible, then leave before
  -- the atmospheric handoff. Motion is intentionally more salient than the
  -- procedural geography during the one interval where a viewer might audit it.
  local startP, enterEnd, holdEnd, endP = 0.285, 0.405, 0.665, 0.805
  if progress <= startP or progress >= endP then return end
  local fadeIn = Arrival.clamp((progress - startP) / 0.045)
  local fadeOut = Arrival.clamp((endP - progress) / 0.060)
  local alpha = math.min(fadeIn, fadeOut)
  if alpha <= 0 then return end

  local scale = math.max(0.76, math.min(1.42, height / 1080))
  local panelW = math.min(width * 0.46, 780 * scale)
  local panelH = math.min(height * 0.39, 405 * scale)
  local left
  if progress < enterEnd then
    local u = Arrival.clamp((progress - startP) / (enterEnd - startP))
    u = u * u * (3 - 2 * u)
    left = (width + panelW * 0.05) * (1 - u) + (width * 0.53) * u
  elseif progress < holdEnd then
    local u = Arrival.clamp((progress - enterEnd) / (holdEnd - enterEnd))
    left = width * (0.53 - 0.17 * u)
  else
    local u = Arrival.clamp((progress - holdEnd) / (endP - holdEnd))
    u = u * u * (3 - 2 * u)
    left = width * 0.36 * (1 - u) + (-panelW * 1.04) * u
  end

  local bottom = height * 0.51 - panelH * 0.50
  local right, top = left + panelW, bottom + panelH
  local pad = 22 * scale

  -- Dirty survey glass, not neon HUD. Higher contrast than the first pass so
  -- the eye can actually catch two or three numbers at normal play size.
  gl.Color(0.018, 0.023, 0.026, 0.43 * alpha)
  gl.Rect(left, bottom, right, top)
  gl.Color(0.43, 0.49, 0.49, 0.52 * alpha)
  gl.Rect(left, top - 2.5 * scale, right, top)
  gl.Rect(left, bottom, left + 2.5 * scale, top)

  local headerSize = 15.5 * scale
  local textSize = 13.2 * scale
  gl.Color(0.76, 0.79, 0.77, 0.96 * alpha)
  gl.Text("ORB-CIV // REGIONAL RISK AGGREGATE", left + pad, top - 31 * scale,
      headerSize, "o")
  gl.Color(0.56, 0.60, 0.58, 0.84 * alpha)
  gl.Text("MODEL ESTIMATE // " .. riskPacket.theme ..
      " // CONF " .. riskPacket.confidence .. "%", left + pad,
      top - 53 * scale, 10.8 * scale, "o")

  local y = top - 86 * scale
  local barLeft = left + panelW * 0.61
  local barMax = panelW * 0.235
  for _, line in ipairs(riskPacket.lines) do
    gl.Color(0.70, 0.72, 0.69, 0.92 * alpha)
    gl.Text(line.label, left + pad, y, textSize, "o")
    gl.Color(0.16, 0.19, 0.19, 0.72 * alpha)
    gl.Rect(barLeft, y + 2.5 * scale, barLeft + barMax, y + 7.5 * scale)
    gl.Color(0.56, 0.59, 0.56, 0.88 * alpha)
    gl.Rect(barLeft, y + 2.5 * scale,
        barLeft + barMax * line.value / 100, y + 7.5 * scale)
    gl.Color(0.76, 0.70, 0.61, 0.96 * alpha)
    gl.Text(string.format("%02d%%", line.value), right - pad,
        y, textSize, "or")
    y = y - 31 * scale
  end

  gl.Color(0.76, 0.55, 0.27, 0.98 * alpha)
  gl.Text(riskPacket.status, left + pad, bottom + 24 * scale,
      14.0 * scale, "o")

  -- Target-acquisition bracket near the optical axis visually binds the card
  -- to the territory without pretending the percentages are literal GIS data.
  local cx, cy = width * 0.50, height * 0.49
  local arm, gap, thick = 25 * scale, 12 * scale, 1.7 * scale
  gl.Color(0.56, 0.61, 0.59, 0.32 * alpha)
  gl.Rect(cx - gap - arm, cy - gap - thick, cx - gap, cy - gap)
  gl.Rect(cx + gap, cy - gap - thick, cx + gap + arm, cy - gap)
  gl.Rect(cx - gap - arm, cy + gap, cx - gap, cy + gap + thick)
  gl.Rect(cx + gap, cy + gap, cx + gap + arm, cy + gap + thick)
  gl.Rect(cx - gap - thick, cy - gap - arm, cx - gap, cy - gap)
  gl.Rect(cx + gap, cy - gap - arm, cx + gap + thick, cy - gap)
  gl.Rect(cx - gap - thick, cy + gap, cx - gap, cy + gap + arm)
  gl.Rect(cx + gap, cy + gap, cx + gap + thick, cy + gap + arm)

  gl.Color(0.47, 0.52, 0.51, 0.42 * alpha)
  local tickY = bottom + 10 * scale
  for i = 0, 6 do
    local tx = right - pad - i * 17 * scale
    gl.Rect(tx, tickY, tx + 9 * scale, tickY + 1.7 * scale)
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
