local Hivemind = Building:New{
	corpse				= "",
	maxDamage           = 1500,
	mass                = 500,
	name 				= "HivemindSupraIntelligence",
	description 		= " provides information warfare once assembled (",
	buildPic 			= "hivemind.png",
	iconType 			= "hivemind",
	buildTime 			= 3*60,
	buildCostEnergy     = 5000,
	buildCostMetal      = 2500,

	UnitRestricted = 1,
        EnergyUse 			= 10,
	MetalStorage 		= 0,

	EnergyMake 			= 0, 
	MakesMetal 			= 0, 
	MetalMake 			= 0,	
	workerTime 			= 1,
	buildTime			= 60,
	Builder 			= true,
	YardMap 			="yyyy yyyy yyyy yyyy",

	explodeAs			= "none",
	buildingMask 		= 8,
	maxSlope 			= 50.0,
	levelGround 		= false,
	blocking 			= false,
	CanReclaim			= false,
	onoffable 			= true,	

	footprintX 			= 4,
	footprintZ 			= 4,
	script 				= "hivemindscript.lua",
	objectName        	= "hivemind.dae",

	usepiececollisionvolumes = false,
  	collisionVolumeType = "box",
  	collisionvolumescales = "100 70 100",
  	collisionVolumeOffsets  = {0.0, 30.0,  0.0},

	showNanoFrame		= true,
	nanocolor			= [[0.20 0.411 0.611]],
	canCloak 			= true,
	cloakCost 			= 0.0001,
	ActivateWhenBuilt	= false,
	cloakCostMoving 	= 0.0001,
	minCloakDistance 	= -1.0,
	onoffable			= true,
	initCloaked 		= true,
	decloakOnFire 		= false,
	cloakTimeout 		= 5,
	selfDestructCountdown = 3*60,
	category 			= [[GROUND BUILDING RAIDABLE]],
	buildoptions = 
	{
		"informationpayload",		
		"socialengineeringicon",
		"blackouticon",
		"cybercrimeicon",
		"bribeicon"
	},

	customparams = {
		helptext		= "Hivemind",
		baseclass		= "Building",
		normaltex 		= "unittextures/component_atlas_normal.dds",
    },
}

local AICore = Building:New{
	corpse				= "",
	maxDamage           = 1500,
	mass                = 500,
	name = "AI",
	description = " supra intelligent machine <Allows use of SlowMotion>",
	buildPic = "ai.png",
	iconType ="ai",
	buildTime = 25,
	buildCostMetal      = 2500,
	buildCostEnergy     = 500,

 
        UnitRestricted = 1,
        EnergyUse = 10,
	MetalStorage = 0,

	EnergyMake = 0, 
	MakesMetal = 0, 
	MetalMake = 0,	
	
	acceleration = 0,
	
	explodeAs			= "none",
	buildingMask = 8,
	footprintX = 8,
	footprintZ = 8,
	buildingMask = 8,
	maxSlope = 50.0,
	levelGround = false,
	blocking =false,

	script 			= "aicorescript.lua",
	objectName        	= "aicore.dae",
	customParams        = {
		normaltex = "unittextures/propagandaserver_normal.dds",
	},
	
	usepiececollisionvolumes = false,
  	collisionVolumeType = "box",
  	collisionvolumescales = "100 70 100",
  	collisionVolumeOffsets  = {0.0, 30.0,  0.0},

	showNanoFrame= true,
	nanocolor=[[0.20 0.411 0.611]],
	canCloak =true,
	cloakCost=0.0001,
	ActivateWhenBuilt= false,
	cloakCostMoving =0.0001,
	minCloakDistance = -1.0,
	onoffable=true,
	initCloaked = true,
	decloakOnFire = false,
	cloakTimeout = 5,
	selfDestructCountdown = 3*60,
	category = [[GROUND BUILDING RAIDABLE]],
	
}


return lowerkeys({
	--Temp
	["hivemind"] = Hivemind:New(),
	["aicore"] = AICore:New(),
	
})
