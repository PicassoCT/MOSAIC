-- Guns down Sattelites and project launches with in the sector

--Guns up com-sattelites and scan-sattelites

--NimRod_Railgun_SatelliteLauncher


local Noone_UplinkLaser = Building:New{
	corpse				= "",
	maxDamage           = 500,
	mass                = 500,
	buildCostEnergy     = 5,
	buildCostMetal      = 5,
	explodeAs			= "none",




	YardMap ="oooo oooo oooo oooo ",
	MaxSlope 					= 50,

	footprintX = 4,
	footprintZ = 4,
	
	EnergyStorage = 0,
	EnergyUse = 0,
	MetalStorage = 0,
	MetalUse = 3,
	EnergyMake = 0, 
	MakesMetal = 0, 
	MetalMake = 0,	
	
	
	script 					= "noonescript.lua",
	objectName        	= "noone.s3o",
	name = "Noone",
	description = "Uplinklaser  <Com with Satellites / blind Scansatellites>",

	
	customparams = {
		helptext		= "Noone Uplinklaser",
		baseclass		= "Building", -- TODO: hacks
    },
	
		buildoptions = 
	{
		
	},
	

	}



return lowerkeys({
	--Temp
	["noone"] = Noone_UplinkLaser:New(),
	
})