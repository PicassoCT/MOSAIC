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
	sightDistance = 50,
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

	buildingMask = 8,
	footprintX = 8,
	footprintZ = 8,
	maxSlope = 50.0,
	levelGround = false,
	blocking =false,
	
	selfDestructCountdown = 2*60,

	usepiececollisionvolumes = false,
  	collisionVolumeType = "box",
  	collisionvolumescales = "100 70 100",
  	collisionVolumeOffsets  = {0.0, 30.0,  0.0},
	
	script 					= "nimrodscript.lua",
	objectName        	= "nimrod.dae",

	buildPic = "nimrod.png",
	canCloak =true,
	cloakCost=0.0001,
	ActivateWhenBuilt=1,
	cloakCostMoving =0.0001,
	minCloakDistance = -1.0,
	onoffable=true,
	initCloaked = true,
	decloakOnFire = true,
	cloakTimeout = 5,
	
	customparams = {
		helptext		= "Nimrod Railgun",
		baseclass		= "Building", -- TODO: hacks
		normaltex = "unittextures/component_atlas_normal.dds",
    },
	
		buildoptions = 
	{
		"satellitescan",
		"satelliteanti",
		"satellitegodrod",
		"air_plane_artillery"
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