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
    StartThread(hideHouse)
    Hide(buildspot)
end

function hideHouse()
    waitTillComplete(unitID)
    Sleep(100)
    myHouseID = getInternalModulesHouse(unitID)
    if myHouseID then return end
    env = Spring.UnitScript.GetScriptEnv(myHouseID)
    if env and env.hideHouse then
        Spring.UnitScript.CallAsUnit(myHouseID, env.hideHouse)
    end
end


BLINK_ACTIVE = 1250
blinkTime= 500
Race1 = piece("Race1")
Race2 = piece("Race002")
racerSize = 500
function blinkLights()
    Signal(SIG_BLINK)
    SetSignalMask(SIG_BLINK)
    k= 0
    n = 0
    while true do
            showT(TablesOfPiecesGroups["LightOn"], 1, 3)
            hideT(TablesOfPiecesGroups["LightOff"],1, 3)
            for i=4, # TablesOfPiecesGroups["LightOn"] do
                k = (k+1) % 13
                n = 13 + (n+1) % 13
                Move(Race1, x_axis, k * racerSize, 0)
                Move(Race2, x_axis, n * racerSize, 0)
                Hide(TablesOfPiecesGroups["LightOn"][i])
                Show(TablesOfPiecesGroups["LightOff"][i])
                Sleep(600)
            end

            hideT(TablesOfPiecesGroups["LightOn"],1,3)
            showT(TablesOfPiecesGroups["LightOff"],1,3)
            for i=4, # TablesOfPiecesGroups["LightOn"] do
                k = (k+1) % 13
                n = 13 + (n+1) % 13
                Move(Race1, x_axis, k * racerSize, 0)
                Move(Race2, x_axis, n * racerSize, 0)
                Show(TablesOfPiecesGroups["LightOn"][i])
                Hide(TablesOfPiecesGroups["LightOff"][i])
                Sleep(600)
            end
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


