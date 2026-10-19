function widget:GetInfo()
  return {name = "Orbital Arrival", desc = "Screen-space loading-to-city descent",
    author = "MOSAIC", license = "GPL2", layer = 100000, enabled = true}
end

local Arrival = VFS.Include("luaui/widgets_mosaic/include/orbital_arrival.lua")
local renderer, liveTexture, modal
local width, height, offsetX, offsetY
local timer, texture, age, fade, descent
local riskPacket, targetName
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
  targetName = nil
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
  targetName = tostring(Game.mapName or "UNASSIGNED SECTOR"):gsub("[\r\n]", " "):upper()
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

local function overlayLine(x1, y1, x2, y2)
  gl.BeginEnd(GL.LINES, function()
    gl.Vertex(x1, y1)
    gl.Vertex(x2, y2)
  end)
end

local function overlayBox(left, bottom, right, top)
  overlayLine(left, bottom, right, bottom)
  overlayLine(right, bottom, right, top)
  overlayLine(right, top, left, top)
  overlayLine(left, top, left, bottom)
end

local function fittedText(text, x, y, size, available, options)
  -- GetTextWidth is measured at unit font size. Fit unusually long map names
  -- and risk labels without truncating any of the deterministic content.
  local units = gl.GetTextWidth and gl.GetTextWidth(text) or #text * 0.62
  gl.Text(text, x, y, math.min(size, available / math.max(units, 0.01)), options or "o")
end

local function drawRiskOverlay(progress)
  if not riskPacket or not width or not height then return end

  -- The lock belongs to the entire arrival, including the cloud passage.
  -- Only the artwork blend and the terminal handoff change its visibility;
  -- the final .98..1 cloud interval must remain the exact live framebuffer.
  local cloud = Arrival.cloudDescent(progress)
  local alpha = (fade or 0) * (1 - Arrival.clamp((cloud - 0.94) / 0.04))
  if alpha <= 0 then return end
  local target = Arrival.targetFrame(progress, width, height)

  local scale = math.min(1.35, math.max(0.85, height / 900))
  local margin = math.max(10, 20 * scale)
  -- Reserve room for the largest selected footprint too, so a compact
  -- viewport never places the later target rectangle over telemetry rows.
  local finalTarget = Arrival.targetFrame(1, width, height)
  local clearWidth = width - margin - finalTarget.right - 8 * scale
  local panelW = math.max(60, math.min(width * 0.43, 300 * scale, clearWidth))
  local panelH = math.min(height - margin * 2, 230 * scale)
  -- Compact screens retain every row. The width fit below handles long
  -- labels while vertical spacing follows the available panel height.
  local sy = panelH / 230
  local right, top = width - margin, height - margin
  local left, bottom = right - panelW, top - panelH
  local pad = math.min(16 * scale, panelW * 0.055)
  local textLeft, textRight = left + pad, right - pad
  local contentW = panelW - pad * 2

  -- High-contrast survey glass stays at the screen edge. It never sweeps
  -- across the city or changes the sampled risk packet while approaching.
  gl.Color(0.018, 0.026, 0.028, 0.82 * alpha)
  gl.Rect(left, bottom, right, top)
  gl.LineWidth(1)
  gl.Color(0.44, 0.64, 0.65, 0.76 * alpha)
  overlayBox(left, bottom, right, top)
  gl.Color(0.94, 0.74, 0.39, 0.94 * alpha)
  gl.Rect(left, top - 2 * sy, left + panelW * 0.25, top)

  gl.Color(0.98, 0.93, 0.80, alpha)
  local themeW = math.min(contentW * 0.31, 65 * scale)
  fittedText("TARGET LOCK", textLeft, top - 25 * sy, 16.5 * scale,
      contentW - themeW - 8 * scale)
  gl.Color(0.96, 0.77, 0.46, alpha)
  fittedText(riskPacket.theme, textRight, top - 24 * sy,
      10.5 * scale, themeW, "or")
  gl.Color(0.57, 0.77, 0.77, 0.98 * alpha)
  fittedText(targetName, textLeft, top - 43 * sy, 10.8 * scale, contentW)
  gl.Color(0.71, 0.79, 0.77, 0.98 * alpha)
  fittedText("MODEL ESTIMATE // CONF " .. riskPacket.confidence .. "%",
      textLeft, top - 61 * sy, 10.5 * scale, contentW)
  gl.Color(0.36, 0.49, 0.48, 0.66 * alpha)
  gl.Rect(textLeft, top - 70 * sy, textRight, top - 69 * sy)

  local y = top - 90 * sy
  local numberW = 38 * scale
  for _, line in ipairs(riskPacket.lines) do
    gl.Color(0.78, 0.84, 0.81, alpha)
    fittedText(line.label, textLeft, y, 13.5 * scale, contentW - numberW - 8 * scale)
    gl.Color(0.98, 0.78, 0.45, alpha)
    fittedText(string.format("%02d%%", line.value), textRight, y,
        14.0 * scale, numberW, "or")
    y = y - 24 * sy
  end
  gl.Color(0.36, 0.49, 0.48, 0.66 * alpha)
  gl.Rect(textLeft, bottom + 33 * sy, textRight, bottom + 34 * sy)
  gl.Color(0.98, 0.73, 0.31, alpha)
  fittedText(riskPacket.status, textLeft, bottom + 14 * sy,
      12.5 * scale, contentW)

  -- Project the same destination footprint as the scene, instead of placing
  -- an unrelated reticle at screen center. The leader ends at its near corner.
  local anchorX, anchorY = left + pad, bottom
  local elbowX, elbowY = anchorX - 12 * scale, bottom - 12 * scale
  local tx, ty = target.right, target.top
  local function lockGeometry()
    overlayLine(anchorX, anchorY, elbowX, elbowY)
    overlayLine(elbowX, elbowY, tx, ty)
    overlayBox(target.left, target.bottom, target.right, target.top)
  end
  gl.LineWidth(math.max(2, 3 * scale))
  gl.Color(0.015, 0.023, 0.022, 0.80 * alpha)
  lockGeometry()
  gl.LineWidth(math.max(1, 1.35 * scale))
  gl.Color(0.98, 0.93, 0.78, 0.98 * alpha)
  lockGeometry()

  -- Short acquisition ticks remain legible on bright cloud tops and dark
  -- streets. Their center shares the destination's coordinates at every cut.
  local tick = math.max(3, 5 * scale)
  gl.Color(0.95, 0.72, 0.34, 0.94 * alpha)
  overlayLine(target.cx - tick, target.cy, target.cx + tick, target.cy)
  overlayLine(target.cx, target.cy - tick, target.cx, target.cy + tick)
  gl.LineWidth(1)
  gl.Color(0.84, 0.88, 0.80, 0.95 * alpha)
  local captionY = math.max(8 * scale, target.bottom - 17 * scale)
  fittedText("TARGET // 01",
      target.left, captionY, 10.2 * scale,
      math.max(50 * scale, width - margin - target.left))

  -- Stable phase and altitude cues leave the open center free for the city.
  local phaseW = math.max(1, left - margin * 2)
  gl.Color(0.96, 0.90, 0.75, alpha)
  fittedText(string.format("%02d", target.stage) .. " / " .. target.label,
      margin, top - 21 * scale, 15 * scale, phaseW)
  gl.Color(0.52, 0.72, 0.73, 0.94 * alpha)
  fittedText("ALT ~ " .. target.altitude, margin, top - 42 * scale,
      10.8 * scale, phaseW)
  gl.Color(0.38, 0.56, 0.57, 0.60 * alpha)
  gl.Rect(margin, top - 52 * scale,
      margin + math.min(128 * scale, phaseW), top - 51 * scale)
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
