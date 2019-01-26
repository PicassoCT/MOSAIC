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
	description = " attacks a remote target with a ICBM - ending the game ",


	
	customparams = {
		helptext		= "Weapon Launcher",
		baseclass		= "Building", -- TODO: hacks
    },
	
		buildoptions = 
	{
		"launcherstep"
	},
}

return lowerkeys(
	{
	["launcher"] = Launcher:New()	
	}
)