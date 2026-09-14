function gadget:GetInfo()
    return {
        name = "Unit script ownership events",
        desc = "Forward ownership notifications to opt-in unit scripts",
        author = "Mosaic contributors",
        license = "GPL3",
        layer = 0,
        enabled = true,
    }
end

if not gadgetHandler:IsSyncedCode() then return false end

function gadget:UnitGiven(unitID, unitDefID, newTeam, oldTeam)
    local env = Spring.UnitScript.GetScriptEnv(unitID)
    local handler = env and env.onUnitGivenEvent
    if type(handler) == "function" then
        -- Establish the unit context. The exposed handler queues its own
        -- deferred coroutine; never yield from this engine notification.
        Spring.UnitScript.CallAsUnit(unitID, handler, unitDefID, newTeam, oldTeam)
    end
end
