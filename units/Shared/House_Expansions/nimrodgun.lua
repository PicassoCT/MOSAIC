-- Guns down Sattelites and project launches with in the sector

--Guns up com-sattelites and scan-sattelites

--NimRod_Railgun_SatelliteLauncher


local NimRodGun = Building:New{
	corpse				= "",
	maxDamage           = 500,
	mass                = 500,
	buildCostEnergy     = 5,
	buildCostMetal      = 5,
	explodeAs			= "none",

	MetalStorage = 2500,


	Builder = true,
	nanocolor=[[0 0 0]], --
	CanReclaim=false,	
	workerTime = 0.005,
	buildDistance = 1,
	terraformSpeed = 1,
	YardMap ="oooo oooo oooo oooo ",
	MaxSlope 					= 50,
	buildingMask = 8,
	footprintX = 4,
	footprintZ = 4,
	
	script 					= "nimrodscript.lua",
	objectName        	= "nimrod.dae",

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
		helptext		= "Nimrod Railgun",
		baseclass		= "Building", -- TODO: hacks
    },
	
		buildoptions = 
	{
		"satellitescan",
		"satellitecom"
	},
	weapons={
			[1]={name  = "railgun",
				onlyTargetCategory = [[GROUND BUILDING]],
			},
		},	

	}



return lowerkeys({
	--Temp
	["nimrod"] = NimRodGun:New(),
	
})