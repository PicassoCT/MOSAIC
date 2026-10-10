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

function playCollapseSound()
    soundFilePath = "sounds/building/collapse/collapse"..math.random(1,4)..".ogg"
    Spring.PlaySoundFile(soundFilePath, 1.0)
end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    playCollapseSound()
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
    Sleep(10)
    -- City rubble has one clock, owned by the plot lifecycle. Never self-delete
    -- it or run an independent sink timer during combat/anarchy.
    if GG.CityRubble and GG.CityRubble[unitID] then
        while GG.CityRubble[unitID] do
            local plot = GG.CityRubble[unitID]
            local progress = math.min(1, plot.elapsed / GameConfig.city.rubble.decayFrames)
            Move(center, z_axis, -distanceToGoDown * progress, 0)
            Sleep(500)
        end
        return
    end
    -- Unmanaged decorative rubble keeps its finite lifetime.
    local duration = GameConfig.city.rubble.disappearanceTimeMs
    Move(center, z_axis, -distanceToGoDown, distanceToGoDown / (duration / 1000))
    Sleep(duration)
    Spring.DestroyUnit(unitID, true, false)
end
