-- Integration check for the capture/Weatherman merge in the actual rain widget.
-- Run from repository root: lua tests/rain_capture_weather.lua
local captureAPI, active, saved
local function noop() end
widget, WG = {}, {}
Game = {mapName = "mosaic_lastdayofdubai_v", mapSizeX = 1024, mapSizeZ = 1024}
GL = setmetatable({}, {__index = function() return 1 end})
gl = setmetatable({
    GetAtmosphere = function() return 0.2, 0.3, 0.4 end,
    GetSun = function() return 0, 1, 0 end,
}, {__index = function() return function() return 1 end end})
Spring = setmetatable({
    GetViewGeometry = function() return 1280, 720, 0, 0 end,
    GetCameraPosition = function() return 0, 100, 0 end,
    GetCameraDirection = function() return 0, -1, 0 end,
    GetGameFrame = function() return 0 end,
    GetTimer = function() return 0 end,
}, {__index = function() return noop end})
widgetHandler = {UpdateCallIn = noop}
VFS = {Include = function(path)
    assert(path == "luaui/widgets_mosaic/include/rain_capture.lua")
    return function(api)
        captureAPI = api
        return {
            command = function(command)
                if command == "rainsnap" then
                    saved = api.save(); api.prepare(); active = true
                    return true
                elseif command == "rainsnap cancel" then
                    api.restore(saved); active = false
                    return true
                end
                return false
            end,
            active = function() return active end,
            update = function()
                if active then api.setRain(0.3); return true end
                return false
            end,
        }
    end
end}
dofile("luaui/widgets_mosaic/gfx_rain.lua")
widget:TextCommand("Weatherman on")
widget:Update(0.01)
assert(captureAPI.save().rain == 1)
widget:TextCommand("rainsnap")
widget:Update(0.01)
assert(captureAPI.save().rain == 0.3)
widget:TextCommand("Weatherman off")
widget:TextCommand("rainreflection on")
assert(captureAPI.save().rain == 0.3 and not captureAPI.save().reflection)
widget:TextCommand("rainsnap cancel")
widget:Update(0.01)
assert(captureAPI.save().rain == 1) -- Weatherman remained on during the capture.
widget:TextCommand("Weatherman off")
widget:Update(0.01)
assert(captureAPI.save().rain == 0) -- Natural daytime weather survived the override.
widget:TextCommand("rainreflection on")
widget:TextCommand("rainsnap")
widget:Update(0.01)
widget:TextCommand("rainsnap cancel")
assert(captureAPI.save().reflection and captureAPI.save().rain == 1)
print("PASS: capture takes priority, weather/debug commands are blocked, Weatherman and natural weather restore")
