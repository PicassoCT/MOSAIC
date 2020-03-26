include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}
SIG_DELAYEDSTOP = 1

function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "center"
gun = piece "gun"
EmitPiece = piece "EmitPiece"

function script.Create()
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	Hide(EmitPiece)
end

function script.Killed(recentDamage, _)

    --createCorpseCUnitGeneric(recentDamage)
    return 1
end


--- -aimining & fire weapon
function script.AimFromWeapon1()
    return gun
end



function script.QueryWeapon1()
    return gun
end

function script.AimWeapon1(Heading, pitch)
    --aiming animation: instantly turn the gun towards the enemy
	WTurn(center,z_axis, math.rad(180), 360)
	WTurn(center,y_axis, math.rad(0), 360)

    return true
end


function script.FireWeapon1()

    return true
end

boolAlreadyMoving=false
function startMovement()
if boolAlreadyMoving == true then return end
process(TablesOfPiecesGroups["uprotor"],
		function(id)
			Spin(id,y_axis,math.rad(9000),10)
		end
		)
process(TablesOfPiecesGroups["lowrotor"],
		function(id)
			Spin(id,y_axis,math.rad(-9000),10)
		end
		)
Sleep(500)
WTurn(center,z_axis, math.rad(180), 180)
WTurn(center,y_axis, math.rad(180), 360)
boolAlreadyMoving= true

end

function script.StartMoving()
Signal(SIG_DELAYEDSTOP)
StartThread(startMovement)
end

function delayedStop()
Signal(SIG_DELAYEDSTOP)
SetSignalMask(SIG_DELAYEDSTOP)
Sleep(50)
Turn(center,z_axis, math.rad(0), 90)
Turn(center,y_axis, math.rad(0), 90)
Sleep(1000)
process(TablesOfPiecesGroups["uprotor"],
		function(id)
			StopSpin(id,y_axis,1)
		end
		)
process(TablesOfPiecesGroups["lowrotor"],
		function(id)
			StopSpin(id,y_axis,1)
		end
		)


boolAlreadyMoving = false
end

function script.StopMoving()
StartThread(delayedStop)
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

