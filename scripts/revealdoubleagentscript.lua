-- Retired global reveal: existing/cheat-spawned icons refund their cost.
-- Investigations are now explicit operative commands, never self-investigation.
include "lib_UnitScript.lua"
local function retire()
    if not waitTillComplete(unitID) then return end
    local def = UnitDefs[Spring.GetUnitDefID(unitID)]
    local team = Spring.GetUnitTeam(unitID)
    Spring.AddTeamResource(team, "metal", def.metalCost or 0)
    Spring.AddTeamResource(team, "energy", def.energyCost or 0)
    Spring.DestroyUnit(unitID, false, true)
end
function script.Create() StartThread(retire) end
function script.Killed() return 0 end
