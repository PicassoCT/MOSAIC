include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}
function script.HitByWeapon(x, z, weaponDefID, damage) return damage end
TruckTypeTable = getTruckTypeTable(UnitDefs)
local spGetUnitDefID = Spring.GetUnitDefID
GameConfig= getGameConfig()

function script.Create()
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitBlocking(unitID, false)
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(waitForCar)
    StartThread(lifeTime, GameConfig.LifeTimeCarStopIconMs)

end

function waitForCar()
    while true do
        foreach(getAllNearUnit(unitID, 90)
            function(id)
                defID = spGetUnitDefID(id)
                if TruckTypeTable[defID] then
                    setSpeedEnv(id, 0.0)
                    Spring.DestroyUnit(unitID, false, true)
                end
            end
            )
        Sleep(500)
    end

end

function script.Killed(recentDamage, _)
    return 1
end

function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

