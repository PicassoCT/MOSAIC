include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"
include "lib_mosaic.lua"

center = piece "center"

GameConfig = getGameConfig()
distanceToGoDown = 90
TablesOfPiecesGroups = {}
function script.Killed()  end



function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    randHide(TablesOfPiecesGroups["scrapHeap"])
    randHide(TablesOfPiecesGroups["corn"])
    randHide(TablesOfPiecesGroups["girder"])
    randHide(TablesOfPiecesGroups["wall"])
    randHide(TablesOfPiecesGroups["winWall"])
    randHide(TablesOfPiecesGroups["winDebB"])
    randHide(TablesOfPiecesGroups["skyscrape"])
    Spring.SetUnitAlwaysVisible(unitID, true)
    StartThread(waitForAnEnd)
end

boolSleepOnHit = false
function script.HitByWeapon(x, z, weaponDefID, damage)
    return damage
end
excavatorcenter = piece("excavatorcenter")
Excavator = piece("Excavator")
ExArm = piece("ExArm")
ExArmLow = piece("ExArmLow")
Shovell = piece("Shovell")
Base = piece("Base")
ExcavatorTable = {Excavator, ExArm, excavatorcenter, ExArmLow, Shovell, Base}

function excavator()
    showT(ExcavatorTable)
    while true do
        direction = math.random(-90,10)
        WTurn(excavatorcenter, 2, math.rad(direction), 0.5)
        distance = math.random(0,150)
        WMove(Base,3, distance, 15)
        shovellings = math.random(5, 15)
        for i=1, shovellings do
            Turn(Excavator,2,math.rad(i*3), 2)        
            Turn(ExArm,1, math.rad(35), 2 )
            WTurn(ExArmLow,1, math.rad(58), 2 )
            
            Turn(Shovell, 1, math.rad(-30), 1)
            Turn(ExArm,1, math.rad(-51), 1 )
            WTurn(ExArmLow,1, math.rad(-35), 1)
            WaitForTurns(Shovell,ExArmLow,ExArmLow)
            
            Turn(Shovell, 1, math.rad(0), 1)
            WTurn(ExArm,1, math.rad(0), 1 )            
            WTurn(ExArmLow, 1, math.rad(0), 1)
        end
        Turn(Excavator,2,math.rad(0), 1) 
        WTurn(ExArm,1, math.rad(35), 1 )
        WTurn(ExArmLow,1, math.rad(58), 1 )
        WMove(Base,3, 0, 15)
        Sleep(1000)
    end
end

function waitForAnEnd()
    hideT(ExcavatorTable)   
    timeForMoveInSec = GameConfig.TimeForScrapHeapDisappearanceInMs/1000
    speed = distanceToGoDown / timeForMoveInSec
    Sleep(GameConfig.minutMS)
    StartThread(excavator)

    for i= 1, -1 * distanceToGoDown, -1 do
        WMove(center, z_axis, i, speed)
        while boolSleepOnHit == true or GG.GlobalGameState ~= GameConfig.GameState.normal do
            Sleep(GameConfig.minutMS)
            boolSleepOnHit = false
        end            
    end
    Spring.DestroyUnit(unitID, true, false)
end
