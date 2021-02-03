include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

GameConfig = getGameConfig()

center = piece "center"
Line001 = piece "Line001"
Icon = piece "Icon"
function script.Create()
	Hide(Line001)
	Spin(center,y_axis,math.rad(1),0.5)
	 if Icon then  Move(Icon,y_axis, GameConfig.SatelliteIconDistance, 0);	Hide(Icon) end
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	StartThread(delayedShow)
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
	shatterUnit(unitID, Icon, UnitScript)
    return 1
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