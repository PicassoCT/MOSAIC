if addon.InGetInfo then
  return {name = "LoadTexture", desc = "Artwork to orbital arrival", author = "MOSAIC",
    license = "GPL2", layer = 2, depend = {"LoadProgress"}, enabled = true}
end

local Arrival = VFS.Include("luaui/widgets_mosaic/include/orbital_arrival.lua")
local screens = VFS.DirList("luaui/images/loadpictures/", "*.png")
local texture = #screens > 0 and screens[math.random(1, #screens)] or ""
local startTimer = Spring.GetTimer()
local renderer = Arrival.newRenderer()
local active = false
Arrival.beginHandoff()
function SG.IsOrbitalArrivalActive() return active end

function addon.DrawLoadScreen()
  local width, height = gl.GetViewSizes()
  local age = Spring.DiffTimers(Spring.GetTimer(), startTimer)
  local fade, descent = Arrival.loadingState(age)
  active = renderer ~= nil and fade > 0
  -- LuaUI initializes while LuaIntro is still alive; read this on its first draw,
  -- not during Initialize. Shutdown retains the last *displayed* state.
  if renderer then Arrival.writeHandoff(texture, age, fade, descent) end
  gl.PushMatrix()
  gl.Scale(1 / width, 1 / height, 1)
  if renderer then
    if not renderer:draw(width, height, texture, age, fade, descent) then
      renderer:destroy(); renderer = nil; active = false
    end
  end
  if not renderer and texture ~= "" then
    gl.Color(1, 1, 1, 1)
    gl.Texture(texture); gl.TexRect(0, 0, width, height); gl.Texture(false)
  end
  gl.PopMatrix()
end

function addon.Shutdown()
  -- This is the authoritative loading-screen boundary. LuaUI is allowed to
  -- start the descent only after LuaIntro has actually relinquished control.
  Arrival.finishIntro()
  if renderer then renderer:destroy() end
  if texture ~= "" then gl.DeleteTexture(texture) end
end
