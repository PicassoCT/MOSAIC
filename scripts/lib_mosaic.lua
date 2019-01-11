--===================================================================================================================
-- Game Configuration


function getGameConfig()
	return {
	numberOfBuildings 	= 75,
    numberOfVehicles 	= 100,
    numberOfPersons		= 200,
	 houseSizeX			= 256, 
	 houseSizeY			= 16, 
	 houseSizeZ			= 256,
	 xRandOffset		= 20,
	 zRandOffset		= 20,
	 allyWaySizeX 		= 25,
	 allyWaySizeZ		= 25,
	 --civilianbehaviour
	 civilianInterestRadius = 750,
	 groupChatDistance = 150,
	 inHundredChanceOfInterestInDisaster = 75,
	 mainStreetModulo	= 4,
	 maxIterationSteps = 2048
	 
	}
end

--===================================================================================================================
--Mosaic specific functions 
--> creates a table from names to check unittypes against
function getUnitDefNames(UnitDefs)
	local UnitDefNames = {}
	assert(UnitDefs)
	for defID,v in pairs(UnitDefs) do
		UnitDefNames[v.name]=v
	end
	return UnitDefNames
end


function getTypeTable(UnitDefNames, StringTable)
	local Stringtable = StringTable
	retVal = {}
	for i = 1, #Stringtable do
		if not UnitDefNames[Stringtable[i]] then Spring.Echo("Error: Unitdef of Unittype " .. Stringtable[i] .. " does not exists") 
		else
		retVal[UnitDefNames[Stringtable[i]].id] = true
		end
	end
	return retVal
end

function getWeaponTypeTable(WeaponDefNames, StringTable)
	local Stringtable = StringTable
	retVal = {}
	for i = 1, #Stringtable do
		assert(WeaponDefNames[Stringtable[i]], "Error: Weapondef of Weapontype " .. Stringtable[i] .. " does not exists")
		retVal[WeaponDefNames[Stringtable[i]].id] = true
	end
	return retVal
end

function getSatteliteTypes(UnitDefs)
	assert(UnitDefs)
	UnitDefNames = getUnitDefNames(UnitDefs)
	typeTable={
		"comsatellite",
		"scansatellite"
	}
	return getTypeTable(UnitDefNames, typeTable)
end

function  getMobileCivilianDefIDTypeTable(UnitDefs)
	assert(UnitDefs)
	UnitDefNames = getUnitDefNames(UnitDefs)
	typeTable={
		"civilian",
		"truck"
	}
	
	return getTypeTable(UnitDefNames, typeTable)
end

function getCivilianTypeTable(UnitDefs)
	assert(UnitDefs)
	UnitDefNames = getUnitDefNames(UnitDefs)
	typeTable={
		"house",
		"civilian",
		"truck"
	}
	
	local retTable = {}
	for _,defs in pairs(UnitDefs) do
		for num,k in pairs(typeTable) do
			
				if defs.name == k then			
					retTable[k] = defs.id
				end
			
		end
	end
	
	return retTable, getTypeTable(UnitDefNames, typeTable)
end

framesPerSecond = 30

function getSatelliteTimeOutTable(UnitDefs) --per Frame
UnitDefNames = getUnitDefNames(UnitDefs)

	valuetable={
		[UnitDefNames["comsatellite"].id] = 3*90 * framesPerSecond,
		[UnitDefNames["scansatellite"].id] = 90 * framesPerSecond
	}
	
	return valuetable
end

function getSatelliteTypesSpeedTable(UnitDefs) --per Frame
UnitDefNames = getUnitDefNames(UnitDefs)

	valuetable={
		[UnitDefNames["comsatellite"].id] = 30/framesPerSecond,
		[UnitDefNames["scansatellite"].id] = 90/framesPerSecond
	}
	
	return valuetable
end
function getSatelliteAltitudeTable(UnitDefs) --per Frame
UnitDefNames = getUnitDefNames(UnitDefs)

	valuetable={
		[UnitDefNames["comsatellite"].id] = 1500,
		[UnitDefNames["scansatellite"].id] = 1500
	}
	
	return valuetable
end


function getCategoryNameWeaponTypes()
	typeTable= {
	
	}
	
	return getWeaponTypeTable(WeaponDefNames, typeTable)
end

function unitCanBuild(unitDefID)
	
	if unitDefID and UnitDefs[unitDefID] then		
		return UnitDefs[unitDefID].buildOptions 	
	end
	return {}
end

function getUnitDefIDFromName(name)
	for i=1,#UnitDefs do
		if name == UnitDefs[i].name then return UnitDefs[i].id end
	end
	
end

--computates a map of all unittypes buildable by a unit (detects loops)
--> getUnitBuildAbleMap
function getUnitCanBuildList(unitDefID, closedTableExtern, root)
	if not unitDefID then return {} end
	if not root then root = true end
	Result = {}
	assert(type(unitDefID)=="number")
	boolCanBuildSomething= false
	
	local openTable = unitCanBuild(unitDefID) or {}
	if lib_boolDebug == true then	
		assert(UnitDefs)
		assert(unitDefID)
		assert(UnitDefs[unitDefID],unitDefID)
		assert(UnitDefs[unitDefID].name)		
	end
	closedTable = closedTableExtern or {}
	local CanBuildList = unitCanBuild(unitDefID)
	closedTable[unitDefID] = true 
	assert(CanBuildList)
	for num, unitName in pairs(CanBuildList) do		
		defID = getUnitDefIDFromName(unitName)
		boolCanBuildSomething = true
		
		if defID and not closedTable[defID] then
			Result[defID] =defID	
			
			unitsToIntegrate, closedTable = getUnitCanBuildList(defID, closedTable, false)
			if unitsToIntegrate then
				for id,_ in pairs(unitsToIntegrate) do
					
					if lib_boolDebug == true then	
						Spring.Echo("+ "..UnitDefs[id].name)
					end
					
					Result[id] = id
				end
			end
		end
	end
	if boolCanBuildSometing == true then
		if root == true then
			Spring.Echo("Unit "..UnitDefs[unitDefID].name.." can built:")
		end
	end
	
	return Result,closedTable
end


ProtagonUnitTypeList = getUnitCanBuildList(UnitDefNames["safehouse"].id)
AntagonUnitTypeList = getUnitCanBuildList(UnitDefNames["safehouse"].id)

function getUnitSide(unitID)
	defID= Spring.GetUnitDefID(unitID)
	if ProtagonUnitTypeList[defID] then return "protagon"end
	if AntagonUnitTypeList[defID] then return "antagon"end
	return "gaia"
end




function getDayTime()
	DAYLENGTH = 28800
	Frame = (Spring.GetGameFrame() + (DAYLENGTH / 2)) % DAYLENGTH
	
	hours = math.floor((Frame / DAYLENGTH) * 24)
	minutes = math.ceil((((Frame / DAYLENGTH) * 24) - hours) * 60)
	seconds = 60 - ((24 * 60 * 60 - (hours * 60 * 60) - (minutes * 60)) % 60)
	return hours, minutes, seconds
end

--> Creates a Eventstream Event bound to a Unit
function createStreamEvent(unitID, func, framerate, persPack)
	persPack.unitID = unitID
	persPack.startFrame = Spring.GetGameFrame()
	persPack.functionToCall = func
	
	eventFunction = function(id, frame, persPack)
		nextFrame = frame + framerate
		if persPack then
			if persPack.unitID then
				--check
				boolDead = Spring.GetUnitIsDead(persPack.unitID)
				
				if boolDead and boolDead == true then
					return nil, nil
				end
				
				if not persPack.startFrame then
					persPack.startFrame = frame
				end
				
				if persPack.startFrame then
					nextFrame = persPack.startFrame + framerate
					persPack.startFrame = nil
				end 
			end
		end
		
		boolDoneFor, persPack = persPack.functionToCall(persPack)
		if boolDoneFor then
			return nil 
		end
		
		return nextFrame, persPack
	end
	
	GG.EventStream:CreateEvent(eventFunction, persPack, Spring.GetGameFrame() + 1)
end


function createRewardEvent(teamid, returnOfInvestmentM, returnOfInvestmentE)
	
	returnOfInvestmentM = returnOfInvestmentM or 100
	returnOfInvestmentE = returnOfInvestmentE or 100
	
	
	rewarderProcess = function (evtID, frame, persPack, startFrame)
		
		
		Spring.AddTeamResource(	persPack.teamId, 
		"metal", 
		persPack.returnOfInvestmentM/persPack.rewardCycles)
		Spring.AddTeamResource(persPack.teamId, 
		"energy", 
		persPack.returnOfInvestmentE/persPack.rewardCycles)
		
		persPack.rewardCycleIndex= persPack.rewardCycleIndex +1
		if persPack.rewardCycleIndex > persPack.rewardCycles then 
			return nil, nil
		end	
		
		return frame + 1000, persPack
	end
	
	persPack = { 
		teamId= teamid,
		returnOfInvestmentM= returnOfInvestmentM,
		returnOfInvestmentE= returnOfInvestmentE,
		id = unitID,
		rewardCycles= 25, 
		rewardCycleIndex= 0 
	}
	
	GG.EventStream:CreateEvent(
	rewarderProcess,
	persPack,
	Spring.GetGameFrame() + 1)
	
end
