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


	footprintX = 4,
	footprintZ = 4,
	script 					= "nimrodscript.lua",
	objectName        	= "nimrod.s3o",


	
	customparams = {
		helptext		= "Nimrod Railgun",
		baseclass		= "Building", -- TODO: hacks
    },
	
		buildoptions = 
	{
		"scansatellite",
		"comsatellite"
	},
	weapons={
			[1]={name  = "railgun",
				onlyTargetCategory = [[LAND BUILDING]],
			},
		},	

	}



return lowerkeys({
	--Temp
	["nimrod"] = NimRodGun:New(),
	
})