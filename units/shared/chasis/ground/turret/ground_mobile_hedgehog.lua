local ground_mobile_hedgehog = Turret:New{
	name = "ground_mobile_hegehog",
	description = "a mine going dormant",
	
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
	objectName 		= "ground_hedgehog.dae",
	buildPic 		= "ground_turret_spyder.png",
	iconType 		= "ground_turret_spyder",
	
	usepiececollisionvolumes = true,
	customparams = {
		baseclass		= "Truck", -- TODO: hacks
		normaltex = "unittextures/component_atlas_normal.dds",
	},
	
	weapons = {			
				[1]={
					name  = "hedgehog",
					onlyTargetCategory = [[BUILDING GROUND]],
					},					
			},	
}


return lowerkeys({
	["ground_mobile_hedgehog"]	= ground_mobile_hedgehog:New(),	
})