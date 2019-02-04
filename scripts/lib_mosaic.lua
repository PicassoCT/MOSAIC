--===================================================================================================================
-- Game Configuration


function getGameConfig()
	return {
	Version = 0.1,
	
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
	 
	 agentConfig={
		recruitmentRange= 60,
	 },
	 
	 --civilianbehaviour
	 civilianInterestRadius = 750,
	 groupChatDistance = 150,
	 inHundredChanceOfInterestInDisaster = 75,
	 mainStreetModulo	= 4,
	 maxIterationSteps = 2048,
	 
	 --safehouseConfig
	 buildSafeHouseRange = 66,
	 safeHousePieceName = "center",
	 delayTillSafeHouseEstablished= 15000,
	 
	 --doubleAgentHeight
	 doubleAgentHeight = 256,
	 
	 --Dayproperties
	 daylength = 28800,
	 
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
function  getSafeHouseUpgradeTypeTable(UnitDefs, myDefID)
	UnitDefNames = getUnitDefNames(UnitDefs)
	typeTable={}
	if myDefID == UnitDefNames["antagonsafehouse"].id then
		typeTable={
		"nimrod",
		"noone",
		"propagandaserver",
		"assembly",
		"launcher"
		}
	else
	typeTable={
		"nimrod",
		"noone",
		"propagandaserver",
		"assembly"
		}
	end
	
	return getTypeTable(UnitDefNames, typeTable)
end

function  getSafeHouseUpgradeTypeTable(UnitDefs)

	UnitDefNames = getUnitDefNames(UnitDefs)
	typeTable={
		"nimrod",
		"assembly",
		"noone",
		"propagandaserver",
		"launcher"
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
		[UnitDefNames["comsatellite"].id] = 1400,
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


ProtagonUnitTypeList = getUnitCanBuildList(UnitDefNames["protagonsafehouse"].id)
AntagonUnitTypeList = getUnitCanBuildList(UnitDefNames["antagonsafehouse"].id)

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
		if boolDoneFor and boolDoneFor == true then
			return nil 
		end
		
		return nextFrame, persPack
	end
	
	GG.EventStream:CreateEvent(eventFunction, persPack, Spring.GetGameFrame() + 1)
end

function attachDoubleAgentToUnit(id, teamToTurnTo)
gameConfig = getGameConfig()

doubleAgentID = createUnitAtUnit(teamToTurnTo, "doubleagent", id, 0, gameConfig.doubleAgentHeight , 0)

Spring.MoveCtrl.Enable(doubleAgentID, true)
--set invisible

--set non-collidable

hoverAboveFunc = function( persPack)
					boolContinue = false
					boolEndFunction= true
					
					if doesUnitExistAlive(persPack.toTrackID)== false then 
						Spring.DestroyUnit(persPack.unitID,true,true)
						return boolEndFunction, nil
					end					
						
					x,y,z= Spring.GetUnitPosition(persPack.toTrackID)
							
					if doesUnitExistAlive(persPack.unitID)== false then 
						persPack.unitID =createUnitAtUnit(persPack.myTeam, "doubleagent", persPack.toTrackID, x, y + persPack.heightAbove , z)
						Spring.MoveCtrl.Enable(persPack.unitID)
						
						return boolContinue, persPack
					end					
					
					Spring.MoveCtrl.SetPosition(persPack.unitID, x,y + persPack.heightAbove,z)	
					boolUnitIsActive =	Spring.GetUnitIsActive (persPack.unitID)
					
					if boolUnitIsActive and boolUnitIsActive == false then
						Spring.TransferUnit(persPack.toTrackID, persPack.myTeam)
						Spring.Destroy(persPack.unitID,true,true)
						return boolEndFunction, nil
					end
				

					return boolContinue, persPack
				end

createStreamEvent(doubleAgentID, hoverAboveFunc, 1, {
													myTeam = teamToTurnTo, 
													toTrackID = id, 
													heightAbove = gameConfig.doubleAgentHeight,
													}
													)

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

--EventStream Function
function syncDecoyToAgent(evtID, frame, persPack, startFrame)
				--	only apply if Unit is still alive
				if doesUnitExistAlive(persPack.myID) == false  then
					return nil, persPack
				end
				
				if doesUnitExistAlive(persPack.syncedID) == false  then
					return nil, persPack
				end
				
				--sync Health
				transferUnitStatusToUnit(persPack.myID, persPack.syncedID)
				
				x,y,z = Spring.GetUnitPosition(persPack.syncedID)
				mx,my,mz = Spring.GetUnitPosition(persPack.myID)
				if not x then 
					return nil, persPack 
				end
				
				if not persPack.oldSyncedPos then persPack.oldSyncedPos ={x=x,y=y,z=z} end
				-- Test Synced Unit Stopped
				
				if distance ( persPack.oldSyncedPos.x, persPack.oldSyncedPos.y,persPack.oldSyncedPos.z, x,y, z) < 5 then
					-- Unit has stopped, test wether we are near it
					if distance(mx,my,mz,x, y, z) < 25 then
						Command(persPack.myID, "stop")
						return frame + 30, persPack 
					end
				end
				--update old Pos
				persPack.oldSyncedPos ={x=x,y=y,z=z}
				
				
				if not persPack.currPos then
					persPack.currPos ={x=mx,y=my,z=mz}
					persPack.stuckCounter=0
				end
				
				if distance(mx,my,mz, persPack.currPos.x,persPack.currPos.y,persPack.currPos.z) < 50 then				
					persPack.stuckCounter=persPack.stuckCounter+1
				else
					persPack.currPos={x=mx, y=my, z=mz}
					persPack.stuckCounter=0
				end
						
				if persPack.stuckCounter > 5 then
					moveUnitToUnit(persPack.myID, persPack.syncedID, math.random(-10,10),0, math.random(-10,10))
				end

				transferOrders( persPack.syncedID, persPack.myID)
				
				return frame + 30 , persPack	
			end
			
function initalizeInheritanceManagement()
--GG.InheritanceTable = [teamid] ={ [parent] = {[child] = true}}}
	if not GG.InheritanceTable then  
	GG.InheritanceTable ={} 
		for _,teams in pairs(Spring.GetTeamList()) do
				GG.InheritanceTable[teams] ={}
		end
	end
end

function registerChild( teamID, parent, childID)
if not GG.InheritanceTable[teamID][parent] then GG.InheritanceTable[teamID][parent] ={} end

	GG.InheritanceTable[teamID][parent][childID]= true
end

function getChildrenOfUnit(teamID, unit)
return GG.InheritanceTable[teamID][unit] or {}
end

function getParentOfUnit(teamID, unit)
	for parent, unitTable in pairs( GG.InheritanceTable[teamID]) do
		if unitTable then
			for thisUnit,_ in pairs(unitTable) do
				if unit == thisUnit then return parent end
			end
		end
	end
end

function removeUnit(teamID, unit)
	parent= getParentOfUnit(teamID, unit)
	if parent then  GG.InheritanceTable[teamID][parent][unit] = nil end
	if GG.InheritanceTable[teamID][unit] then GG.InheritanceTable[teamID][unit] = nil end
end