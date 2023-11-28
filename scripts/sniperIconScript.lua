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
		Spring.AddDamage(storePassengerID)
		Spring.UnitDetach(storePassengerID)
		Spring.DestroyUnit(storePassengerID, true, false)
	end
end


function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	Spring.SetUnitNoSelect(unitID, true)
    Hide(attachPoint)
	StartThread(threadStarter)
end
function isWithinBuilding(personOnRoof, mx mz)
	

end


function threadStarter()
	while true do
		while storePassengerID do
			if doesUnitExistAlive(storePassengerID) then
				mx,mz = GetMoveGoal(storePassengerID)
				if mx then
					-- isWithinBuilding - move Icon
					if isWithinBuilding(storePassengerID, mx,mz) then
						Command("go", unitID, {mx, 0, mz})
					else
					-- is outside drop
						TransportDrop(storePassengerID)
					end
				end				
			end
		Sleep(100)
		end
	Sleep(1000)
	end

end


function script.Killed(recentDamage, _)
    return 1
end

function setEnvironmentFireAllowance(value)
	
    env = Spring.UnitScript.GetScriptEnv(storePassengerID)

    if env and env.setTransportedBySniperIcon then
       result= Spring.UnitScript.CallAsUnit(unitID, 
                                     env.setTransportedBySniperIcon,
                                     value
                                     ))
    end
end

function script.TransportPickup(passengerID)
    if passengerID then
       Spring.UnitAttach(unitID, passengerID, attachPoint)
	   setEnvironmentFireAllowance(true)
	   storePassengerID = passengerID
    end
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

function script.TransportDrop(passengerID, x, y, z)
        Spring.UnitDetach(passengerID)
		setEnvironmentFireAllowance(false)
		storePassengerID = nil
end