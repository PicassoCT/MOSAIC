local Launcher = Building:New{
	corpse				= "",
	maxDamage           = 500,
	mass                = 500,
	buildCostEnergy     = 5,
	buildCostMetal      = 5,
	explodeAs			= "none",

	buildtime			 = 2*60,
	buildPic = "launcher.png",
	Builder = true,
	nanocolor=[[0.20 0.411 0.611]],--
	CanReclaim=false,	
	workerTime = 0.005,
	YardMap ="oooo oooo oooo oooo ",
	MaxSlope 					= 50,

	footprintX = 4,
	footprintZ = 4,
	buildingMask = 8,
	
	script 					= "launcherscript.lua",
	objectName        	= "launcher.dae",
		customParams        = {
		normaltex = "unittextures/component_atlas_normal.png",
	},
	name = "Launcher",
	description = " ends the game with a MOSA ICBM launch",

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
		helptext		= "Weapon Launcher",
		baseclass		= "Building", -- TODO: hacks
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