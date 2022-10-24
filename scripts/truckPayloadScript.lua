include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"

GameConfig = getGameConfig()
TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

myDefID = Spring.GetUnitDefID(unitID)
myTeamID = Spring.GetUnitTeam(unitID)

function attachPayload(payLoadID, id)
    if payLoadID then
       Spring.SetUnitAlwaysVisible(payLoadID,true)
       Spring.UnitAttach(id, payLoadID, TablesOfPiecesGroups["RefugeeDeco"][math.random(1,#TablesOfPiecesGroups["RefugeeDeco"])])
       return payLoadID
    end
end
boolIsFireTruckOrEMT = false
displayedPiece = center
function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    Spring.SetUnitNeutral(unitID,true)
    Spring.SetUnitBlocking(unitID,false)
    Spring.SetUnitAlwaysVisible(unitID,true)
    Spring.SetUnitNoSelect(unitID,true)

    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideAll(unitID)

    if myDefID == UnitDefNames["truckpayloadrefugee"].id then
        showOnePiece(TablesOfPiecesGroups["RefugeePayload"])
        StartThread(delayedAttachCivilianLoot)

        for i=1, #TablesOfPiecesGroups["RefugeeDeco"] do
            if maRa() == true then
                Show(TablesOfPiecesGroups["RefugeeDeco"][i] )
            end
        end
    else
      displayedPiece =  showOnePiece(TablesOfPiecesGroups["container"])
	  boolIsFireTruckOrEMT = (displayedPiece == fireTruck or displayedPiece == EMT)
	  if boolIsFireTruckOrEMT then
		StartThread(fireTruckEmergencyBehaviour)
	  end
    end
end

function script.Killed(recentDamage, _)
    return 1
end

function getEmergency()
	if GG.EmergencyPositions then
		index = 0
		if #GG.EmergencyPositions == 1 then index = 1
		if #GG.EmergencyPositions > 1 then index = math.random(1,  #GG.EmergencyPositions)
		if index > 0 then
			x, z = GG.EmergencyPositions[index].x,  GG.EmergencyPositions[index].z
			local copy = GG.EmergencyPositions
			GG.EmergencyPositions = table.remove(copy, index)
			return x, z
		end
	end
end

function fireTruckEmergencyBehaviour()
	Sleep(50)
	while true do
		intervallTime = GameConfig.emergencyLocationTimeMs 
		x, z = getEmergency()
		if x then
		 transporterID = Spring.GetUnitTransporter(unitID)
		 if transporterID then
			while doesUnitExistAlive(transporterID) and intervallTime > 0 do
				Command("go", transporterID {x=x,y=0, z=z})
				Sleep(2500)
				intervallTime = intervallTime -2500
			end
		 end
		end
		Sleep(5000)
	end
end

function delayedAttachCivilianLoot()
    Sleep(500)
    --Spring.Echo("createUnitAtUnit ".."truckPayloadScript.lua") 
    civilianLootID = createUnitAtUnit(myTeamID, "civilianloot", unitID)
    attachPayload(civilianLootID, unitID)
end
