if addon.InGetInfo then
  return {name = "LoadTexture", desc = "Rotating loading artwork with a final cinematic handoff",
    author = "MOSAIC", license = "GPL2", layer = 2,
    depend = {"LoadProgress"}, enabled = true}
end

-- LuaIntro may run for minutes at a few frames per second. It must NEVER
-- compile or draw the orbital shader while the engine is still loading.
-- Only pass the chosen artwork to LuaUI; simulation frames own the descent.
local Arrival = VFS.Include("luaui/widgets_mosaic/include/orbital_arrival.lua")
local screens = VFS.DirList("luaui/images/loadpictures/", "*.png")
local selected = #screens > 0 and math.random(1, #screens) or nil
local texture = selected and screens[selected] or ""
local changeSeconds = 30
local lastChange, stopped

Arrival.beginHandoff()
Arrival.writeHandoff(texture, 0, 0, 0)

-- Keep the normal loading progress visible throughout loading.
function SG.IsOrbitalArrivalActive() return false end

function addon.DrawLoadScreen()
  -- Use wall time: simulation time does not advance during engine loading.
  -- Start at the first displayed image, and never catch up with a burst of
  -- unseen pictures after a loading stall.
  if not stopped and #screens > 1 then
    local now = Spring.GetTimer()
    if not lastChange then
      lastChange = now
    elseif Spring.DiffTimers(now, lastChange) >= changeSeconds then
      local nextIndex = math.random(1, #screens - 1)
      if nextIndex >= selected then nextIndex = nextIndex + 1 end
      local previous = texture
      selected, texture, lastChange = nextIndex, screens[nextIndex], now
      Arrival.writeHandoff(texture, 0, 0, 0)
      -- Only retired slides are released. The final image remains available
      -- for LuaUI's exact-image hold and subsequent flicker-out.
      gl.DeleteTexture(previous)
    end
  end
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
  stopped = true
  -- An informational marker only, NOT a gate for starting the cinematic.
  Arrival.finishIntro()
  Spring.Echo("[MOSAIC arrival] LuaIntro finished loading slideshow")
  -- The VFS artwork path belongs to the pending LuaUI handoff.
  -- Do not gl.DeleteTexture(texture) while the receiving widget needs it.
end
