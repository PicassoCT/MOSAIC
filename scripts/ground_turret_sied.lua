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
SIG_GUARDMODE = 1

function script.Create()
    generatepiecesTableAndArrayCode(unitID)
	resetAll(unitID)
	Hide(aimpiece)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	StartThread(orderTransfer)
end

boolAiming = false

function orderTransfer()
	while true do
		while isTransported(unitID)== true do
			transporterID = Spring.GetUnitTransporter(unitID)
			if transporterID then
				Spring.SetUnitNoSelect(transporterID, true)
				transferOrders(unitID, transporterID)
			end
			Sleep(100)
		end
		Spring.SetUnitNoSelect(transporterID, false)
		Sleep(100)
	end
end



function script.Killed(recentDamage, _)
		
    --createCorpseCUnitGeneric(recentDamage)
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

    return true
end



function script.FireWeapon1()
	StartThread(guardSwivelTurret)
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



