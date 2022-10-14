include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"
include "lib_mosaic.lua"
skyscrape = piece "skyscrape"
center = piece "center"

GameConfig = getGameConfig()
distanceToGoDown = 90
TablesOfPiecesGroups = {}
function script.Killed() end



function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    randHide(TablesOfPiecesGroups["scrapHeap"])
    Spring.SetUnitAlwaysVisible(unitID, true)
    if math.random(0, 1) == 1 then Hide(skyscrape) end
    StartThread(waitForAnEnd)
end

boolSleepOnHit = false
function script.HitByWeapon(x, z, weaponDefID, damage)
    boolSleepOnHit = true
    return damage
end

function waitForAnEnd()
    timeForMoveInSec = GameConfig.TimeForScrapHeapDisappearanceInMs / 30
    speed = distanceToGoDown / timeForMoveInSec
   

    for i= 1, -1 * distanceToGoDown, -1 do
        WMove(center, z_axis, i, speed)
        while boolSleepOnHit == true or  GG.GlobalGameState ~= GameConfig.GameState.normal do
            Sleep(GameConfig.minutMS)
            boolSleepOnHit = false
        end            
    end
    Spring.DestroyUnit(unitID, true, false)
end
