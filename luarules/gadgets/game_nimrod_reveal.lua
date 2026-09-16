function gadget:GetInfo()
    return {
        name = "Nimrod firing exposure",
        desc = "A Nimrod remains visible to everyone after its first shot",
        author = "MOSAIC contributors",
        license = "GPL3",
        layer = 5,
        enabled = true,
    }
end

if not gadgetHandler:IsSyncedCode() then return end

local nimrodDefID = UnitDefNames.nimrod.id
local exposed = {}

local function reveal(unitID)
    if Spring.GetUnitDefID(unitID) ~= nimrodDefID then return end
    exposed[unitID] = true
    Spring.SetUnitRulesParam(unitID, "nimrod_fired", 1, {public = true})
    Spring.SetUnitCloak(unitID, false)
    Spring.SetUnitAlwaysVisible(unitID, true)
    local env = Spring.UnitScript.GetScriptEnv(unitID)
    if env and env.showHideIcon then
        Spring.UnitScript.CallAsUnit(unitID, env.showHideIcon, false)
    end
end

local function restoreExposure(unitID, unitDefID)
    if unitDefID == nimrodDefID and
        (exposed[unitID] or Spring.GetUnitRulesParam(unitID, "nimrod_fired") == 1) then
        reveal(unitID)
    end
end

function gadget:Initialize()
    GG.RevealNimrodOnFire = reveal
    for _, unitID in ipairs(Spring.GetAllUnits()) do
        restoreExposure(unitID, Spring.GetUnitDefID(unitID))
    end
end

function gadget:AllowUnitCloak(unitID)
    return not exposed[unitID]
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams)
    if exposed[unitID] and cmdID == CMD.CLOAK and cmdParams[1] ~= 0 then
        return false
    end
    return true
end

function gadget:UnitCreated(unitID, unitDefID)
    restoreExposure(unitID, unitDefID)
end

function gadget:UnitGiven(unitID, unitDefID)
    restoreExposure(unitID, unitDefID)
end

function gadget:UnitTaken(unitID, unitDefID)
    restoreExposure(unitID, unitDefID)
end

function gadget:UnitDestroyed(unitID)
    exposed[unitID] = nil
end

function gadget:Shutdown()
    if GG.RevealNimrodOnFire == reveal then GG.RevealNimrodOnFire = nil end
end
