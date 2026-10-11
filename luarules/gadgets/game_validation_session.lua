function gadget:GetInfo()
    return {
        name = 'Validation match identity',
        desc = 'Makes the engine match ID available to the local validation checklist',
        author = 'MOSAIC contributors',
        license = 'GPL3',
        layer = 0,
        enabled = true,
    }
end

if not gadgetHandler:IsSyncedCode() then return false end

local config = VFS.Include('luaui/configs/mosaic_validation.lua')

-- Recoil delivers the ID as an event; Game.gameID is not a guaranteed engine
-- constant. GameRules metadata survives LuaUI reload and is new for each match.
-- This observer does not change any unit, order, resource or simulation RNG.
function gadget:GameID(gameID)
    -- CLuaHandle::GameID supplies 16 bytes encoded as 32 hex characters. Never
    -- publish raw bytes (which can contain NUL) or a numeric-looking value.
    if type(gameID) == 'string' and #gameID == 32 and gameID:match('^%x+$') then
        Spring.SetGameRulesParam(config.gameIDParam, 'engine:' .. gameID:lower(), {public = true})
    end
end
