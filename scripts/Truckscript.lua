include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}

LoadOutTypes = getTruckLoadOutTypeTable()


center = piece "center"
attachPoint = piece "attachPoint"
myDefID = Spring.GetUnitDefID(unitID)
boolIsCivilianTruck = (myDefID == UnitDefNames["truck"].id)
local loadOutUnitID 

function showAndTell()
	showAll(unitID)
	teamID =Spring.GetUnitTeam(unitID)
	teamID,_,_,_,sidename =Spring.GetTeamInfo(teamID)
	if not sidename or sidename == "protagon" then
		hideT(TablesOfPiecesGroups["BodyB"])
	else
		hideT(TablesOfPiecesGroups["Body"])
	end

end

function script.Create()

	if boolIsCivilianTruck == false then
		StartThread(loadLoadOutLoop)
	end

    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	showAndTell()
end

function loadLoadOutLoop()
	Sleep(100)
	myLoadOutType =  LoadOutTypes[myDefID]
	while true do			
	Sleep(100)
	
		if doesUnitExistAlive(loadOutUnitID) == false then
			myTeam = Spring.GetUnitTeam(unitID)

			loadOutUnitID= createUnitAtUnit( myTeam, myLoadOutType, unitID, 0, 10, 0)
			Spring.SetUnitNoSelect(loadOutUnitID, true)
			Spring.UnitAttach(unitID, loadOutUnitID, attachPoint)
		else
			transferOrders(unitID, loadOutUnitID)
		end

	end

end
function script.HitByWeapon(x, z, weaponDefID, damage)
end
function script.Killed(recentDamage, _)
	if doesUnitExistAlive(loadOutUnitID) then Spring.DestroyUnit(loadOutUnitID,true,true) end

    createCorpseCUnitGeneric(recentDamage)
    return 1
end

function script.TransportPickup ( passengerID ) 
	if boolIsCivilianTruck then
		if count(Spring.GetUnitIsTransporting(passengerID)) ~= 0 then return end 
		Spring.UnitAttach(unitID, passengerID, attachPoint)
	else
		Spring.UnitAttach(unitID, passengerID, attachPoint)
	end
end

function script.TransportDrop ( passengerID, x, y, z ) 
	if boolIsCivilianTruck == true then
		Spring.UnitDetach(passengerID)
	else
		if passengerID ~= loadOutUnitID then
			Spring.UnitDetach(passengerID)	
		end
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

function script.QueryBuildInfo()
    return center
end

Spring.SetUnitNanoPieces(unitID, { center })

