include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

GameConfig = getGameConfig()
TablesOfPiecesGroups = {}
myDefID = Spring.GetUnitDefID(unitID)
gaiaTeamID = Spring.GetGaiaTeamID()
myTeamID = Spring.GetUnitTeam(unitID)
function script.HitByWeapon(x, z, weaponDefID, damage) end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(blackOutCycle)
    StartThread(lifeTime, unitID, GameConfig.LifeTimeBribeIcon, true, false,
     function() 
        foreach(blackOuttedUnits_OriginalState,
                function (id)
                    if id then
                        Spring.SetUnitNoSelect(id, blackOuttedUnits_OriginalState[id])
                    end
                end
            )
     end
     )
end

blackOuttedUnits_OriginalState = {}

function blackOutCycle()
    while true do  
        unitsInCircle = getAllNearUnit(untiID,GameConfig.iconBlackHoleComDeactivateRange)
        filteredUnitsInCircle = {}
        foreach(unitsInCircle,
                function(id)
                    if blackOuttedUnits_OriginalState[id] ~= nil then
                        return id
                    end
                end,
                function(id)
                    teamID = Spring.GetUnitTeam(id)
                    if teamID ~= myTeamID and teamID ~= gaiaTeamID then
                        return id
                    end
                end,
                function(id)
                    blackOuttedUnits_OriginalState[id] = Spring.GetUnitNoSelect(id)
                    Spring.SetUnitNoSelect(id, true)
                    filteredUnitsInCircle[id] = id
                end
                )

        for id,state in pairs(blackOuttedUnits_OriginalState) do
            if id and state ~= nil then 
                if not filteredUnitsInCircle[id] then
                    Spring.SetUnitNoSelect(id, blackOuttedUnits_OriginalState[id])
                    blackOuttedUnits_OriginalState[id] = nil
                end
            end
        end

        Sleep(1000)
    end
end

function script.Killed(recentDamage, _)
    return 1
end

function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end
