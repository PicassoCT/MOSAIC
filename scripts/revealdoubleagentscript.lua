include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

myDefID = Spring.GetUnitDefID(unitID)
myTeamID = Spring.GetUnitTeam(unitID)
function script.HitByWeapon(x, z, weaponDefID, damage) end


function script.Create()

    StartThread(revealAllDoubleAgents)
end

function revealAllDoubleAgents()
    waitTillComplete(unitID)
    if GG.DoubleAgents then
        for traitorID, iconID in pairs(GG.DoubleAgents) do
            if Spring.GetUnitTeam(traitorID) == myTeamID then
                Command(traitorID, "cloak")
            end
        end
    end
    destroyUnitConditional(unitID, false, true)
end

function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end

