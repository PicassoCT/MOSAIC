include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"

GameConfig = getGameConfig()
TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end
fireTruck = piece("container031")
EMT = piece("container032")
GarbageTruck = piece("container39")
myDefID = Spring.GetUnitDefID(unitID)
myTeamID = Spring.GetUnitTeam(unitID)
gaiaTeamID = Spring.GetGaiaTeamID()

function attachPayload(payLoadID, id)
    if payLoadID then
       Spring.SetUnitAlwaysVisible(payLoadID,true)
       Spring.UnitAttach(id, payLoadID, TablesOfPiecesGroups["RefugeeDeco"][math.random(1,#TablesOfPiecesGroups["RefugeeDeco"])])
       return payLoadID
    end
end
boolIsFireTruckOrEMT = false
displayedPiece = center
busPieces = {}


function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    Spring.SetUnitNeutral(unitID,true)
    Spring.SetUnitBlocking(unitID,false)
    Spring.SetUnitAlwaysVisible(unitID,true)
    Spring.SetUnitNoSelect(unitID,true)

    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    busPieces[TablesOfPiecesGroups["container"][41]] = TablesOfPiecesGroups["container"][41]
    busPieces[TablesOfPiecesGroups["container"][42]] = TablesOfPiecesGroups["container"][42]
    busPieces[TablesOfPiecesGroups["container"][40]] = TablesOfPiecesGroups["container"][40]
    busPieces[TablesOfPiecesGroups["container"][35]] = TablesOfPiecesGroups["container"][35]
    busPieces[TablesOfPiecesGroups["container"][34]] = TablesOfPiecesGroups["container"][34]
    busPieces[TablesOfPiecesGroups["container"][33]] = TablesOfPiecesGroups["container"][33]
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
	  if (displayedPiece == fireTruck or displayedPiece == EMT) then StartThread(FireTruckEmergencyBehaviour) end
	  if displayedPiece == GarbageTruck then StartThread(GarbageTruckBehaviour) end
	  if busPieces[displayedPiece] then
	  	GG.BusesTable[unitID] = unitID
	  end
    end
end

function script.Killed(recentDamage, _)
    return 1
end

function getEmergency()
	if GG.EmergencyPositions then
		index = 0
		if #GG.EmergencyPositions == 1 then index = 1 end
		if #GG.EmergencyPositions > 1 then index = math.random(1,  #GG.EmergencyPositions) end
		if index > 0 then
			x, z = GG.EmergencyPositions[index].x,  GG.EmergencyPositions[index].z
			local copy = GG.EmergencyPositions
			GG.EmergencyPositions = table.remove(copy, index)
			return x, z
		end
	end
end

function GarbageTruckBehaviour()
	Sleep(50)
	garbageID = nil
	ox,_, oz = Spring.GetUnitPosition(unitID)
	while true do
		gx,gz = GetCurrentMoveGoal(unitID)
		if gx and  gx ~= ox and gz ~= oz then
			ox, oz = gx,gz
			if garbageID and doesUnitExistAlive(garbageID)then
				Spring.DestroyUnit(garbageID, false, true)
			end
			garbageID = Spring.CreateUnit("trashbin",gaiaTeamID ,gx, 0, gz, math.random(0,4))
		end
		Sleep(5000)
	end
end

local corpsePrideTable = {[FeatureDefNames["bodybag"].id] = true}
function FireTruckEmergencyBehaviour()
	Sleep(50)
	while true do
		intervallTime = GameConfig.emergencyLocationTimeMs 
		x, z = getEmergency()
		if x then
		 transporterID = Spring.GetUnitTransporter(unitID)
		 if transporterID then
			while doesUnitExistAlive(transporterID) and intervallTime > 0 do
				Command(transporterID, "go", transporterID, {x=x,y=0, z=z})
				Sleep(2500)
				intervallTime = intervallTime -2500
			end
			if displayedPiece == EMT then
				T= getFeaturesInCircleAroundUnit(unitID, 50)
				if T then
					foreach(T,
						function(id)
							if corpsePrideTable[Spring.GetFeatureDefID(id)] then
								Spring.DestroyFeature(id)
							end
						end
						)
				end
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
