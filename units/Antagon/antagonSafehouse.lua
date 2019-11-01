local AntagonSafeHouse = Building:New{
	corpse				= "",
	maxDamage           = 500,
	mass                = 500,

	buildTime = 15,
	MaxSlope 					= 50,
	explodeAs			= "none",
	NoWeapon=true,
	name = "Safehouse",
	description= " base of operation <recruits Agents/ builds upgrades>",
	
	Builder = true,
	nanocolor=[[0 0 0]], --
	CanReclaim=false,	
	workerTime = 0.1,
	buildDistance = 1,
	terraformSpeed = 1,
	YardMap ="oooo oooo oooo oooo ",
	buildingMask = 8,
	footprintX = 4,
	footprintZ = 4,

	buildCostEnergy     = 0,
	buildCostMetal      = 500,
	
	EnergyStorage = 0,
	EnergyUse = 0,
	MetalStorage = 2500,
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
	
	script 			= "safehousescript.lua",
	objectName        	= "safehouse.dae",
	
	customparams = {
		helptext		= "Civilian Building",
		baseclass		= "Building", -- TODO: hacks
    },
	
	buildoptions={
	"operativeasset",
	"operativepropagator",
	"civilianagent",
	
	"nimrod",
	"noone",
	"propagandaserver",
	"assembly",
	"launcher"
	},
	
	category = [[GROUND BUILDING ARRESTABLE]]
}


return lowerkeys({

	["antagonsafehouse"] = AntagonSafeHouse:New(),
	
})