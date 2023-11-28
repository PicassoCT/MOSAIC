include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"


TablesOfPiecesGroups = {}
myDefID = Spring.GetUnitDefID(unitID)
storePassengerID = nil
attachPoint = piece("attachPoint")
Icon = piece("Icon")

function script.HitByWeapon(x, z, weaponDefID, damage) 
	if storePassengerID then
		Spring.AddDamage(storePassengerID
		Spring.UnitDetach(storePassengerID)
		Spring.DestroyUnit(storePassengerID, true, false)
	end
end


function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    Hide(attachPoint)
	StartThread(threadStarter)
end

function threadStarter()
	while true do
		while storePassengerID do
			if doesUnitExistAlive(storePassengerID) then
				
				
			end
		Sleep(100)
		end
	Sleep(1000)
	end

end


function script.Killed(recentDamage, _)
    return 1
end

function script.TransportPickup(passengerID)
    if passengerID then
       Spring.UnitAttach(unitID, passengerID, attachPoint)
	   storePassengerID = passengerID
    end
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

function script.TransportDrop(passengerID, x, y, z)
        Spring.UnitDetach(passengerID)
		storePassengerID = nil
end