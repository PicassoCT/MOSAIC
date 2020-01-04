--===================================================================================================================
-- Game Configuration

unitFactor= 0.5


function getGameConfig()
	return {
	instance = {
	culture = "arabic", -- "international", "europe", "china", "russia", "northamerica", "southamerica"
	
	},
	
	Version = "Alpha: 0.660",
	
	numberOfBuildings 	= 75 *unitFactor,
    numberOfVehicles 	= 100 *unitFactor,
    numberOfPersons		= 150 *unitFactor,

	 houseSizeX			= 256, 
	 houseSizeY			= 16, 
	 houseSizeZ			= 256,
	 xRandOffset		= 20,
	 zRandOffset		= 20,
	 allyWaySizeX 		= 25,
	 allyWaySizeZ		= 25,
	 
	 agentConfig={
		recruitmentRange= 60,
		raidWeaponDownTimeInSeconds =  60,
		raidComRange= 1200,
		raidBonusFactorSatellite = 2.5,
	 },
	 
	 --civilianbehaviour
	 civilianPanicRadius = 350,
	 civilianInterestRadius = 150,
	 groupChatDistance = 150,
	 inHundredChanceOfInterestInDisaster = 75,
	 inHundredChanceOfDisasterWailing = 35,
	 mainStreetModulo	= 4,
	 maxIterationSteps = 2048,
	 chanceCivilianArmsItselfInHundred = 50,
	 
	 maxNrPolice = 6,
	 policeMaxDispatchTime = 2000,
	 policeSpawnMinDistance = 800, --preferably at houses
	 policeSpawnMaxDistance = 2500,
	 maxSirenSoundFiles = 7,
	 
	 --safehouseConfig
	 buildSafeHouseRange = 66,
	 safeHousePieceName = "center",
	 delayTillSafeHouseEstablished= 15000,
	 safeHouseLiftimeUnattached= 15000,

	 --propagandaserver 
	 propandaServerFactor = 0.1,
	 
	 --doubleAgentHeight
	 doubleAgentHeight = 128,
	 
	 --Dayproperties
	 daylength = 28800, --in frames
	 
	 --Aerosoldrone
	 aerosolDistance = 250,
	 
	 -- Interrogation
	 InterrogationTimeInSeconds = 20,
	 InterrogationTimeInFrames = 20*30,
	 InterrogationDistance= 120,
	 
	 --Launcher
	 PreLaunchLeakSteps = 3,
	 LaunchReadySteps = 7,
		 
	 --Game States
	 GameState={
				normal = "normal",
				launchleak = "launchleak",
				anarchy = "anarchy",
				postlaunch = "postlaunch",
				gameover = "gameover",
				pacification = "pacification",
	 },
	
	 
	 
	 TimeForInterceptionInFrames= 30 * 10,
	 TimeForPanicSpreadInFrames= 30 * 30,
	 TimeForPacification = 30* 90,
	 TimeForScrapHeapDisappearanceInMs = 42 *1000,
	 
	 costs ={
		RecruitingTruck= 500,
	 },
	 
	 --Icons
	 iconGroundOffset = 50,
	 
	
	--Operativedrop HeightOffset
	OperativeDropHeigthOffset = 400,
	}
end

GG.GameConfig = getGameConfig()
_G.GameConfig = getGameConfig()
--===================================================================================================================
--===================================================================================================================
function getChemTrailTypes()
return {
	["orgyanyl"] = "orgyanyl",
	["wanderlost"] = "wanderlost",
	["tollwutox"] = "tollwutox",
	["depressol"] = "depressol"
}
end
function getScrapheapTypeTable(UnitDefs)
UnitDefNames= getUnitDefNames(UnitDefs)
return {
			[UnitDefNames["gcscrapheap"].id	]= true
		}

end

function getPoliceTypes()
UnitDefNames= getUnitDefNames(UnitDefs)
return {
			[UnitDefNames["policetruck"].id		]= true
		}

end
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

function getAerosolUnitDefIDs(UnitDefNames)
		AerosolTypes = getChemTrailTypes()
		return {
		[UnitDefNames["air_copter_aerosol_orgyanyl"].id		]= AerosolTypes.orgyanyl,
		[UnitDefNames["air_copter_aerosol_wanderlost"].id	]= AerosolTypes.wanderlost,
		[UnitDefNames["air_copter_aerosol_tollwutox"].id 	]= AerosolTypes.tollwutox,
		[UnitDefNames["air_copter_aerosol_depressol"].id 	]= AerosolTypes.depressol,
		}
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
		"satelliteanti",
		"satellitescan",
		"satellitegodrod"		
	}
	return getTypeTable(UnitDefNames, typeTable)
end

function isUnitInGroup(id, groupname, culture, UnitDefs)
	defID = Spring.GetUnitDefID(id)
	name = UnitDefs[defID].name
	
	if name == groupname then return true end
	culturUnitGroupTable = getCultureUnitModelNames(culture, groupname)

	if ( culturUnitGroupTable.range == 0 ) then
		echo(name.." == "..culturUnitGroupTable.name)
		return (name == culturUnitGroupTable.name) 
	end

	for i=1,culturUnitGroupTable.range do
		if name == (culturUnitGroupTable.name..i) then return true end
	end
	
return false
end

function getCultureUnitModelNames(cultureName, unitType)
translation ={
	["arabic"] = {
		["house"] = {name= "house_arab", range=0},
		["civilian"] = {name= "civilian_arab", range=0},
		["truck"] ={name = "truck_arab", range = 0}
	}
}

return translation[cultureName][unitType]
end

function expandNameSubSetTable(SubsetTable)
	expandedNamesTable = {}
		for i=0, SubsetTable.range do
			name = SubsetTable.name.. i
			expandedNamesTable[#expandedNamesTable +1] = name
		end
	return expandedNamesTable
end

function isUnitOfCivilianType(TypeName, cache, gameconfig)
	boolIsOfType = true
	localcache = cache or {}
		if not cache or #cache < 1 then
			myCulture = gameConfig.instance.culture
			lUnitDefNames =  getUnitDefNames(UnitDefs)
			modelNames = getCultureUnitModelNames(myCulture, TypeName, lUnitDefNames)
			expandedModelNames = expandNameSubSetTable(modelNames)
			for i=1, #expandedModelNames do 
				localcache[UnitDefNames[expandedModelNames[i]].id] = expandedModelNames[i]
			end
		end
		
	TypeID = getUnitDefIDFromName(TypeName)
	boolIsOfType = (localcache[TypeID] ~= nil)

	return boolIsOfType, localcache
end

function getTruckLoadOutTypeTable()
	mapping = {
	["ground_truck_mg"] = "ground_turret_mg",
	["ground_truck_ssied"] = "ground_turret_ssied",
	["ground_truck_antiarmor"] = "ground_turret_antiarmor",
	
	}
	typeDefMappingTable ={}
	
	for k,v in pairs(mapping) do
		if  UnitDefNames[v] and  UnitDefNames[k] then
		typeDefMappingTable[UnitDefNames[k].id] = UnitDefNames[v].id
		else
			if  not UnitDefNames[v] then echo("getTruckLoadOutTypeTable "..v.." is undefined") end
			if  not UnitDefNames[k] then echo("getTruckLoadOutTypeTable "..k.." is undefined") end  
		end
	end
	
	return typeDefMappingTable
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

function  getPanicableCiviliansTypeTable(UnitDefs)
	assert(UnitDefs)
	typeTable={
		"civilian"
	}
	
	return getTypeTable(getUnitDefNames(UnitDefs), typeTable)
end
function  getSafeHouseUpgradeTypeTable(UnitDefs, myDefID)
	UnitDefNames = getUnitDefNames(UnitDefs)
	typeTable={}
	if myDefID == UnitDefNames["antagonsafehouse"].id then
		typeTable={
		"nimrod",
		"propagandaserver",
		"assembly",
		"launcher"
		}
	else
	typeTable={
		"nimrod",
		"blacksite",
		"propagandaserver",
		"assembly"
		}
	end
	
	return getTypeTable(UnitDefNames, typeTable)
end

function  getSafeHouseTypeTable(UnitDefs)

	UnitDefNames = getUnitDefNames(UnitDefs)
	typeTable={
		"protagonsafehouse",
		"antagonsafehouse"
	}
	
	return getTypeTable(UnitDefNames, typeTable)
end

function  getRaidAbleTypeTable(UnitDefs)

	UnitDefNames = getUnitDefNames(UnitDefs)
	typeTable={
		"house",
		"antagonsafehouse",
		"protagonsafehouse"

	}
	
	return getTypeTable(UnitDefNames, typeTable)
end

function  getSafeHouseUpgradeTypeTable(UnitDefs)

	UnitDefNames = getUnitDefNames(UnitDefs)
	typeTable={
		"nimrod",
		"assembly",
		"blacksite",
		"propagandaserver",
		"launcher"
	}
	
	return getTypeTable(UnitDefNames, typeTable)
end

function  getInterrogateAbleTypeTable(UnitDefs)
	assert(UnitDefs)
	UnitDefNames = getUnitDefNames(UnitDefs)
	typeTable={
		"civilianagent",
		"operativeasset",
		"operativepropagator",
		"operativeinvestigator",
		"antagonsafehouse",
		"protagonsafehouse",
		"propagandaserver",
		"launcher"
	}
	
	return getTypeTable(UnitDefNames, typeTable)
end

function  getHouseTypeTable(UnitDefs)

	typeTable={
			"house"		
	}
	
	return getTypeTable( getUnitDefNames(UnitDefs), typeTable)
end

function  getOperativeTypeTable(UnitDefs)
	
	UnitDefNames = getUnitDefNames(UnitDefs)
	typeTable={
		"civilianagent",
		"operativeasset",
		"operativepropagator",
		"operativeinvestigator"
		
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

function getAersolAffectableUnits()
	typeTable={
		"civilian",
		"truck"
	}
	return getTypeTable(getUnitDefNames(UnitDefs), typeTable)
end

function setCivilianBehaviourMode(unitID, boolStartUnitBehaviourState, TypeOfBehaviour )
	env = Spring.UnitScript.GetScriptEnv(unitID)
       if env and env.setBehaviourStateMachineExternal then
		Spring.UnitScript.CallAsUnit(unitID, env.setBehaviourStateMachineExternal, boolStartUnitBehaviourState, TypeOfBehaviour)
       end

end
	
function getCivilianAnimationStates()
return {
	-- Upper Body States
	slaved	="STATE_SLAVED", -- do nothing
	idle	="STATE_IDLE",
	filming	="STATE_FILMING" ,
	phone	="STATE_PHONE",
	wailing	="STATE_WAILING" ,
	talking		="STATE_TALKING",
	handsup	= "STATE_HANDSUP",
	protest = "STATE_PROTEST",

	--	coupled cycles	
	standing	="STATE_STANDING",
	aiming	="STATE_AIMING",
	hit	="STATE_HIT",
	death	="STATE_DEATH",
	transported 		="STATE_TRANSPORTED",
	catatonic = "STATE_CATATONIC",
	-- self ending Cycles	
	trolley = "STATE_PULL",
	walking	="STATE_WALKING",
	running = "STATE_RUNNING",
	coverwalk	="STATE_COVERWALK",
	wounded	="STATE_WOUNDED"   
}

end
framesPerSecond = 30

function getSatelliteTimeOutTable(UnitDefs) --per Frame
UnitDefNames = getUnitDefNames(UnitDefs)

	valuetable={
		[UnitDefNames["satelliteanti"].id] = 2*90 * framesPerSecond,
		[UnitDefNames["satellitegodrod"].id] = 3*90 * framesPerSecond,
		[UnitDefNames["satellitescan"].id] = 90 * framesPerSecond
	}
	
	return valuetable
end

function getSatelliteTypesSpeedTable(UnitDefs) --per Frame
UnitDefNames = getUnitDefNames(UnitDefs)

	valuetable={
		[UnitDefNames["satellitegodrod"].id] = 30/framesPerSecond,
		[UnitDefNames["satelliteanti"].id] = 30/framesPerSecond,
		[UnitDefNames["satellitescan"].id] = 90/framesPerSecond
	}
	
	return valuetable
end

function getSatelliteAltitudeTable(UnitDefs) --per Frame
UnitDefNames = getUnitDefNames(UnitDefs)

	valuetable={
		[UnitDefNames["satellitegodrod"].id] = 1450,
		[UnitDefNames["satelliteanti"].id] = 1550,
		[UnitDefNames["satellitescan"].id] = 1500
	}
	
	return valuetable
end

function getUnitScaleTable(UnitDefNames)
	local defaultScaleTable={}
	realScaleTable ={
	["house"]= 1.0,
	["antagonsafehouse"]=1.0,
	["protagonsafehouse"]=1.0,
	["nimrod"]=1.0,
	["assembly"]=1.0,
	["propagandaserver"]=1.0,
	["launcher"]=1.0,
	["ground_truck_mg"]=1.0,
	["ground_turret_mg"]=1.0,
	
	
	}
	
	for name,v in pairs(UnitDefNames) do
		factor = 0.3
		if realScaleTable[name] then factor = realScaleTable[name] end
		defaultScaleTable[v.id]	= { realScale = factor,   tacticalScale = 1.0}
	end
	
	return defaultScaleTable
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

function getDecalMap(culture)
	if culture == "arabic" then
		return {
			["house"] = {
							rural={
								"house_arab_decal7",
								"house_arab_decal4"
							},						
							urban={
							"house_arab_decal1",
							"house_arab_decal2",
							"house_arab_decal3",				
							"house_arab_decal5",
							"house_arab_decal6"
							}			
						}
		}
	end

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
				
				nextFrame = frame + framerate
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
					boolUnitIsCloaked =	Spring.GetUnitIsCloaked (persPack.unitID)
					
					
					if persPack.startFrame + 30 < Spring.GetGameFrame()  and  boolUnitIsCloaked == false then
						copyUnit(persPack.toTrackID, persPack.myTeam)
						Spring.DestroyUnit(persPack.toTrackID,true,true)
						Spring.DestroyUnit(persPack.unitID,true,true)
						return boolEndFunction, nil
					end
				

					return boolContinue, persPack
				end

createStreamEvent(doubleAgentID, hoverAboveFunc, 1, {
													startFrame = Spring.GetGameFrame(),
													unitID = doubleAgentID,
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
					--if Unit did not die peacefully - kill the synced unit
					if not GG.DiedPeacefully[persPack.myID] then
						Spring.DestroyUnit(persPack.syncedID, false, true) 
					end
				
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

function registerFather( teamID, parent)
-- Spring.Echo("register Father of unit")
	if not GG.InheritanceTable[teamID][parent] then GG.InheritanceTable[teamID][parent] ={} end
end

function registerChild( teamID, parent, childID)
-- Spring.Echo("register Child child of unit")
if not GG.InheritanceTable[teamID][parent] then GG.InheritanceTable[teamID][parent] ={} end

	GG.InheritanceTable[teamID][parent][childID]= true
end

function getChildrenOfUnit(teamID, unit)
-- Spring.Echo("Getting children of unit")
return GG.InheritanceTable[teamID][unit] or {}
end

function getParentOfUnit(teamID, unit)
-- Spring.Echo("getParentOfUnit")
	for parent, unitTable in pairs( GG.InheritanceTable[teamID]) do
		if unitTable then
			for thisUnit,_ in pairs(unitTable) do
				if unit == thisUnit then return parent end
			end
		end
	end
end

function giveParachutToUnit(id,x,y, z)
	parachutID = createUnitAtUnit(Spring.GetUnitTeam(id), "air_parachut", id)
	
	if not GG.ParachutPassengers then GG.ParachutPassengers  ={} end

	GG.ParachutPassengers[parachutID]={id=id, x= x, y=y, z= z}
	Spring.SetUnitTooltip(parachutID,id.."")
	setUnitValueExternal(id, 'WANT_CLOAK' , 0)
end

function removeUnit(teamID, unit)
-- Spring.Echo("removing unit from graph")
	parent= getParentOfUnit(teamID, unit)
	if parent then  GG.InheritanceTable[teamID][parent][unit] = nil end
	if GG.InheritanceTable[teamID][unit] then GG.InheritanceTable[teamID][unit] = nil end
end