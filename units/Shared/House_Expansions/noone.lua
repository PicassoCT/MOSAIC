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
	MetalStorage = 1500,
	MetalUse = 3,
	EnergyMake = 0, 
	MakesMetal = 0, 
	MetalMake = 0,	
	
	
	script 					= "noonescript.lua",
	objectName        	= "noone.s3o",
	name = "Noone",
	description = "Uplinklaser  <Com with Satellites / blind scansattelites>",

	canCloak =true,
	cloakCost=0.0001,
	ActivateWhenBuilt=1,
	cloakCostMoving =0.0001,
	minCloakDistance = 0,
	onoffable=true,
	initCloaked = true,
	decloakOnFire = true,
	cloakTimeout = 5,

	customparams = {
		helptext		= "Noone Uplinklaser",
		baseclass		= "Building", -- TODO: hacks
    },
	
		buildoptions = 
	{
		
	},
	
		weapons={
			[1]={name  = "odysseuslaser",
				onlyTargetCategory = [[SATELLITE AIR]],
			},
		},	


	}



return lowerkeys({
	--Temp
	["noone"] = Noone_UplinkLaser:New(),
	
})