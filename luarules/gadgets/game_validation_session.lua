function gadget:GetInfo()
    return {
        name = 'Validation match identity',
        desc = 'Match identity and on-demand reconstruction diagnostics',
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

-- A status request changes no plot, unit or random state. Replies go only to
-- the requesting player and are bounded even after a city-wide destruction.
local lastRequestFrame = {}
local function display(value)
    return value == nil and 'none' or tostring(value)
end

function gadget:RecvLuaMsg(message, playerID)
    if type(message) ~= 'string' then return false end
    local prefix = config.rebuildStatusMessage
    local selected
    if message ~= prefix then
        if message:sub(1, #prefix + 1) ~= prefix .. ':' then return false end
        local suffix = message:sub(#prefix + 2)
        if not suffix:match('^%d+$') or #suffix > 8 then return false end
        selected = tonumber(suffix)
    end
    local frame = Spring.GetGameFrame()
    local previous = lastRequestFrame[playerID]
    if previous and frame - previous < 30 then return true end
    lastRequestFrame[playerID] = frame
    local function reply(text)
        Spring.SendMessageToPlayer(playerID, config.prefix .. text)
    end
    local service = GG.CityReconstruction
    if not service or type(service.GetStatus) ~= 'function' then
        reply('Reconstruction: status unavailable; check Spawn City Gadget errors earlier in infolog.')
        return true
    end
    local status = service:GetStatus()
    reply(string.format('Reconstruction frame=%d queued=%d completed=%d active=%d waiting_for_collapse=%d rubble=%d construction=%d',
        frame, status.queued, status.completed, status.active,
        status.waitingForRemoval, status.rubble, status.construction))
    local plots, matches = status.plots, {}
    if selected then
        for _, plot in ipairs(plots) do
            if plot.unitID == selected or plot.sourceUnitID == selected or plot.originalUnitID == selected then
                matches[#matches + 1] = plot
            end
        end
        if #matches == 0 then
            reply('Selected unit ' .. selected .. ' has no active reconstruction plot; showing recent plots.')
        end
    end
    if #matches == 0 then
        for index = math.max(1, #plots - 7), #plots do matches[#matches + 1] = plots[index] end
    end
    local shown = math.min(8, #matches)
    for index = #matches - shown + 1, #matches do
        local plot = matches[index]
        local defID = plot.unitID and Spring.GetUnitDefID(plot.unitID)
        local definition = defID and UnitDefs[defID]
        reply(string.format('Plot %d at %.0f,%.0f stage=%s source=%s waiting=%s unit=%s type=%s paused=%s reason=%s elapsed=%d rubble_attempts=%d rubble_failures=%d site_attempts=%d site_failures=%d',
            plot.id, plot.x, plot.z, display(plot.stage), display(plot.sourceUnitID), display(plot.sourceWaiting),
            display(plot.unitID), display(definition and definition.name), display(plot.paused), display(plot.pauseReason),
            plot.elapsed, plot.rubbleSpawnAttempts, plot.rubbleSpawnFailures, plot.siteSpawnAttempts, plot.siteSpawnFailures))
    end
    if #plots > shown then reply('Showing ' .. shown .. ' of ' .. #plots .. ' active plots. Select a rubble/site to filter.') end
    if status.active == 0 then reply('No destroyed-house plots are queued. A partially collapsed house may still be alive; select it and use /validate status.') end
    return true
end
