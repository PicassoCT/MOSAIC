if addon.InGetInfo then
  return {name = "LoadTexture", desc = "Static artwork until simulation starts",
    author = "MOSAIC", license = "GPL2", layer = 2,
    depend = {"LoadProgress"}, enabled = true}
end

-- LuaIntro may run for minutes at a few frames per second. It must NEVER
-- compile or draw the orbital shader while the engine is still loading.
-- Only pass the chosen artwork to LuaUI; simulation frames own the descent.
local Arrival = VFS.Include("luaui/widgets_mosaic/include/orbital_arrival.lua")
local screens = VFS.DirList("luaui/images/loadpictures/", "*.png")
local texture = #screens > 0 and screens[math.random(1, #screens)] or ""

Arrival.beginHandoff()
Arrival.writeHandoff(texture, 0, 0, 0)

-- Keep the normal loading progress visible throughout loading.
function SG.IsOrbitalArrivalActive() return false end

function addon.DrawLoadScreen()
  local width, height = gl.GetViewSizes()
  gl.PushMatrix()
  gl.Scale(1 / width, 1 / height, 1)
  gl.Color(1, 1, 1, 1)
  if texture ~= "" then
    gl.Texture(texture)
    gl.TexRect(0, 0, width, height)
    gl.Texture(false)
  else
    gl.Color(0, 0, 0, 1)
    gl.Rect(0, 0, width, height)
    gl.Color(1, 1, 1, 1)
  end
  gl.PopMatrix()
end

function addon.Shutdown()
  -- An informational marker only, NOT a gate for starting the cinematic.
  Arrival.finishIntro()
  Spring.Echo("[MOSAIC arrival] LuaIntro finished static loading screen")
  -- The VFS artwork path belongs to the pending LuaUI handoff.
  -- Do not gl.DeleteTexture(texture) while the receiving widget needs it.
end
