include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_mosaic.lua"

local GameConfig = getGameConfig()
local TablesOfPiecesGroups = {}

gaiaTeamID = Spring.GetGaiaTeamID()
myTeamID = Spring.GetUnitTeam(unitID)
stunnedInBlackOutUnitType = getStunnedInBlackOutUnitTypes(UnitDefs)
hologramTypeTable = getHologramTypes(UnitDefs)
local spGetUnitDefID = Spring.GetUnitDefID
 Spinner = piece"Spinner"
 PercentRing = piece"PercentRing"
 Cellphone = piece"Cellphone"
 blackOuttedUnits_OriginalState = {}

function script.Create()
        TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)

        Spring.SetUnitNeutral(unitID,true)
        Spring.SetUnitBlocking(unitID,false)
        StartThread(hoverAboveGround, unitID, GameConfig.iconHoverGroundOffset, 1.0, false)    
        Spin(PercentRing,y_axis,math.rad(-22),0)

        StartThread(animation)
        StartThread(lifeTimeAnimation)
        StartThread(blackOutCycle)

        StartThread(lifeTime, unitID, GameConfig.LifeTimeBlackOutIcon, true, false )
end

function lifeTimeAnimation()
    step = math.ceil(GameConfig.LifeTimeBlackOutIcon/#TablesOfPiecesGroups["Percentages"])
    showT(TablesOfPiecesGroups["Percentages"])
        for i=1, #TablesOfPiecesGroups["Percentages"] do
            Sleep(step)
            Hide(TablesOfPiecesGroups["Percentages"][i])           
        end
end

function animation()
    Spin(Spinner,y_axis, math.rad(42),0)
    while true do
        showT(TablesOfPiecesGroups["Com"])
        for i=6, 0, -1 do            
            Sleep(1000)
            if TablesOfPiecesGroups["Com"][i] then
                Hide(TablesOfPiecesGroups["Com"][i])
            end
        end
        Sleep(5000)
    end
end


function script.HitByWeapon(x, z, weaponDefID, damage) end


function blackOutCycle()
    while true do  
        unitsInCircle = getAllNearUnit(unitID, GameConfig.iconBlackHoleComDeactivateRange)
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
                    defID = spGetUnitDefID(id)
                    if stunnedInBlackOutUnitType[defID] then
                        stunUnit(id, 10.0)
                        spawnCegAtUnit(id, "electric_arc",0, 20, 0)                     
                        return
                    end

                    if hologramTypeTable[defID] then
                        if not GG.BlackOutDeactivationTime then GG.BlackOutDeactivationTime = {} end
                        GG.BlackOutDeactivationTime[id] = Spring.GetGameFrame()
                    end

                    blackOuttedUnits_OriginalState[id] = Spring.GetUnitNoSelect(id)
                    Spring.SetUnitNoSelect(id, true)
                    Command(unitID, "stop")
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
        spawnCegAtUnit(unitID, "orangematrix", math.random(-10,10), math.random(-10,10), math.random(-10,10))
        Sleep(1000)
    end
end

function script.Killed(recentDamage, _)
    foreach(blackOuttedUnits_OriginalState,
            function (id)
                if id then
                    Spring.SetUnitNoSelect(id, blackOuttedUnits_OriginalState[id])
                end
            end
        )     


    return 1
end

function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end
