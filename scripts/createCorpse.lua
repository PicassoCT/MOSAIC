include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

include "lib_Build.lua"
include "lib_mosaic.lua"

--die young- leave a great corpse
GameConfig = getGameConfig()
local civilianWalkingTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture, "civilian", UnitDefs)

function createCorpseCBuilding(unitID, recentDamage)
    --<RubbleScript>
    if unitID and Spring.ValidUnitID(unitID) == true then
        if recentDamage == nil or recentDamage > 1 then
            --This script spawns the rubbleHeap. If you too drunk to understad, just copy and paste into the Killed function

            spx, spy, spz = Spring.GetUnitPosition(unitID)
            teamID = Spring.GetGaiaTeamID()
            x = math.random(0, 3)
            heapID = Spring.CreateUnit("gCScrapHeap", spx, spy, spz, x, teamID)
            Spring.SetUnitNeutral(heapID, true)
            --</RubbleScript>
            --<ciVillian>
            spx, spy, spz = Spring.GetUnitPosition(unitID)
            teamID = Spring.GetGaiaTeamID()
            x = math.random(1, 5)
            for i = 1, x, 1 do
                maRa = math.random(-1, 1)
                heapID = Spring.CreateUnit(randT(civilianWalkingTypeTable), spx + (150 * maRa), spy, spz + (150 * maRa), 1, teamID)
                Spring.SetUnitMoveGoal(heapID, spx + 1000, spy, spz + 1000)
                Spring.SetUnitNeutral(heapID, true)
            end

            --</ciVillian>
        else
            --This script spawns the rubbleHeap. If you too drunk to understad, just copy and paste into the Killed function
            spx, spy, spz = Spring.GetUnitPosition(unitID)
            teamID = Spring.GetGaiaTeamID()
            x = math.random(0, 3)
            -- GG.UnitsToSpawn:PushCreateUnit("gCScrapHeapPeace", spx, spy, spz, x, teamID)

        end
        --</RubbleScript>
    end
end

function createCorpseCUnitSmall(recentDamage)

    if recentDamage == nil or recentDamage > 1 then
        --This script spawns the rubbleHeap. If you too drunk to understad, just copy and paste into the Killed function
        spx, spy, spz = Spring.GetUnitPosition(unitID)
        --teamID=Spring.GetUnitTeam(unitID)
        teamID = Spring.GetGaiaTeamID()
        --dirx,diry,dirz=Spring.GetUnitDirection(unitID)


       GG.UnitsToSpawn:PushCreateUnit("gCVehicCorpseMini", spx, spy, spz, 1, teamID)
  GG.UnitsToSpawn:PushCreateFeature("bodybag", spx, spy, spz, 1, teamID)

    end
end

function createCorpseCUnitGeneric(recentDamage)

    if recentDamage == nil or recentDamage > 1 then

         --This script spawns the rubbleHeap. If you too drunk to understad, just copy and paste into the Killed function
        spx, spy, spz = Spring.GetUnitPosition(unitID)
        --teamID=Spring.GetUnitTeam(unitID)
        teamID = Spring.GetGaiaTeamID()
        --dirx,diry,dirz=Spring.GetUnitDirection(unitID)


        GG.UnitsToSpawn:PushCreateUnit("gCVehicCorpse", spx, spy, spz, 1, teamID)
        --Spring.SetUnitDirection(heapID,dirx,diry,dirz)
       -- Spring.SetUnitNeutral(heapID, true)
    end
end
