include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "center001"
Turret = piece "Turret"
aimpiece = Turret
SIG_GUARDMODE = 1

function script.Create()
	resetAll(unitID)
	Hide(aimpiece)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	StartThread(orderTransfer)
end

boolAiming = false
local transporterID 
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
		if transporterID then
			Spring.SetUnitNoSelect(transporterID, false)
		end
		Sleep(100)
	end
end



function script.Killed(recentDamage, _)
	if transporterID and doesUnitExistAlive(transporterID)== true then
		Spring.DestroyUnit(transporterID, false, true)
	end
    --createCorpseCUnitGeneric(recentDamage)
    return 1
end

--- -aimining & fire weapon
function script.AimFromWeapon1()
    return Turret
end

function script.QueryWeapon1()
    return center
end

function script.AimWeapon1(Heading, pitch)
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