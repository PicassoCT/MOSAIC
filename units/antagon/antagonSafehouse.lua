local AntagonSafeHouse = Building:New{
	corpse				= "",
	maxDamage           = 1000,
	mass                = 500,

	buildTime = 15,
	MaxSlope 					= 50,
	explodeAs			= "none",
	NoWeapon=true,
	name = "Safehouse",
	buildPic = "antagonsafehouse.png",
	iconType					= "antagonsafehouse",
	description= " base of operation <recruits Agents/ builds upgrades>",
	
	Builder = true,
	nanocolor=[[0.20 0.411 0.611]],
	CanReclaim=false,	
	workerTime = 1,
	buildDistance = 1,
	terraformSpeed = 1,
	YardMap ="oooooooo oooooooo oooooooo oooooooo oooooooo oooooooo oooooooo oooooooo",
	buildingMask = 8,
	footprintX = 8,
	footprintZ = 8,
	showNanoFrame= true,

	buildCostEnergy     = 2000,
	buildCostMetal      = 2000,
	
	EnergyStorage = 1000,
	EnergyUse = 0,
	MetalStorage = 1000,
	MetalUse = 1,
	EnergyMake = 0, 
	MakesMetal = 0, 
	MetalMake = 0,	
	
	canCloak =true,
	cloakCost=0.0001,
	ActivateWhenBuilt=1,
	cloakCostMoving =0.0001,
	minCloakDistance = 0,
	onoffable=true,
	initCloaked = true,
	decloakOnFire = true,
	cloakTimeout = 5,

	
	script = "safehousescript.lua",
	objectName = "safehouse.dae",
	
	customparams = {
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
		"hivemind",
		"launcher"
		},
	category = [[GROUND BUILDING RAIDABLE]],

}


return lowerkeys({

	["antagonsafehouse"] = AntagonSafeHouse:New(),
	
})