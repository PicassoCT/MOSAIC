local ProtagonSafeHouse = Building:New{
	corpse				= "",
	maxDamage           = 500,
	mass                = 500,

	buildTime = 15,
	explodeAs			= "none",


	Builder = true,
	nanocolor=[[0 0 0]], --
	CanReclaim=false,	
	workerTime = 0.05,
	buildDistance = 1,
	terraformSpeed = 1,
	YardMap ="oooo oooo oooo oooo ",
	MaxSlope 					= 50,

	footprintX = 4,
	footprintZ = 4,
	
	buildCostEnergy     = 0,
	buildCostMetal      = 500,
	
	EnergyStorage = 0,
	EnergyUse = 0,
	MetalStorage = 0,
	MetalUse = 1,
	EnergyMake = 0, 
	MakesMetal = 0, 
	MetalMake = 0,	
	
	
	script 			= "safehousescript.lua",
	objectName        	= "house_safehouse.s3o",


	
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
	"assembly"
	},
	
	category=[[LAND BUILDING]],
}


return lowerkeys({
	--Temp
	["protagonsafehouse"] = ProtagonSafeHouse:New(),
	
})