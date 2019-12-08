include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}
center = piece "center"
turret = piece "turret"
projectile = piece "projectile"
Icon = piece "Icon"
GameConfig = getGameConfig()



function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	
	T= process(getAllNearUnit(unitID, GameConfig.buildSafeHouseRange*2),
				function(id)
					if isUnitInGroup(id, "house", GameConfig.instance.culture, UnitDefs)== true then
						return id
					end
				end
				)
	StartThread(mortallyDependant, unitID, T[1], 15, false, true)
end

function script.HitByWeapon(x, z, weaponDefID, damage)
end

--- -aimining & fire weapon
function script.AimFromWeapon1()
    return projectile
end

function script.QueryWeapon1()
    return projectile
end

function script.AimWeapon1(Heading, pitch)
    --aiming animation: instantly turn the gun towards the enemy

        WTurn(center, y_axis, Heading, 0.4)
        WTurn(turret, x_axis, -pitch, 0.4)
		
    return true
end


function script.FireWeapon1()

    return true
end



function script.StartBuilding()
end

function script.StopBuilding()
end
function script.Activate()



    SetUnitValue(COB.YARD_OPEN, 1)

    SetUnitValue(COB.BUGGER_OFF, 1)

    SetUnitValue(COB.INBUILDSTANCE, 1)
    return 1
end



function script.Deactivate()

    SetUnitValue(COB.YARD_OPEN, 0)

    SetUnitValue(COB.BUGGER_OFF, 0)

    SetUnitValue(COB.INBUILDSTANCE, 0)

    return 0
end




function script.QueryBuildInfo()
    return projectile
end

Spring.SetUnitNanoPieces(unitID, { projectile })

function script.Killed(recentDamage, _)

    createCorpseCUnitGeneric(recentDamage)
    return 1
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