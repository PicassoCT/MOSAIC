local LaunchedICBM = Rocket:New{
	corpse				= "",
	maxDamage           = 256,
	mass                = 50000,
	buildCostEnergy     = 5,
	buildCostMetal      = 5,
	explodeAs			= "none",

	name = "MOSA ICBM",
	description= "launched Doomsdaydevice <Ends game if not intercepted>",

	
	script 				= "launchedicbmscript.lua",
	objectName        	= "launcherICBM.dae",
	--objectName        	= "launcherICBM.s3o",
	name = "MOSAICBM",
	description = " the end",
	iconType = "launcher",
	ActivateWhenBuilt=1,
	alwaysupright = true,


	
	customparams = {
		helptext		= "Flying Rocket",
		baseclass		= "Rocket", -- TODO: hacks
		normaltex = "unittextures/component_atlas_normal.dds",
    },

     sfxtypes = {
		explosiongenerators = {
							"custom:cruisemissiletrail"
							  },
				},
	

	category = [[ORBIT AIR]],
}

return lowerkeys(
	{
	["launchedicbm"] = LaunchedICBM:New()	
	}
)