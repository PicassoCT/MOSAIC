--===================================================================================================================
-- Game Configuration

unitFactor= 0.5 --0.5


function getGameConfig()
	return {
	instance = {
	culture = "arabic", -- "international", "european", "chinese", "russia", "northamerica", "southamerica"
	Version = "Alpha: 0.699",
	},
		
	numberOfBuildings 	= math.ceil(75 *unitFactor	),  --not related to the hangdetector bug
    numberOfVehicles 	= math.ceil(100 *unitFactor	), --not related to the hangdetector bug
    numberOfPersons		= math.ceil(150 *unitFactor	), --not related to the hangdetector bug
	LoadDistributionMax = 5,
	
	 houseSizeX			= 256, 
	 houseSizeY			= 16, 
	 houseSizeZ			= 256,
	 xRandOffset		= 20,
	 zRandOffset		= 20,
	 allyWaySizeX 		= 25,
	 allyWaySizeZ		= 25,
	 bonusFirstUnitMoney_S = 12,
	 bonusFirstUnitMaterial_S = 8,
	 
	 agentConfig={
		recruitmentRange= 60,
		raidWeaponDownTimeInSeconds =  60,
		raidComRange= 1200,
		raidBonusFactorSatellite = 2.5,
	 },
	SnipeMiniGame ={
	
	Aggressor ={
	StartPoints =4},
	Defender ={
	StartPoints =4},
	},

 --ObjectiveRewardRate

	 
	Objectives = {
		RewardCyle = 30* 60, -- /30 frames = 1 seconds
		Reward = 50,
	},
	 --civilianbehaviour
	 civilianGatheringBehaviourIntervalFrames = 3*60*30,
	 
	 civilianPanicRadius = 350,
	 civilianFleeDistance = 500,
	 civilianInterestRadius = 150,
	 generalInteractionDistance= 250,
	 minConversationLengthFrames= 3 * 30,
	 maxConversationLengthFrames= 25 *30,
	 groupChatDistance = 150,
	 inHundredChanceOfInterestInDisaster = 75,
	 inHundredChanceOfDisasterWailing = 35,
	 mainStreetModulo	= 4,
	 maxIterationSteps = 2048,
	 chanceCivilianArmsItselfInHundred = 50,
	 demonstrationMarchRadius = 50,
	 
	 maxNrPolice = 6,
	 policeMaxDispatchTime = 2000,
	 policeSpawnMinDistance = 800, --preferably at houses
	 policeSpawnMaxDistance = 2500,
	 maxSirenSoundFiles = 7,
	 
	 --safehouseConfig
	 buildSafeHouseRange = 80,
	 safeHousePieceName = "center",
	 delayTillSafeHouseEstablished= 15000,
	 safeHouseLiftimeUnattached= 15000,
	 	
	 --all buildings
	 buildingLiftimeUnattached = 10000,

	 --propagandaserver 
	 propandaServerFactor = 0.1,
	 
	 --doubleAgentHeight
	 doubleAgentHeight = 256,
	 
	 --Dayproperties
	 daylength = 28800, --in frames
	 
	 --Aerosoldrone
	 aerosolDistance = 250,

	
	 -- Interrogation
	 InterrogationTimeInSeconds = 20,
	 InterrogationTimeInFrames = 20*30,
	 InterrogationDistance= 256,
	 
	 RaidInterrogationPropgandaPrice = 50,
	 investigatorCloakedSpeedReduction = 0.35,
	 raidWaitTimeToRecloak = 5000,
	 operativeShotFiredWaitTimeToRecloak_MS = 10000,

	--checkpoint
	checkPointRevealRange = 125,
	checkPointPropagandaCost= 50,

	 raid={
	 maxTimeToWait = 3*60*1000,
	 maxRoundLength= 20*1000,
	 },
	 
	 --asset
	 assetCloakedSpeedReduction = 0.175,
	 assetShotFiredWaitTimeToRecloak_MS = 6000,
	 
	 Wreckage ={
	 lifeTime = 3*60*1000,
	 },	 
	 
	 --Launcher
	 PreLaunchLeakSteps = 3,
	 LaunchReadySteps = 7,
	 LauncherInterceptTimeSeconds= 20,
	 
	 --CruiseMissiles
	 CruiseMissilesHeightOverGround=  22,
		 
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
	 TimeForScrapHeapDisappearanceInMs = 3*60* 30, -- 3 Minutes off line
	 
	 costs ={
		RecruitingTruck= 500,
	 },
	 --startenergymetal
	 energyStartVolume = 10000,
	 energyStart = 5000,
	 metalStartVolume = 10000,
	 metalStart = 5000,
	 
	 --Icons
	 iconGroundOffset = 50,
	 SatelliteIconDistance = 150,
	
	--Operativedrop HeightOffset
	OperativeDropHeigthOffset = 900,
	
	--Hiveminds & AiCores
	integrationRadius = 75,
	maxTimeForSlowMotionRealTimeSeconds = 10,
	addSlowMoTimeInMsPerCitizen = 150,
	
	--Aerosols
	Aerosols={
	sprayRange = 200,
	orgyanyl={	
	sprayTimePerUnitInMs = 2*60*1000, --2mins
	VictimLifetime = 60000,
	},
	wanderlost={
	sprayTimePerUnitInMs = 2*60*1000 ,
	VictimLiftime = 3*60*1000
	},--2mins
	tollwutox={sprayTimePerUnitInMs = 2*60*1000,}, --2mins
	depressol={sprayTimePerUnitInMs = 2*60*1000,}, --2mins
	},
}
end

GG.GameConfig = getGameConfig()
_G.GameConfig = getGameConfig()
--===================================================================================================================
function getCultureName()
GameConfig = getGameConfig()
	return GameConfig.instance.culture
end
--===================================================================================================================
function getChemTrailTypes()
return {
	["orgyanyl"] = "orgyanyl",
	["wanderlost"] = "wanderlost",
	["tollwutox"] = "tollwutox",
	["depressol"] = "depressol"
}
end

function getChemTrailInfluencedTypes(UnitDefs)
	assert(UnitDefs)
	local UnitDefNames =  getUnitDefNames(UnitDefs)

	typeTable = {"civilianagent"}
	typeTable = mergeTables(typeTable, getTypeUnitNameTable(getCultureName(), "civilian", UnitDefs))
	typeTable = mergeTables({}, getTypeUnitNameTable(getCultureName(), "truck", UnitDefs))
	
	return getTypeTable(UnitDefNames, typeTable)
end

function getScrapheapTypeTable(UnitDefs)
local UnitDefNames= getUnitDefNames(UnitDefs)
return {
			[UnitDefNames["gcscrapheap"].id	]= UnitDefNames["gcscrapheap"].id	
		}
end

function getPoliceTypes(UnitDefs)
local UnitDefNames= getUnitDefNames(UnitDefs)
return {
			[UnitDefNames["policetruck"].id		]= true,
			[UnitDefNames["ground_tank_night"].id		]= true,
			[UnitDefNames["ground_tank_day"].id		]= true
		}
end

function getObjectiveTypes(UnitDefs)
assert(UnitDefs)
local UnitDefNames= getUnitDefNames(UnitDefs)
return {
 			[UnitDefNames["objective_refugeegyland"].id]	= "water",
 			[UnitDefNames["objective_factoryship"].id]		= "water",
			[UnitDefNames["objective_refugeecamp"].id]		= "land",
			[UnitDefNames["objective_powerplant"].id]		= "land",
			[UnitDefNames["objective_geoengineering"].id]	= "land",
			[UnitDefNames["objective_westhemhq"].id	]		= "land",
			[UnitDefNames["objective_artificialglacier"].id	]= "land"
		}
end

function getIconTypes(UnitDefs)
local UnitDefNames= getUnitDefNames(UnitDefs)
return {
 			[UnitDefNames["raidicon"].id		]= true,
			[UnitDefNames["doubleagent"].id		]= true,
			[UnitDefNames["interrogationicon"].id		]= true,
			[UnitDefNames["recruitcivilian"].id		]= true
		}
end

--Mosaic specific functions 
--> creates a table from names to check unittypes against
function getUnitDefNames(UnitDefs)
	local UnitDefNames = {}
	if UnitDefs == nil then return nil end
	
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
	local UnitDefNames = getUnitDefNames(UnitDefs)
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
local	UnitDefNames = getUnitDefNames(UnitDefs)
	typeTable={
		"satelliteanti",
		"satellitescan",
		"satellitegodrod"		
	}
	return getTypeTable(UnitDefNames, typeTable)
end

function getTranslation(cultureName)
translation ={
		["arabic"] = {
			["house"] = {name= "house_arab", range=0},
			["civilian"] = {name= "civilian_arab", range=3},
			["truck"] ={name = "truck_arab", range = 8}
		},
		["international"] = {
			["house"] = {name= "house_int", range=0},
			["civilian"] = {name= "civilian_int", range=0},
			["truck"] ={name = "truck_int", range = 3}
		},
		["european"] = {
			["house"] = {name= "house_european", range=0},
			["civilian"] = {name= "civilian_european", range=0},
			["truck"] ={name = "truck_european", range = 3}
		},
	}
	return translation[cultureName]
end

function getCultureUnitModelTypes (cultureName, typeName, UnitDefs)
	UnitDefNames = getUnitDefNames(UnitDefs)
	allNames = getCultureUnitModelNames(cultureName, typeName, UnitDefs)
	result ={}
	
	for num, name in pairs(allNames) do
		result[UnitDefNames[name].id] = UnitDefNames[name].id
	end
	
	return result
end



function getCultureUnitModelNames(cultureName, typeName, UnitDefs)
	assert( UnitDefs )
	translation =getTranslation(cultureName)
	return expandNameSubSetTable(translation[typeName], UnitDefs)
end

function getTypeUnitNameTable(culturename, typeDesignation, UnitDefs)
	assert( UnitDefs )
	ID_Name_Map = getCultureUnitModelNames(culturename, typeDesignation, UnitDefs)

	results= {}
		for defID, name in pairs(ID_Name_Map) do
			table.insert(results, name)
		end

return results
end

function expandNameSubSetTable(SubsetTable, UnitDefs)
local	UnitDefNames = getUnitDefNames(UnitDefs)
	expandedDictId_Name = {}
		for i=0, SubsetTable.range do
			if UnitDefNames[SubsetTable.name.. i] then
				expandedDictId_Name[UnitDefNames[SubsetTable.name.. i].id]= SubsetTable.name.. i
			end
		end
	return expandedDictId_Name
end

function getUnitType_BaseTypeMap(UnitDefs, culture)
	truckTypes = getTypeUnitNameTable(culture, "truck", UnitDefs)
	houseTypes = getTypeUnitNameTable(culture, "house", UnitDefs)
	civilianTypes = getTypeUnitNameTable(culture, "civilian", UnitDefs)
	results ={}

	-- echo("trucktypes:",truckTypes)
	for num, name in pairs(truckTypes) do
		results[name]= "truck"
	end

	for num, name in pairs(houseTypes) do
		results[name]= "house"
	end

	for num, name in pairs(civilianTypes) do
		results[name]= "civilian"
	end

	return results
end


function getBaseTypeName(name)
	if name:match("house") then return "house" end
	if name:match("civilian") then return "civilian" end
	if name:match("truck") then return "truck" end

end

function getRaidStates()
	return {
			["Aborted"] = 0,
			["OnGoing"] = 1,
			["DefenderWins"] = 2,
			["AggressorWins"] = 3
			}

end

function getTruckLoadOutTypeTable()
	mapping = {
	["ground_truck_mg"] = "ground_turret_mg",
	["ground_truck_ssied"] = "ground_turret_ssied",
	["ground_truck_antiarmor"] = "ground_turret_antiarmor",
	["ground_truck_rocket"] = "ground_turret_rocket",
	
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

function getTruckTypeTable(UnitDefs)
	local UnitDefNames =  getUnitDefNames(UnitDefs)
	GameConfig= getGameConfig()
	
	typeTable= getCultureUnitModelNames(GameConfig.instance.culture, "truck", UnitDefs)
	
	return getTypeTable( UnitDefNames, typeTable)
end

function  getMobileCivilianDefIDTypeTable(UnitDefs)
	assert(UnitDefs)
	GameConfig = getGameConfig()
	local	UnitDefNames = getUnitDefNames(UnitDefs)
	typeTable=getTypeUnitNameTable(GameConfig.instance.culture, "truck", UnitDefs)
	typeTable = mergeTables(typeTable, getTypeUnitNameTable(GameConfig.instance.culture, "civilian", UnitDefs))
	
	return getTypeTable(UnitDefNames, typeTable)
end

function  getPanicableCiviliansTypeTable(UnitDefs)
	assert(UnitDefs)
	local UnitDefNames =  getUnitDefNames(UnitDefs)

	typeTable = {}
	typeTable = mergeTables(typeTable, getTypeUnitNameTable(getCultureName(), "civilian", UnitDefs))
	
	return getTypeTable(UnitDefNames, typeTable)
end

function  getSafeHouseUpgradeTypeTable(UnitDefs, myDefID)
local	UnitDefNames = getUnitDefNames(UnitDefs)
	typeTable={}
	if not myDefID then 
			typeTable={
			"nimrod",
			"propagandaserver",
			"assembly"
			}

	else

		if myDefID == UnitDefNames["antagonsafehouse"].id then
			typeTable={
			"nimrod",
			"propagandaserver",
			"assembly",
			"launcher",
			"hivemind"
			}
		else
		typeTable={
			"nimrod",
			"blacksite",
			"propagandaserver",
			"assembly",
			"aicore"
			}
		end
	end
	
	return getTypeTable(UnitDefNames, typeTable)
end

function  getSafeHouseTypeTable(UnitDefs)

local	UnitDefNames = getUnitDefNames(UnitDefs)
	typeTable={
		"protagonsafehouse",
		"antagonsafehouse"
	}
	
	return getTypeTable(UnitDefNames, typeTable)
end


function  getInterrogateAbleTypeTable(UnitDefs)
	assert(UnitDefs)
	GameConfig = getGameConfig()
local	UnitDefNames = getUnitDefNames(UnitDefs)
	typeTable={
		"civilianagent",
		"operativeasset",
		"operativepropagator",
		"operativeinvestigator",
		"antagonsafehouse",
		"protagonsafehouse",
		"propagandaserver",
		"assembly",
		"launcher",
		"hivemind",
		"aicore"
	}
	
	typeTable = mergeTables(typeTable, getTypeUnitNameTable(GameConfig.instance.culture, "civilian", UnitDefs))	
	
	return getTypeTable(UnitDefNames, typeTable)
end

function  getMobileInterrogateAbleTypeTable(UnitDefs)
	assert(UnitDefs)
	GameConfig = getGameConfig()
local	UnitDefNames = getUnitDefNames(UnitDefs)
	typeTable={
		"civilianagent",
		"operativeasset",
		"operativepropagator",
		"operativeinvestigator"
	}
	
	typeTable = mergeTables(typeTable, getTypeUnitNameTable(GameConfig.instance.culture, "civilian", UnitDefs))	
	
	return getTypeTable(UnitDefNames, typeTable)
end

function getRaidIconTypeTable(UnitDefs)
	assert(UnitDefs)
	GameConfig = getGameConfig()
local	UnitDefNames = getUnitDefNames(UnitDefs)
	typeTable={
		"raidicon",
		"snipeicon",
		"objectiveicon"
	}
		
	return getTypeTable(UnitDefNames, typeTable)
end


function getRaidAbleTypeTable(UnitDefs)
	assert(UnitDefs)
	GameConfig = getGameConfig()
local	UnitDefNames = getUnitDefNames(UnitDefs)
	typeTable={
		"civilianagent",
		"operativeasset",
		"operativepropagator",
		"operativeinvestigator"
	}
	
	typeTable = mergeTables(typeTable, getTypeUnitNameTable(GameConfig.instance.culture, "civilian", UnitDefs))	
	
	return getTypeTable(UnitDefNames, typeTable)
end


function  getHouseTypeTable(UnitDefs, culturename)
		assert( UnitDefs )
		return getCultureUnitModelNames(culturename , "house", UnitDefs)
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
local	UnitDefNames = getUnitDefNames(UnitDefs)
	GameConfig = getGameConfig()
	typeTable=getTypeUnitNameTable(GameConfig.instance.culture, "truck", UnitDefs)
	typeTable = mergeTables(typeTable, getTypeUnitNameTable(GameConfig.instance.culture, "house", UnitDefs))
	typeTable = mergeTables(typeTable, getTypeUnitNameTable(GameConfig.instance.culture, "civilian", UnitDefs))
	
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

function getAersolAffectableUnits(UnitDefs)
	local UnitDefNames =  getUnitDefNames(UnitDefs)

	typeTable = mergeTables({}, getTypeUnitNameTable(getCultureName(), "truck", UnitDefs))
	typeTable = mergeTables(typeTable, getTypeUnitNameTable(getCultureName(), "civilian", UnitDefs))
	
	return getTypeTable(UnitDefNames, typeTable)
end

function setCivilianBehaviourMode(unitID, boolStartUnitBehaviourState, TypeOfBehaviour )
	env = Spring.UnitScript.GetScriptEnv(unitID)
       if env and env.setBehaviourStateMachineExternal then
		Spring.UnitScript.CallAsUnit(unitID, env.setBehaviourStateMachineExternal, boolStartUnitBehaviourState, TypeOfBehaviour, true)
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
local UnitDefNames = getUnitDefNames(UnitDefs)

	valuetable={
		[UnitDefNames["satelliteanti"].id] = 2*90 * framesPerSecond,
		[UnitDefNames["satellitegodrod"].id] = 3*90 * framesPerSecond,
		[UnitDefNames["satellitescan"].id] = 90 * framesPerSecond
	}
	
	return valuetable
end

function getSatelliteTypesSpeedTable(UnitDefs) --per Frame
local UnitDefNames = getUnitDefNames(UnitDefs)

	valuetable={
		[UnitDefNames["satellitegodrod"].id] = 30/framesPerSecond,
		[UnitDefNames["satelliteanti"].id] = 30/framesPerSecond,
		[UnitDefNames["satellitescan"].id] = 90/framesPerSecond
	}
	
	return valuetable
end

function getSatelliteAltitudeTable(UnitDefs) --per Frame
local UnitDefNames = getUnitDefNames(UnitDefs)

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
								"house_arab_decal8",
								"house_arab_decal7",
								"house_arab_decal4",
								"house_arab_decal10",
								"house_arab_decal11",
								"house_arab_decal12"
							},						
							urban={
								"house_arab_decal1",
								"house_arab_decal2",
								"house_arab_decal3",				
								"house_arab_decal5",
								"house_arab_decal6",
								"house_arab_decal9"
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
GameConfig = getGameConfig()
if not GG.DoubleAgents then GG.DoubleAgents={} end
if  GG.DoubleAgents[id] then
--already has DoubleAgent attached- abort
	return  GG.DoubleAgents[id] 
 end

doubleAgentID = createUnitAtUnit(teamToTurnTo, "doubleagent", id, 0, GameConfig.doubleAgentHeight , 0)
GG.DoubleAgents[id]= doubleAgentID

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
						persPack.unitID =createUnitAtUnit(persPack.myTeam, "doubleagent", persPack.toTrackID, x - 10, y + persPack.heightAbove , z)
						Spring.MoveCtrl.Enable(persPack.unitID)
						
						return boolContinue, persPack
					end					
					
					Spring.MoveCtrl.SetPosition(persPack.unitID, x-10,y + persPack.heightAbove,z)	
					boolUnitIsCloaked =	Spring.GetUnitIsCloaked(persPack.unitID)	

					if not persPack.boolCloakedAtLeastOnce  then
						persPack.boolCloakedAtLeastOnce = boolUnitIsCloaked
					end

					persPack.boolCloakedAtLeastOnce = persPack.boolCloakedAtLeastOnce or boolUnitIsCloaked

					if persPack.startFrame + 30 < Spring.GetGameFrame() and persPack.boolCloakedAtLeastOnce == true and boolUnitIsCloaked == false then
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
													heightAbove = GameConfig.doubleAgentHeight,
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
						Command(persPack.myID, "stop", {},{})
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
					moveUnitToUnitGrounded(persPack.myID, persPack.syncedID, math.random(-10,10),0, math.random(-10,10))
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
	if not GG.ParachutPassengers then GG.ParachutPassengers  ={} end
	
	if Spring.GetGameFrame() < 1 then
	
		delayedParachutSpawn =function (evtID, frame, persPack, startFrame)
		
		if Spring.GetGameFrame() < 1 then 
		return  frame + 1, persPack
		end
		
		parachutID = createUnitAtUnit(Spring.GetUnitTeam(persPack.id), "air_parachut", persPack.id)
		GG.ParachutPassengers[parachutID]={id=persPack.id, x= persPack.x, y=persPack.y, z= persPack.z}
		Spring.SetUnitTooltip(parachutID,persPack.id.."")
		--setUnitValueExternal(persPack.id, 'WANT_CLOAK' , 0)
		--setUnitValueExternal(persPack.id, 'CLOAKED' , 0)
		return nil, nil
		end
				
		persPack ={id = id,
					x= x,
					y=y,
					z=z
					}
	
		GG.EventStream:CreateEvent(
		delayedParachutSpawn,
		persPack,
		Spring.GetGameFrame() + 1)
	
	else
		parachutID = createUnitAtUnit(Spring.GetUnitTeam(id), "air_parachut", id)

		GG.ParachutPassengers[parachutID]={id=id, x= x, y=y, z= z}
		Spring.SetUnitTooltip(parachutID,id.."")
		setUnitValueExternal(id, 'WANT_CLOAK' , 0)
	end
end

function removeUnit(teamID, unit)
-- Spring.Echo("removing unit from graph")
	parent= getParentOfUnit(teamID, unit)
	if parent then  GG.InheritanceTable[teamID][parent][unit] = nil end
	if GG.InheritanceTable[teamID][unit] then GG.InheritanceTable[teamID][unit] = nil end
end


function getHouseClusterPoints(UnitDefs, culture)

	houseTypeTable= getHouseTypeTable(UnitDefs, culture)
	local PositionTable ={}
	
	process(Spring.GetAllUnits(),
			function(id)
				defID = Spring.GetUnitDefID(id)
				if houseTypeTable[defID] then 	
					return id
				end
			end,
			function(id)
				x,y,z= Spring.GetUnitPosition(id)
				PositionTable[#PositionTable+1]= {x=x,y=y,z=z}
			end
			)
	assert(#PositionTable > 0)

	--PositionTable= shuffleT(PositionTable)		
		local	midPoints ={}
			--calculate midpoints
			for n=1, #PositionTable  do
				for i=1, #PositionTable  do
					dist = distance(PositionTable[i],PositionTable[n])
					local pos = mixTable(PositionTable[i],PositionTable[n], 0.5)
					_,_,_,slope =	Spring.GetGroundNormal(pos.x, pos.z)
					
					if dist < 1024 and i ~= n and slope < 0.1 then 
						midPoints[#midPoints+1] = 	pos	
					end
				end
			end
	
	assert(#midPoints > 0)	
	return midPoints
end

function cullPositionCluster(PosTable, iterrations)
	if count(PosTable) <= 3 then 
		Spring.Echo("cullPositionCluster: PosTable to small")
		return PosTable 
	end

	local culledPoints= PosTable

	for it=1, iterrations do
		local result={}
		for i=1, count(culledPoints)-1, 2 do
			pos = mixTable(culledPoints[i], culledPoints[i+1], 0.5)	
			_,_,_,slope =	Spring.GetGroundNormal(pos.x, pos.z)
			
			if slope <  0.1  then 
				result[#result+1] = pos
			end
		end
		culledPoints = result
			
		if count(culledPoints) <= 3 then
			Spring.Echo("Aborting with Points:"..count(culledPoints))
			return culledPoints
		end
	end
	
	return culledPoints
end

function computateClusterNodes(housePosTable, GameConfig)
	timeFactor = math.abs(math.sin(math.pi*Spring.GetGameFrame() / GameConfig.civilianGatheringBehaviourIntervalFrames)) -- [0 - 1]
	
	goalIndexMaxDivider = getBelowPow2(GameConfig.numberOfBuildings)
	--protect against min and max
	goalIndexDivider = math.floor(goalIndexMaxDivider*timeFactor)
	Spring.Echo("IndexDivider : "..goalIndexDivider)
	local result = cullPositionCluster(housePosTable, goalIndexDivider)
	return result
end

function computeOrgHouseTable(UnitDefs, GameConfig)
	return getHouseClusterPoints(UnitDefs, GameConfig.instance.culture)
end



function showHideIconEnv( unitID, arg)
    env = Spring.UnitScript.GetScriptEnv(unitID)
    if env and env.showHideIcon then
		Spring.UnitScript.CallAsUnit(unitID, env.showHideIcon, arg)
    end
end

function getInfluencedStates()
return {
["Init"]="Init",
["PreOutbreak"]="PreOutbreak",
["Outbreak"]="Outbreak",
["Dieing"]="Dieing"
}
end

function getInfluencedStateMachine(unitID, UnitDefs, typeOfInfluence )
AerosolTypes = getChemTrailTypes()
InfStates = getInfluencedStates()
CivilianTypes = getCivilianTypeTable(UnitDefs)

InfluenceStateMachines = {
	[AerosolTypes.orgyanyl] = function (lastState, currentState, unitID)
								if currentState == AerosolTypes.orgyanyl then currentState = InfStates.Init end
								
								--Init 
								if currentState == InfStates.Init then
									val= math.random(10, 60)/1000
									spinT(Spring.GetUnitPieceMap(unitID), z_axis, val*randSign(), 0000015)
									currentState = InfStates.PreOutbreak
								end
								
								if currentState == InfStates.PreOutbreak then
									val= math.random(10, 60)/1000
									spinT(Spring.GetUnitPieceMap(unitID), z_axis, val*randSign(), 0000015)

									al = Spring.GetUnitNearestAlly(unitID)
									if al and CivilianTypes[Spring.GetUnitDefID(al)] then
										x,y,z = Spring.GetUnitPosition(al)
										Command(unitID, "go", { x= x, y= y, z = z}, {})
										if distanceUnitToUnit(unitID, al) < 50 then
											currentState = InfStates.Outbreak
										end
									else
										currentState = InfStates.Outbreak
									end	
									setOverrideAnimationState(eAnimState.walking, eAnimState.walking,  true, nil, true)							
								end
								
								if currentState == InfStates.Outbreak then
									for i=1,3 do
										stopSpinT(Spring.GetUnitPieceMap(unitID),i)
									end

								showID = createUnitAtUnit(Spring.GetGaiaTeamID(), "civilian_orgy_pair", unitID, 0, 0, 0)
								myDefID = Spring.GetUnitDefID(showID)
								process(getAllNearUnit(showID,100),
										function(id)	--get Bystanders
											defID = Spring.GetUnitDefID(id)
											if CivilianTypes[defID] then
												x,y,z = Spring.GetUnitPosition(al)
												Command(id, "go", { x= x+math.random(-10,10), y= y, z = z+math.random(-10,10)}, {})	
											end
										end
										)									
									Spring.DestroyUnit(unitID, false, true)
								end
								
								return currentState
							end,
							
	[AerosolTypes.wanderlost] = function (lastState, currentState, unitID)
							if currentState == AerosolTypes.wanderlost then
								StartThread(lifeTime, unitID, GG.GameConfig.Aerosols.wanderlost.VictimLiftime, false, true)
								currentState = InfStates.Init
							end
							
							if currentState == InfStates.Init then
								currentState = InfStates.Outbreak
							end
							
							if currentState == InfStates.Outbreak then
							gf =Spring.GetGameFrame()
							
								if  gf % 27 == 0 then
									randPiece= Spring.GetUnitPieceMap(unitID)
									for i=1,3 do
										val = math.random(5, 35)/100
										spinT(Spring.GetUnitPieceMap(unitID), i, val*-1, val, 0.0015)
									end											
								end
								
								if  gf % 81 == 0 then
									for i=1,3 do
										stopSpinT(Spring.GetUnitPieceMap(unitID),i)
									end										
								end
							
							
								x = (unitID * 65533) % Game.mapSizeX
								z = (unitID * 65533) % Game.mapSizeZ
								f = (Spring.GetGameFrame()% GG.GameConfig.Aerosols.wanderlost.VictimLiftime)/GG.GameConfig.Aerosols.wanderlost.VictimLiftime
								--spiraling in towards nowhere
								totaldistance= math.max(128, unitID%900)*math.sin(f*2*math.pi)
								tx,tz= Rotate(totaldistance, 0, f*math.pi*9)
								x = x+tx
								z = z+tz										
								Command(unitID, "go", { x=x,y=0, z=z}, {})								
							end

							return currentState
							end,
	[AerosolTypes.tollwutox] = function (lastState, currentState, unitID)
								gf =Spring.GetGameFrame()
								--random shivers
								if  gf % 30 == 0 and maRa() then
									for i=1,3 do
										val = (math.random(-100,100)/100) * 12
										turnT(Spring.GetUnitPieceMap(unitID), i, math.rad(val) , 3.125)
									end											
								end
								
								ad= Spring.GetUnitNearestAlly(unitID)
								ed= Spring.GetUnitNearestEnemy(unitID)
								Spring.SetUnitNeutral(unitID, false)
									if ad and ed and  distanceUnitToUnit(unitID,ad) < distanceUnitToUnit(unitID,ed) then								
										Command(unitID, "attack",  ad, {})
									else
										Command(unitID, "attack",  ed, {})
									end		
		
								return currentState							
							 end,
	[AerosolTypes.depressol] = function (lastState, currentState, unitID)
								if currentState == AerosolTypes.depressol then
									StartThread(lifeTime, unitID, GG.GameConfig.Aerosols.depressol.VictimLiftime, false, true)
									currentState = InfStates.Init
								end
								stunUnit(unitID, 2)
								setOverrideAnimationState(eAnimState.standing, eAnimState.wailing,  true, nil, true)							
										
								return currentState
							 end
}

	assert(IInfluenceStateMachines[typeOfInfluence], typeOfInfluence )
	return InfluenceStateMachines[typeOfInfluence]
end

-->StartThread(dustCloudPostExplosion,unitID,1,600,50,0,1,0)
--Draws a long lasting DustCloud
function dustCloudPostExplosion(unitID, Density, totalTime, SpawnDelay, dirx, diry, dirz)
	x, y, z = Spring.GetUnitPosition(unitID)
	y = y + 15
	firstTime = true
	for j = 1, totalTime, SpawnDelay do
		for i = 1, Density do
			Spring.SpawnCEG("lightuponsmoke", x, y, z, dirx, diry, dirz)
		end	
	Sleep(SpawnDelay)
	end
	Sleep(550 - totalTime)
	
	if math.random(0, 1) == 1 then
		Spring.SpawnCEG("earcexplosion", x, y + 30, z, 0, -1, 0)
	end
end


function getAllTeamsOfType(teamType)
gaiaTeamID= Spring.GetGaiaTeamID()
local returnT= {}
 process(Spring.GetTeamList(),
			function(tid)
				teamID, leader, isDead, isAiTeam, side,  allyTeam,  incomeMultiplier =Spring.GetTeamInfo(tid)
				
				if tid ~= gaiaTeamID and false== isDead and ( string.find(side, teamType) or side == "") then
					returnT[tid]= tid
				end
			end
			) 
 return returnT
end
   

function transferFromTeamToAllTeamsExceptAtUnit(unit, teamToWithdrawFrom, amount, teamsToIgnore)
  	local allTeams = Spring.GetTeamList()
  	if not unit or not  GG.Bank or not allTeams or #allTeams <= 1 then
		return false
	end
                     
    GG.Bank:TransferToTeam(
                       -amount,
                       teamToWithdrawFrom,
                       unit
                    )

    for i = 1, #allTeams, 1 do
    	teamID = allTeams[i] 
        if teamID ~= teamToWithdrawFrom and not teamsToIgnore[teamID] then
            GG.Bank:TransferToTeam(
                amount,
                teamID,
                unit
            )
        end
    end
end