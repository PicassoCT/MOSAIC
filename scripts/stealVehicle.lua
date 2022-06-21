include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

myTeamID = Spring.GetUnitTeam(unitID)

function script.Create()

    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
   
    StartThread(stealVehicle)
end

function stealVehicle()
    local recruitmentRange = GameConfig.agentConfig.recruitmentRange
    local spGetUnitTeam = Spring.GetUnitTeam
    local spGetUnitDefID = Spring.GetUnitDefID
    local spGetUnitPosition = Spring.GetUnitPosition
    local spDestroyUnit = Spring.DestroyUnit
    waitTillComplete(unitID)
    StartThread(lifeTime, unitID, 15000, true, false)

    while true do
        Sleep(100)
        foreach(getAllNearUnit(unitID, recruitmentRange), 
        function(id)
            if spGetUnitTeam(id) == gaiaTeamID then return id end
        end, 
        function(id)
            recruitedDefID = spGetUnitDefID(id)
            if TruckTypeTable[recruitedDefID] then
               ad = copyUnit(id, teamID)
                fatherID = fatherID or unitID
                x,y,z = Spring.GetUnitPosition(fatherID)
                if doesUnitExistAlive(id) == doesUnitExistAlive(fatherID) then
                     Spring.SetUnitLoadingTransport(fatherID, ad)
                     env = Spring.UnitScript.GetScriptEnv(ad) 
                    if env and env.TransportPickup then
                        Spring.UnitScript.CallAsUnit(ad, env.TransportPickup,fatherID)
                    end
                end
               spDestroyUnit(id, false, true)
               spDestroyUnit(unitID, false, true)
               endIcon()
            end
        end
        )
    end
end

function endIcon()
    Spring.DestroyUnit(unitID, false, true)
    while true do Sleep(1000) end
end


function script.Killed(recentDamage, _)
    return 1
end
