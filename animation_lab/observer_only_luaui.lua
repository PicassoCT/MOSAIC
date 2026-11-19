-- Opt-in external rendering fixture for engines that crash in the game HUD.
-- Reuses the lab's framebuffer observer. Synced game code and models are unchanged.
WG = {}
widget = {}
widgetHandler = {}
function widgetHandler:RegisterGlobal(name, fn)
    assert(_G[name] == nil, 'observer global already exists: ' .. name)
    _G[name] = fn
end
function widgetHandler:DeregisterGlobal(name) _G[name] = nil end
VFS.Include('luaui/widgets_mosaic/dbg_animation_lab_capture.lua')
function Update(...) return widget:Update(...) end
function DrawScreenPost(...) return widget:DrawScreenPost(...) end
function Shutdown(...) return widget:Shutdown(...) end
widget:Initialize()
