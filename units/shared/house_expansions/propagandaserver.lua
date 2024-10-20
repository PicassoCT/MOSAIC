local Propagandaserver = Building:New{
	corpse				= "",
	maxDamage           = 1000,
	mass                = 5000,
	name = "Propagandaserver",
	description = "earns your team money/material by spreading propaganda",
	buildPic = "propagandaserver.png",
	buildTime = 30,
	buildCostMetal      = 1000,
	buildCostEnergy     = 1000,
	EnergyStorage = 2500,
	EnergyUse = 0,
	MetalStorage = 2500,

	EnergyMake = 10, 
	MetalMake = 5,	 
	
	acceleration = 0,

	footprintX = 1,
	footprintZ = 1,	
	explodeAs = "none",
	buildingMask = 8,
	maxSlope = 50.0,
	levelGround = false,
	blocking =false,

	script 			= "propagandaserverscript.lua",
	objectName        	= "propagandaserver.dae",
		customParams        = {
		normaltex = "unittextures/propagandaserver_normal.dds",
	},

	usepiececollisionvolumes = false,
  	collisionVolumeType = "box",
  	collisionvolumescales = "100 70 100",
  	collisionVolumeOffsets  = {0.0, 30.0,  0.0},

	selfDestructCountdown = 2*60,
	showNanoFrame= true,
	nanocolor=[[0.20 0.411 0.611]],
	canCloak =true,
	cloakCost=0.0001,
	ActivateWhenBuilt=1,
	cloakCostMoving =0.0001,
	minCloakDistance = -1.0,
	onoffable=true,
	initCloaked = true,
	decloakOnFire = false,
	cloakTimeout = 5,
	category = [[GROUND BUILDING RAIDABLE]],
}


return lowerkeys({
	["propagandaserver"] = Propagandaserver:New()	
})