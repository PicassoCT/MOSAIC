local ground_turret_hedgehog = Turret:New{
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
	script 			= "ground_turret_hedgehog_script.lua",
	objectName 		= "ground_turret_hedgehog.dae",
	buildPic 		= "ground_turret_spyder.png",
	iconType 		= "ground_turret_spyder",
	
	usepiececollisionvolumes = true,
	customparams = {
		baseclass		= "Truck", -- TODO: hacks
		normaltex = "unittextures/component_atlas_normal.dds",
	},
	
	weapons = {			
				[1]={name  = "hedgehog",
					onlyTargetCategory = [[BUILDING GROUND]],
					},					
			},	
}


return lowerkeys({
	["ground_turret_hedgehog"]	= ground_turret_hedgehog:New(),

	
})