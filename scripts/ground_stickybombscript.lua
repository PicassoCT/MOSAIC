include "lib_UnitScript.lua"
local config = VFS.Include("luarules/configs/sticky_bombs.lua")
local blink = piece "BLINK"
local center = piece "center"

local function fuse()
    -- Payload is assigned immediately after CreateUnit returns. No proximity search.
    while not (GG.StickyBombPayloads and GG.StickyBombPayloads[unitID]) do Sleep(33) end
    local payload = GG.StickyBombPayloads[unitID]
    GG.StickyBombPayloads[unitID] = nil
    local target = payload.target
    local remaining, visible = payload.fuse, false
    while remaining > 0 do
        visible = not visible
        if visible then Show(blink); EmitSfx(center, 1025) else Hide(blink) end
        local delay = math.min(256, remaining)
        Sleep(delay)
        remaining = remaining - delay
    end
    local x, y, z = Spring.GetUnitPosition(unitID)
    if x then config.explode(unitID, target, x, y, z, payload.count) end
    Spring.DestroyUnit(unitID, false, true)
end
function script.Create()
    Spring.SetUnitNoSelect(unitID, true)
    Spring.SetUnitBlocking(unitID, false, false, false)
    Hide(blink)
    StartThread(fuse)
end
function script.Killed()
    return 1
end
