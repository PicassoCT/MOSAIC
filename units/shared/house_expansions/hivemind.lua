local Hivemind = Building:New{
	corpse				= "",
	maxDamage           = 1500,
	mass                = 500,
	name = "Hivemind",
	description = " humans linked together into a supra-intelligence <Allows use of SlowMotion>",
	buildPic = "hivemind.png",
	iconType ="hivemind",
	buildTime = 3*60,
	buildCostMetal      = 2500,
	buildCostEnergy     = 500,

	EnergyUse = 10,
	MetalStorage = 0,

	EnergyMake = 0, 
	MakesMetal = 0, 
	MetalMake = 0,	
	
	acceleration = 0,
	
	explodeAs			= "none",
	buildingMask = 8,
	MaxSlope 					= 100,

	footprintX = 8,
	footprintZ = 8,
	script 			= "hivemindscript.lua",
	objectName        	= "hivemind.dae",
		customParams        = {
		normaltex = "unittextures/propagandaserver_normal.dds",
	},
	
	showNanoFrame= true,
	nanocolor=[[0.20 0.411 0.611]],
	canCloak =true,
	cloakCost=0.0001,
	ActivateWhenBuilt= false,
	cloakCostMoving =0.0001,
	minCloakDistance = 0,
	onoffable=true,
	initCloaked = true,
	decloakOnFire = true,
	cloakTimeout = 5,
	selfDestructCountdown = 3*60,
	category = [[GROUND BUILDING RAIDABLE]],


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

	EnergyUse = 10,
	MetalStorage = 0,

	EnergyMake = 0, 
	MakesMetal = 0, 
	MetalMake = 0,	
	
	acceleration = 0,
	
	explodeAs			= "none",
	buildingMask = 8,
	MaxSlope 					= 50,

	footprintX = 8,
	footprintZ = 8,
	script 			= "aicorescript.lua",
	objectName        	= "aicore.dae",
		customParams        = {
		normaltex = "unittextures/propagandaserver_normal.dds",
	},
	
	showNanoFrame= true,
	nanocolor=[[0.20 0.411 0.611]],
	canCloak =true,
	cloakCost=0.0001,
	ActivateWhenBuilt= false,
	cloakCostMoving =0.0001,
	minCloakDistance = 0,
	onoffable=true,
	initCloaked = true,
	decloakOnFire = true,
	cloakTimeout = 5,
	selfDestructCountdown = 3*60,
	category = [[GROUND BUILDING RAIDABLE]],


}


return lowerkeys({
	--Temp
	["hivemind"] = Hivemind:New(),
	["aicore"] = AICore:New(),
	
})