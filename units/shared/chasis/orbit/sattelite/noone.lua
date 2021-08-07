-- Guns down Sattelites and project launches with in the sector

--Guns up com-sattelites and scan-sattelites

--NimRod_Railgun_SatelliteLauncher


local NooneLaser = Human:New{
	name = "Noone",
	description = "Satellite Destroying Laser",

	corpse				= "",
	maxDamage           = 500,
	mass                = 1,
	buildCostEnergy     = 1500,
	buildCostMetal      = 500,
	explodeAs			= "none",
	buildingMask = 8,
	MovementClass = "AIRUNIT",
	maxVelocity				= 7.15, --14.3, --86kph/20
	acceleration   		 	= 1.7,
	brakeRate      		 	= 0.1,
	turninplace				= true,
	buildTime= 45,
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
	
	fireState = 2,
	script 					= "noonescript.lua",
	objectName        	= "orbit_turret_noone.dae",


	cantBeTransported  = false,
	canAttack = true,
	canGuard = true,
	canMove = true,
	category = [[ORBIT]],

	customparams = {
		helptext		= "Noone Uplinklaser",
		baseclass		= "Satellite", -- TODO: hacks
		normaltex = "unittextures/component_atlas_normal.dds",
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