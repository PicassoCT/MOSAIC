local Launcher = Building:New{
	corpse				= "",
	maxDamage           = 2000,
	mass                = 500,
	buildCostEnergy     = 5000,
	buildCostMetal      = 5000,
	explodeAs			= "none",

	buildtime			 = 60,
	workerTime = 1.0,
	buildPic = "launcher.png",
	iconType = "launcher",
	Builder = true,
	nanocolor=[[0.20 0.411 0.611]],--
	CanReclaim=false,	
	YardMap ="oooo oooo oooo oooo ",
	MaxSlope 					= 50,

	footprintX = 4,
	footprintZ = 4,
	buildingMask = 8,
	
	script 					= "launcherscript.lua",
	objectName        	= "launcher.dae",

	name = "Launcher",
	description = "Build icmb-stages to win the game",

	canCloak =true,
	cloakCost=0.0001,
	ActivateWhenBuilt=1,
	cloakCostMoving =0.0001,
	minCloakDistance = 1.0,
	onoffable=true,
	initCloaked = true,
	decloakOnFire = true,
	cloakTimeout = 5,
	unitRestricted = 2,

	usepiececollisionvolumes = false,
  	collisionVolumeType = "box",
  	collisionvolumescales = "100 70 100",
  	collisionVolumeOffsets  = {0.0, 30.0,  0.0},
	
	customparams = {
		helptext		= "Weapon Launcher",
		baseclass		= "Building", -- TODO: hacks
		normaltex = "unittextures/component_atlas_normal.dds",
    },
	
		buildoptions = 
	{
		"launcherstep"
	},
		category = [[GROUND BUILDING RAIDABLE]],

}

return lowerkeys(
	{
	["launcher"] = Launcher:New()	
	}
)