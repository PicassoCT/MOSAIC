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

function getMeatName(id)
	meats = {"Seitan", "Cow", "Chicken", "Pig", "Soylentils", "Tofu", "Mystery", "Recycled", "Gutter", "Farmer Tod" }
	return meats[(id % #meats) +1]
end

function getStreetName(id)
	if GG.UsedStreetNameCounterDict then
		streetNumber = count(GG.UsedStreetNameCounterDict)
		key, value = getNthElementT(GG.UsedStreetNameCounterDict, (id % streetNumber) +1)
		return key
	end
	return "Mainstreet"	
end

function getShippingContainerCompany(id)
	cont = {"Maersk", "Evergreen", "TransOrbital", "NewUsa", "Mr Lees LittleHongKong", "Luna", "Hanse", "Mistral", "Loyds", "MOSAIC"}
	return cont[(id % #cont) +1]
end

function getLiquid(id)
	cont = {"Hydrogen", "Ethanol", "Sulphuric Accid", "Fluorine", "Oil", "Water", "Hydrogenperoxide", "Yeast", "Gasoline"}
	return cont[(id % #cont) +1]
end

function getBales(id)
	cont = {"Cotton", "Flax", "Hemp", "Hey", "Textiles", "GunCotton"}
	return cont[(id % #cont) +1]
end

function getProduce(id)
	cont = {"Soybeans", "Algea", "Locusts", "Worms"}
	return cont[(id % #cont) +1]
end
function getBusName(id)
	busName = {"Matatu", "Taxi", "Bus", "Greyhound", "Oldsmobile", "Minibus"}
	return busName[(id % #busName) +1].. " to ".. getStreetName(id)
end

function getElPresidenteResidentePraise(unitID)
	Slogan = {"Long live ", "Viva la", "Everyone loves ", "President of the people ", "Vote for ", "Sees all ", "Knows all"}
	President = {}

end

function setPayLoadDescription(payLoadPieceId)
	pieceID_Content =	{}
	pieceID_Content[TablesOfPiecesGroups["container"] [1]]	=  getShippingContainerCompany(unitID).." Shipping Container"
	pieceID_Content[TablesOfPiecesGroups["container"] [2]]	= "Construction site spoil"
	pieceID_Content[TablesOfPiecesGroups["container"] [3]]	=  getShippingContainerCompany(unitID).." Shipping Container"
	pieceID_Content[TablesOfPiecesGroups["container"] [4]]	= "Construction material"
	pieceID_Content[TablesOfPiecesGroups["container"] [5]]	= "Cloned Fruit Limited"
	pieceID_Content[TablesOfPiecesGroups["container"] [6]]	= "Vatcloned Grains"
	pieceID_Content[TablesOfPiecesGroups["container"] [7]]	=  getMeatName(unitID) .. " Meat (certified fresh)"
	pieceID_Content[TablesOfPiecesGroups["container"] [8]]	= "Cereal"
	pieceID_Content[TablesOfPiecesGroups["container"] [9]]	= "IronOxide"
	pieceID_Content[TablesOfPiecesGroups["container"] [10]]	= "Synthwood Veneerplastics"
	pieceID_Content[TablesOfPiecesGroups["container"] [11]]	= "Gravell"
	pieceID_Content[TablesOfPiecesGroups["container"] [12]]	= "Debris & Rubble"
	pieceID_Content[TablesOfPiecesGroups["container"] [13]]	= "Rock & Rolls"
	pieceID_Content[TablesOfPiecesGroups["container"] [14]]	=  getProduce(unitID)
	pieceID_Content[TablesOfPiecesGroups["container"] [15]]	= "medical gasses"
	pieceID_Content[TablesOfPiecesGroups["container"] [16]]	= "Concrete Mixer"
	pieceID_Content[TablesOfPiecesGroups["container"] [17]]	=  getLiquid(unitID) .." tanker"
	pieceID_Content[TablesOfPiecesGroups["container"] [18]]	=  "Bales of" .. getBales(unitID)
	pieceID_Content[TablesOfPiecesGroups["container"] [19]]	=  "Bales of" .. getBales(unitID)
	pieceID_Content[TablesOfPiecesGroups["container"] [20]]	=  "Bales of" .. getBales(unitID)
	pieceID_Content[TablesOfPiecesGroups["container"] [21]]	=  "Wood"
	pieceID_Content[TablesOfPiecesGroups["container"] [22]]	=  "Unknown Payload"
	pieceID_Content[TablesOfPiecesGroups["container"] [23]]	=  "Pipes"
	pieceID_Content[TablesOfPiecesGroups["container"] [24]]	=  "Superconduct cooled energy transport"
	pieceID_Content[TablesOfPiecesGroups["container"] [25]]	=  "Empty"
	pieceID_Content[TablesOfPiecesGroups["container"] [26]]	=  "Nada"
	pieceID_Content[TablesOfPiecesGroups["container"] [27]]	=  "Nil"
	pieceID_Content[TablesOfPiecesGroups["container"] [28]]	=  "Nihil"
	pieceID_Content[TablesOfPiecesGroups["container"] [29]]	=  "Nothing"
	pieceID_Content[TablesOfPiecesGroups["container"] [30]]	=  "Void"
	pieceID_Content[TablesOfPiecesGroups["container"] [31]]	=  "Firetruck"
	pieceID_Content[TablesOfPiecesGroups["container"] [32]]	=  "Emergency Transport"
	pieceID_Content[TablesOfPiecesGroups["container"] [33]]	=  getBusName(unitID).." to "..getStreetName(unitID)
	pieceID_Content[TablesOfPiecesGroups["container"] [34]]	=  getBusName(unitID).." to "..getStreetName(unitID)
	pieceID_Content[TablesOfPiecesGroups["container"] [35]]	=  getBusName(unitID).." to "..getStreetName(unitID)
	pieceID_Content[TablesOfPiecesGroups["container"] [36]]	=  getLiquid(unitID) .." tanker"
	pieceID_Content[TablesOfPiecesGroups["container"] [37]]	=  getLiquid(unitID) .." tanker"
	pieceID_Content[TablesOfPiecesGroups["container"] [38]]	=  getLiquid(unitID) .." tanker"
	pieceID_Content[TablesOfPiecesGroups["container"] [38]]	=  "Garbagetruck"
	pieceID_Content[TablesOfPiecesGroups["container"] [39]]	=  getBusName(unitID).." to "..getStreetName(unitID)
	pieceID_Content[TablesOfPiecesGroups["container"] [40]]	=  getBusName(unitID).." to "..getStreetName(unitID)
	pieceID_Content[TablesOfPiecesGroups["container"] [41]]	=  getBusName(unitID).." to "..getStreetName(unitID)
	pieceID_Content[TablesOfPiecesGroups["container"] [42]]	=  getElPresidenteResidentePraise(unitID)
	pieceID_Content[TablesOfPiecesGroups["container"] [43]]	=  getElPresidenteResidentePraise(unitID)
	pieceID_Content[TablesOfPiecesGroups["container"] [44]]	=  getElPresidenteResidentePraise(unitID)
	pieceID_Content[TablesOfPiecesGroups["container"] [45]]	=  getElPresidenteResidentePraise(unitID)
	pieceID_Content[TablesOfPiecesGroups["container"] [46]]	= "Decontamination"



	for i=1, #TablesOfPiecesGroups["container"] do
		if not pieceID_Content[TablesOfPiecesGroups["container"] [i]] then
			pieceID_Content[TablesOfPiecesGroups["container"] [i]] = "TODO_DefaultPayloadDescription"
		end
	end

	if not pieceID_Content[payLoadPieceId] then echo("No payload defined for :" ..toString(getPieceName(unitID, payLoadPieceId))); return "Error" end

	payLoad = pieceID_Content[payLoadPieceId]
	assert(payLoad, payLoadPieceId)
	illegalPayloads =
	{
		"Anti-Matter",
		"Amphetamines",
		"biotech",
		"Counterfeit clothing",
		"Explosives",
		"Heroin",
		"Opiates",
		"Khat",
		"Information",
		"Immigrants",
		"Illicit AI",
		"Homespun chips",
		"Neuralnetwork pearls",
		"BackUps",
		"Mercenaries",
		"Infiltration teams",
		"Sexworkers",
		"Open source software",
		"Neophytes",
		"Weapons",
		"Uranium",
		"Refugees"
	}
	assert(illegalPayloads[(unitID % #illegalPayloads) + 1] )
	if unitID % 3 == 0 then
		payLoad = payLoad .. " smuggling: ["..illegalPayloads[(unitID % #illegalPayloads) + 1] .." ]"
	end

	Spring.SetUnitTooltip(unitID, payLoad)
	return payLoad
end

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

    if unitDefID == UnitDefNames["truckpayloadrefugee"].id then
        showOnePiece(TablesOfPiecesGroups["RefugeePayload"])
        if randChance(10) then
        	StartThread(delayedAttachCivilianLoot)
    	end
        for i=1, #TablesOfPiecesGroups["RefugeeDeco"] do
            if maRa() == true then
                Show(TablesOfPiecesGroups["RefugeeDeco"][i] )
            end
        end
    else
      displayedPiece =  showOnePiece(TablesOfPiecesGroups["container"])
      description = setPayLoadDescription(displayedPiece)
	  StartThread(delayedSetParentDescription, description)
	  if (displayedPiece == fireTruck or displayedPiece == EMT) then StartThread(FireTruckEmergencyBehaviour) end
	  if displayedPiece == GarbageTruck then StartThread(GarbageTruckBehaviour) end
	  if busPieces[displayedPiece] then
	  	GG.BusesTable[unitID] = unitID
	  end
    end
end

function delayedSetParentDescription(description)
	Sleep(100)
	  transporterID = Spring.GetUnitTransporter(unitID)
      if transporterID then
      	oldToolTip = Spring.GetUnitTooltip ( transporterID ) 
      	Spring.SetUnitTooltip( transporterID, oldToolTip.." "..description)
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
