function widget:GetInfo()
  return {name = "Orbital Arrival", desc = "Screen-space loading-to-city descent",
    author = "MOSAIC", license = "GPL2", layer = 100000, enabled = true}
end

local Arrival = VFS.Include("luaui/widgets_mosaic/include/orbital_arrival.lua")
local renderer, liveTexture, modal
local width, height, offsetX, offsetY
local timer, texture, age, fade, descent, initialFade
local guiWasHidden, hasCapture, started = false, false, false
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
  if texture and texture ~= "" then gl.DeleteTexture(texture) end
  WG.MosaicArrivalFinished = true
end

function widget:Initialize()
  -- Reloads, saved games and mid-match joins must never replay or lock the UI.
  if WG.MosaicArrivalFinished or Arrival.introPhase() == "played"
      or Spring.GetGameFrame() > Arrival.latestStartFrame then
    widgetHandler:RemoveWidget(self); return
  end
  renderer = Arrival.newRenderer()
  if not renderer then finish(); widgetHandler:RemoveWidget(self); return end
  modal = {active = true, skip = finish}
  WG.MosaicArrival = modal
end

function widget:Shutdown() finish() end

local function begin()
  texture, age, initialFade = Arrival.readHandoff()
  if not texture then
    texture, age, initialFade = "", Arrival.artSeconds, 1
  end
  fade, descent = initialFade, 0
  timer = Spring.GetTimer()
  guiWasHidden = Spring.IsGUIHidden()
  started = true
  if not guiWasHidden then Spring.SendCommands("hideinterface") end
  -- Disable engine edge scrolling, restore the user's settings on all exits.
  for _, key in ipairs({"FullscreenEdgeMove", "WindowedEdgeMove"}) do
    savedEdges[key] = Spring.GetConfigInt(key, 1)
    Spring.SetConfigInt(key, 0, true)
  end
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

function widget:DrawScreenEffects()
  if finished or not renderer then return end
  if not started then
    -- The first advancing simulation frame is the ONLY descent trigger.
    -- LuaIntro shutdown, LuaUI readiness and city spawn are not clocks.
    if Spring.GetGameFrame() <= 0 then return end
    begin()
  end
  local elapsed = Spring.DiffTimers(Spring.GetTimer(), timer)
  -- A half-second artwork -> orbit blend, then five half-second scale beats.
  -- Wall time keeps the visual cadence fixed even if simulation FPS fluctuates.
  fade = math.max(initialFade, Arrival.clamp(elapsed / Arrival.blendSeconds))
  descent = Arrival.clamp((elapsed - Arrival.blendSeconds) / Arrival.descentSeconds)
  modal.elapsed, modal.descent = elapsed, descent
  if not capture() then finish(); return end
  hasCapture = true
  if not renderer:draw(width, height, texture, age + elapsed, fade, descent, liveTexture) then
    finish(); return
  end
  if descent >= 1 then finish() end
end

function widget:DrawScreenPost()
  -- Reuse the CLEAN world capture after engine overlays/cursor. No feedback.
  if finished or not hasCapture then return end
  renderer:draw(width, height, texture, age + modal.elapsed, fade, descent, liveTexture)
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
