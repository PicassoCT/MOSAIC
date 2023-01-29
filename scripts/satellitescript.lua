include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

GameConfig = getGameConfig()

center = piece "center"

Icon = piece "Icon"
function script.Create()

    Spin(center, y_axis, math.rad(1), 0.5)
    if Icon then
        Move(Icon, y_axis, GameConfig.Satellite.iconDistance, 0);
        Hide(Icon)
    end
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    Spin(center,y_axis, math.rad(4),0)
    StartThread(delayedShow)
    StartThread(threeBeepLoop)
end

function delayedShow()
    Packed = piece "Packed"
    hideAll(unitID)
    Show(Packed)
    waitTillComplete(unitID)
    Explode(Packed, SFX.SHATTER)
    showAll(unitID)
    Hide(Packed)
end

function script.Killed(recentDamage, _)
    return 1
end

function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

function threeBeepLoop()
    while true do
        Sleep(1000)
        if boolBeep then
            if boolParked == false then
            for i=1,3 do 
                Spring.PlaySoundFile("sounds/satellite/beep.wav", 1.0/i)
                Sleep(1000)
            end
            else
            for i=3,1,-1 do 
                Spring.PlaySoundFile("sounds/satellite/beep.wav", 1.0/i)
                Sleep(1000)
            end
            end
        boolBeep = false
        end
    end
end

boolParked = false
boolLocalCloaked = false
function showHideIcon(boolCloaked)
    boolLocalCloaked = boolCloaked
    if boolCloaked == true then

        hideAll(unitID)
        boolParked = true
        Show(Icon)
        boolBeep = true
    else
        showAll(unitID)
        Hide(Icon)
        boolParked = false
        boolBeep = true
    end
end
