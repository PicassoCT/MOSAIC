-- Guns down Sattelites and project launches with in the sector

--Guns up com-sattelites and scan-sattelites

--NimRod_Railgun_SatelliteLauncher


local NooneLaser = Human:New{
	corpse				= "",
	maxDamage           = 500,
	mass                = 1,
	buildCostEnergy     = 5,
	buildCostMetal      = 5,
	explodeAs			= "none",
	buildingMask = 8,
	MovementClass = "Default2x2",


	MaxSlope 					= 50,

	footprintX = 1,
	footprintZ = 1,
	
	EnergyStorage = 0,
	EnergyUse = 0,
	MetalStorage = 1500,
	MetalUse = 3,
	EnergyMake = 0, 
	MakesMetal = 0, 
	MetalMake = 0,	
	
	
	script 					= "noonescript.lua",
	objectName        	= "noone.s3o",
	name = "Noone",
	description = "Satellite Destroying Laser",


	cantBeTransported  = false,
	category = [[ORBIT]],

	customparams = {
		helptext		= "Noone Uplinklaser",
		baseclass		= "Satellite", -- TODO: hacks
    },
	
	
		weapons = {
		[1]={name  = "noonelaser",-- who blinded you ? Noone.
			onlyTargetCategory = [[ORBIT]],
			},
					
		},


	}



return lowerkeys({
	--Temp
	["noone"] = NooneLaser:New(),
	
})