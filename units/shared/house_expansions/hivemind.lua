local Hivemind = Building:New{
	corpse				= "",
	maxDamage           = 500,
	mass                = 500,
	name = "Hivemind",
	description = " humans linked together into a supra-intelligence <Allows use of SlowMotion>",
	buildPic = "hivemind.png",
	iconType ="hivemind",
	buildTime = 25,
	buildCostMetal      = 150,
	buildCostEnergy     = 50,
	EnergyStorage = 0,
	EnergyUse = 0,
	MetalStorage = 5000,

	EnergyMake = 2.5, 
	MakesMetal = 5, 
	MetalMake = 0,	
	
	acceleration = 0,
	
	explodeAs			= "none",
	buildingMask = 8,
	MaxSlope 					= 50,

	footprintX = 1,
	footprintZ = 1,
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
	category = [[GROUND BUILDING RAIDABLE]],


}
local AICore = Building:New{
	corpse				= "",
	maxDamage           = 500,
	mass                = 500,
	name = "AI",
	description = " supra intelligent machine <Allows use of SlowMotion>",
	buildPic = "ai.png",
	iconType ="ai",
	buildTime = 25,
	buildCostMetal      = 150,
	buildCostEnergy     = 50,
	EnergyStorage = 0,
	EnergyUse = 0,
	MetalStorage = 5000,

	EnergyMake = 2.5, 
	MakesMetal = 5, 
	MetalMake = 0,	
	
	acceleration = 0,
	
	explodeAs			= "none",
	buildingMask = 8,
	MaxSlope 					= 50,

	footprintX = 1,
	footprintZ = 1,
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
	category = [[GROUND BUILDING RAIDABLE]],


}


return lowerkeys({
	--Temp
	["hivemind"] = Hivemind:New(),
	["aicore"] = AICore:New(),
	
})