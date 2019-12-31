include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end


center = piece "center"
Icon = piece "Icon"
	Packed = piece "Packed"
NumberOfRods = 3
function script.Create()
	
	-- Spin(center,y_axis,math.rad(1),0.5)
	if Icon then 	Hide(Icon) end
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	StartThread(delayedShow)
end

function delayedShow()
	
	hideAll(unitID)
	Show(Packed)
	waitTillComplete(unitID)
	Explode(Packed, SFX.SHATTER)
	showAll(unitID)
	Hide(Packed)

end


function script.Killed(recentDamage, _)
	explodeD(Spring.GetUnitPieceMap(unitID), SFX.SHATTER + SFX.FALL + SFX.FIRE + SFX.EXPLODE_ON_HIT)
    return 1
end

function script.AimFromWeapon1()
    return center
end

function script.QueryWeapon1()
    return center
end

function script.AimWeapon1(Heading, pitch)
    --aiming animation: instantly turn the gun towards the enemy
	-- WTurn(base, z_axis, Heading, math.pi)
	-- WTurn(aimpiece, x_axis, -pitch, math.pi)
    return NumberOfRods > 0
end

function script.FireWeapon1()
	Hide(TablesOfPiecesGroups["GodRod"][NumberOfRods])
	NumberOfRods = NumberOfRods -1

	if NumberOfRods == 0 then 
		Explode(center, SFX.SHATTER + SFX.FALL + SFX.FIRE)
		Spring.DestroyUnit(unitID,true, false)
	end
end

function script.StartMoving()
end

function script.StopMoving()
end

function script.Activate()
    return 1
end

function script.Deactivate()
    return 0
end

boolLocalCloaked = false
function showHideIcon(boolCloaked)
    boolLocalCloaked = boolCloaked
    if  boolCloaked == true then

        hideAll(unitID)
        Show(Icon)
    else
        showAll(unitID)
        Hide(Icon)
    end
end