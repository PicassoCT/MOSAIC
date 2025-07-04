include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

local TablesOfPiecesGroups = {}
boolBuilding = false

function script.HitByWeapon(x, z, weaponDefID, damage) end
SIG_BLINK = 2
SIG_BUILD = 4

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(blinkLights)
    StartThread(ammoCrate)
    Hide(buildspot)
end
BLINK_PASSIVE = 2000
BLINK_ACTIVE = 1250
blinkTime= 2000

function blinkLights()
    Signal(SIG_BLINK)
    SetSignalMask(SIG_BLINK)
    while true do
        if boolBuilding == true then
            showT(TablesOfPiecesGroups["lightsOn"])
            hideT(TablesOfPiecesGroups["lightsOff"])
            Sleep(blinkTime)
            hideT(TablesOfPiecesGroups["lightsOn"])
            showT(TablesOfPiecesGroups["lightsOff"])
        end
        Sleep(blinkTime)
    end
end

function ammoCrate()
    Signal(SIG_BUILD)
    SetSignalMask(SIG_BUILD)
    while true do
        if boolBuilding == true then
            WMove(Ammobox, y_axis, 100, 15)
            WTurn(Crane, z_axis, math.rad(80), 5)
            Hide(Ammobox)
            Sleep(500)
            WTurn(Crane, z_axis, math.rad(0), 5)
            Move(Ammobox, y_axis,0, 0)
            Sleep(5000)
            Show(Ammobox)
        end
        Sleep(1000)
    end
end

function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end

buildspot = piece("BuildSpot")
Crane = piece("Crane")
Ammobox = piece("Ammobox")
function script.QueryBuildInfo() return buildspot end

Spring.SetUnitNanoPieces(unitID, {Crane})

function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

function script.StartBuilding() 
    blinkTime = BLINK_ACTIVE; 
    boolBuilding = true; 
    SetUnitValue(COB.INBUILDSTANCE, 1) end

function script.StopBuilding() blinkTime = BLINK_PASSIVE; boolBuilding = false; SetUnitValue(COB.INBUILDSTANCE, 0) end


