local LaunchedICBM = Rocket:New{
	corpse				= "",
	maxDamage           = 1024,
	mass                = 50000,
	buildCostEnergy     = 5,
	buildCostMetal      = 5,
	explodeAs			= "none",



	footprintX = 1,
	footprintZ = 1,
	
	script 					= "launchedicbmscript.lua",
	objectName        	= "launchedICBM.s3o",
	name = "MOSAICBM",
	description = " the end",

	ActivateWhenBuilt=1,

	
	customparams = {
		helptext		= "Flying Rocket",
		baseclass		= "Rocket", -- TODO: hacks
    },
	

	category = [[ORBIT]],
}

return lowerkeys(
	{
	["launchedicbm"] = LaunchedICBM:New()	
	}
)