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

function waitForAnEnd()
    timeForMoveInSec = GameConfig.TimeForScrapHeapDisappearanceInMs / 30
    speed = distanceToGoDown / timeForMoveInSec
    WMove(center, z_axis, -1 * distanceToGoDown, speed)
    Spring.DestroyUnit(unitID, true, false)
end
