include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

local GameConfig = getGameConfig()
local TablesOfPiecesGroups = {}
local myDefID = Spring.GetUnitDefID(unitID)
local storePassengerID = nil
local attachPoint = piece("attachPoint")
local Icon = piece("Icon")
local gaiaTeamID = Spring.GetGaiaTeamID()
local houseTypeTable = getHouseTypeTable(Unitdefs)
local ux,uy,uz = Spring.GetUnitPosition(unitID)
function script.HitByWeapon(x, z, weaponDefID, damage) 
	if storePassengerID then
		Spring.AddDamage(storePassengerID)
		Spring.UnitDetach(storePassengerID)
		Spring.DestroyUnit(storePassengerID, true, false)
	end
end
blockSize = GameConfig.houseSizeX/6
halfBlockSize = blockSize/2
function inHouse(id)
    hx,hy,hz = Spring.GetUnitPosition(id)
    minXLimit, maxXLimit = ux - (2.5*blockSize) ,ux + (2.5*blockSize) 
    minZLimit, maxZLimit = uz - (2.5*blockSize) ,uz + (2.5*blockSize) 
    if hx > minXLimit - halfsize and hx < minXLimit + halfsize  and
       hz > minZLimit - halfsize and hz < minZLimit + halfsize  then

       if  hx < minXLimit + halfsize and hx > minXLimit - halfsize  and
            hz < minZLimit + halfsize and hz > minZLimit - halfsize  then
            return false
       end
       return true
    end
    return false
end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    Hide(attachPoint)
	StartThread(threadStarter)
end
function checkIsWithinBuilding()
    boolOnAtLeastOneRoof= false
    ux,uy,uz = Spring.GetUnitPosition(unitID)
	foreach( 
            getAllNearUnit(unitID, GameConfig.houseSizeX, gaiaTeamID),
            function(id)
                defID= Spring.GetUnitDefID(id)
                if houseTypeTable[defID]then 
                    if inHouse(id) then
                        boolOnAtLeastOneRoof = true
                    end
                    return id
                end
            end
            )
        if not boolOnAtLeastOneRoof then
		TransportDrop(storePassengerID)
        Spring.DestroyUnit(unitID, true, false)
        end
end
	
function handleCommandTransfer(passengerID)
  while doesUnitExistAlive(passengerID) == true do
        transferAttackOrder(unitID, passengerID)
        transferStates(unitID, passengerID)
        Sleep(100)
    end
end

function threadStarter()
	while true do
		if storePassengerID then
			StartThread(handleCommandTransfer, storePassengerID)
			while storePassengerID do
				if doesUnitExistAlive(storePassengerID) then	
					--set Move goal
					checkIsWithinBuilding()
				end
				Sleep(100)
			end
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
        Spring.SetUnitNoSelect(passengerID, true)
       Spring.UnitAttach(unitID, passengerID, attachPoint)
	   setEnvironmentFireAllowance(true)
	   storePassengerID = passengerID
    end
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

function script.TransportDrop(passengerID, x, y, z)
        Spring.SetUnitNoSelect(passengerID, false)
        Spring.UnitDetach(passengerID)
		setEnvironmentFireAllowance(false)
		storePassengerID = nil
end