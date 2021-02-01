local ground_tumbleweed_deployed = Turret:New{
	name = "TumbleWeedSpyder",
	description = "2 mines deployed",
	
	corpse				= "",
	maxDamage = 800,
	mass = 600,
	buildCostEnergy = 750,
	buildCostMetal = 250,
	buildTime = 15,
	explodeAs			= "none",

	
	reclaimable=false,
	Builder = false,
	CanAttack = true,
	CanGuard = true,

	footprintX = 2,
	footprintZ = 2,
	script 			= "tumbleweedspyder_deployedscript.lua",
	objectName 	= "ground_turret_spyder.dae",
	buildPic = "ground_turret_spyder.png",
	iconType ="ground_turret_spyder",
	customParams        = {
		normaltex = "unittextures/component_atlas_normal.dds",
	},

	usepiececollisionvolumes = true,
	customparams = {
		baseclass		= "Truck", -- TODO: hacks
	},
	
				weapons = {
			
				[1]={name  = "s16rocket",
					onlyTargetCategory = [[BUILDING GROUND]],
					},
				[2]={name  = "s16rocket",
					onlyTargetCategory = [[BUILDING GROUND]],
					},
					
		},	
}


return lowerkeys({
	["ground_tumbleweed_deployed"]	= ground_tumbleweed_deployed:New(),

	
})