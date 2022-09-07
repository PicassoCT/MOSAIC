local AntagonSafeHouse = Building:New{
	corpse				= "",
	maxDamage           = 1000,
	mass                = 5000,

	buildTime 			= 15,
	MaxSlope 			= 100,
	explodeAs			= "none",
	name = "Safehouse",
	description= " base of operation <recruits Agents/ builds upgrades>",
	buildPic = "antagonsafehouse.png",
	iconType					= "antagonsafehouse",
	
	Builder = true,
	nanocolor=[[0.20 0.411 0.611]],
	CanReclaim=false,	
	canAssist = false,
	fullHealthFactory = true,
	workerTime = 1,
	showNanoSpray = false,
	canBeAssisted = false,
	buildDistance = 1,
	terraformSpeed = 1,
	YardMap ="oooooooo oooooooo oooooooo oooooooo oooooooo oooooooo oooooooo oooooooo",
	buildingMask = 8,
	footprintX = 8,
	footprintZ = 8,
	maxSlope = 50.0,
	levelGround = false,
	blocking =false,
	
	showNanoFrame= true,
	selfDestructCountdown = 5*60,

	buildCostEnergy     = 2000,
	buildCostMetal      = 2000,
	
	EnergyStorage = 1000,
	EnergyUse = 0,
	MetalStorage = 1000,
	MetalUse = 0,
	EnergyMake = 2.0, 
	MakesMetal = 0, 
	MetalMake = 2.0,	
	
	canCloak =true,
	cloakCost=0.0001,
	ActivateWhenBuilt=1,
	cloakCostMoving =0.0001,
	minCloakDistance = -1,
	onoffable=true,
	initCloaked = true,
	decloakOnFire = false,
	cloakTimeout = 5,

	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "100 80 100",
	collisionVolumeOffsets  = {0.0, 30.0,  0.0},

	script = "safehousescript.lua",
	objectName = "safehouse.dae",
	
	customParams = {
		normaltex = "unittextures/safehouse_normal.dds",
		helptext = "Civilian Building",
		baseclass = "Building", -- TODO: hacks
    },

    fireState = 1,
	
	buildoptions={
		"operativeasset",
		"operativepropagator",
		"civilianagent",
		"nimrod",
		"propagandaserver",
		"assembly",
		"launcher",
		"warheadfactory",
		"hivemind"
		},
	category = [[GROUND BUILDING RAIDABLE]],

}


return lowerkeys({

	["antagonsafehouse"] = AntagonSafeHouse:New(),
	
})
