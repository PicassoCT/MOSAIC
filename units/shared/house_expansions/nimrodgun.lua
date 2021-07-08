-- Guns down Sattelites and project launches with in the sector

--Guns up com-sattelites and scan-sattelites

--NimRod_Railgun_SatelliteLauncher


local NimRodGun = Building:New{
	corpse				= "",
	maxDamage           = 500,
	mass                = 500,
	buildCostEnergy     = 3500,
	buildCostMetal      = 1500,
	explodeAs			= "none",
	buildTime =    60,
	
	MetalStorage = 2500,
	name = "Nimrod",
	description = " railgun and orbital launch system <launches satellites /destroys heavy units>",
showNanoFrame= true,

	Builder = true,
	nanocolor=[[0.20 0.411 0.611]],--
	CanReclaim=false,	
	workerTime = 0.065,
	buildDistance = 1,
	terraformSpeed = 1,
	YardMap =[[	oooooooo
				oooooooo
				oooooooo
				oooooooo
				oooooooo
				oooooooo
				oooooooo
				oooooooo]],


	
	MaxSlope 					= 50,
	buildingMask = 8,
	footprintX = 8,
	footprintZ = 8,
	selfDestructCountdown = 2*60,
	
	script 					= "nimrodscript.lua",
	objectName        	= "nimrod.dae",
	customParams        = {
		normaltex = "unittextures/component_atlas_normal.dds",
	},
	buildPic = "nimrod.png",
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
		"satelliteanti",
		"satellitegodrod"
	},
	
	fireState= 1,
	category = [[GROUND BUILDING RAIDABLE]],

	weapons={
			[1]={name  = "railgun",
				onlyTargetCategory = [[GROUND]], --GROUND BUILDING 
			},
			[2]={name  = "orbitalrailgun",
				onlyTargetCategory = [[ORBIT]], --GROUND BUILDING 
			},			
		},	
	}



return lowerkeys({
	--Temp
	["nimrod"] = NimRodGun:New(),
	
})