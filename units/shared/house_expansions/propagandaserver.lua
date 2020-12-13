local Propagandaserver = Building:New{
	corpse				= "",
	maxDamage           = 1000,
	mass                = 500,
	name = "Propagandaserver",
	description = "earns your team money/material by spreading propaganda",
	buildPic = "propagandaserver.png",
	buildTime = 25,
	buildCostMetal      = 1000,
	buildCostEnergy     = 1000,
	EnergyStorage = 1000,
	EnergyUse = 0,
	MetalStorage = 2500,

	EnergyMake = 5, 
	MakesMetal = 5, 
	MetalMake = 0,	 
	
	acceleration = 0,
	
	explodeAs = "none",
	buildingMask = 8,
	MaxSlope = 50,

	footprintX = 1,
	footprintZ = 1,
	script 			= "propagandaserverscript.lua",
	objectName        	= "propagandaserver.dae",
		customParams        = {
		normaltex = "unittextures/propagandaserver_normal.dds",
	},

	showNanoFrame= true,
	nanocolor=[[0.20 0.411 0.611]],
	canCloak =true,
	cloakCost=0.0001,
	ActivateWhenBuilt=1,
	cloakCostMoving =0.0001,
	minCloakDistance = 0,
	onoffable=true,
	initCloaked = true,
	decloakOnFire = true,
	cloakTimeout = 5,
	category = [[GROUND BUILDING RAIDABLE]],
}


return lowerkeys({
	["propagandaserver"] = Propagandaserver:New()	
})