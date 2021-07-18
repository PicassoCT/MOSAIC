include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

GameConfig = getGameConfig()
center = piece "center"
Icon = piece "Icon"
Packed = piece "Packed"
GodRod = piece "GodRod"
NumberOfRods = 3
function script.Create()

    --Spin(center,y_axis,math.rad(5),0.5)
    if Icon then
        Move(Icon, y_axis, GameConfig.SatelliteIconDistance, 0);
        Hide(Icon)
    end
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(delayedShow)
    Hide(GodRod)
end

function delayedShow()
    hideAll(unitID)
    Show(Packed)
    waitTillComplete(unitID)
    Explode(Packed, SFX.SHATTER)
    showAll(unitID)
    Hide(Packed)
    Hide(GodRod)
end

function script.Killed(recentDamage, _)
    shatterUnit(unitID, Icon, UnitScript)
    return 1
end

function script.AimFromWeapon1() return center end

function script.QueryWeapon1() return GodRod end

function script.AimWeapon1(Heading, pitch)
    boolCanAim = (NumberOfRods > 0)
   -- Spring.Echo("AimWeapon1 Sat GodRod".. toString(boolCanAim))

    return boolCanAim
end

function script.FireWeapon1()
    Hide(TablesOfPiecesGroups["GodRod"][NumberOfRods])
    NumberOfRods = NumberOfRods - 1

    if NumberOfRods == 0 then
        Explode(center, SFX.SHATTER + SFX.FALL + SFX.FIRE)
        Spring.DestroyUnit(unitID, true, false)
    end
end

function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

boolParked= false
boolLocalCloaked = false
function showHideIcon(boolCloaked)
    boolLocalCloaked = boolCloaked
    if boolCloaked == true then

        hideAll(unitID)
        Show(Icon)
        boolParked = true
    else
        showAll(unitID)
        Hide(Icon)
        Hide(Packed)
        Hide(GodRod)
        boolParked = false
    end
end
