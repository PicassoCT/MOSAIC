local Launcher = Building:New{
	corpse				= "",
	maxDamage           = 500,
	mass                = 500,
	buildCostEnergy     = 5,
	buildCostMetal      = 5,
	explodeAs			= "none",



	Builder = true,
	nanocolor=[[0 0 0]], --
	CanReclaim=false,	
	workerTime = 0.005,
	YardMap ="oooo oooo oooo oooo ",
	MaxSlope 					= 50,

	footprintX = 4,
	footprintZ = 4,
	
	script 					= "launcherscript.lua",
	objectName        	= "Launcher.s3o",
	name = "Launcher",
	description = " ends the game with a ICBM launch",


	
	customparams = {
		helptext		= "Weapon Launcher",
		baseclass		= "Building", -- TODO: hacks
    },
	
		buildoptions = 
	{
		"launcherstep"
	},
	category = [[LAND BUILDING]],
}

return lowerkeys(
	{
	["launcher"] = Launcher:New()	
	}
)