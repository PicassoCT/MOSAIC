include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "center"
Turret = piece "Turret"
aimpiece = piece "aimpiece"

function script.Create()
    generatepiecesTableAndArrayCode(unitID)
	resetAll(unitID)
	Hide(aimpiece)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	StartThread(unfold)
end

function unfold()
	if isTransported(unitID)== false then
		Turn(Turret,x_axis,math.rad(90),0)
		Sleep(1000)
		
		Turn(TablesOfPiecesGroups["UpLeg"][1],y_axis,math.rad(-30),0)
		Turn(TablesOfPiecesGroups["UpLeg"][2],y_axis,math.rad(30),0)
		Turn(TablesOfPiecesGroups["UpLeg"][3],y_axis,math.rad(30),0)
		Turn(TablesOfPiecesGroups["UpLeg"][4],y_axis,math.rad(-30),0)


		WTurn(Turret,x_axis,math.rad(0),math.pi)
	end
end

function script.Killed(recentDamage, _)
		
    createCorpseCUnitGeneric(recentDamage)
    return 1
end


--- -aimining & fire weapon
function script.AimFromWeapon1()
    return Turret
end



function script.QueryWeapon1()
    return Turret
end

function script.AimWeapon1(Heading, pitch)
    --aiming animation: instantly turn the gun towards the enemy

	WTurn(Turret,y_axis, Heading, math.pi)

	
    return true
end


function script.FireWeapon1()

    return true
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

function script.QueryBuildInfo()
    return center
end

Spring.SetUnitNanoPieces(unitID, { center })

