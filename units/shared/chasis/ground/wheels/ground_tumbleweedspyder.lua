local ground_tumbleweedspyder = Walker:New{
	name = "TumbleWeedSpyder",
	description = "2 mines in rolling configuration",
	
	corpse				= "",
	maxDamage = 800,
	mass = 600,
	buildCostEnergy = 750,
	buildCostMetal = 250,
	buildTime = 15,
	explodeAs			= "none",
	maxVelocity		= 3.15*0.5 , --14.3, --86kph/20
	--maxReverseVelocity= 2.15,
	acceleration = 0.7,
	brakeRate = 0.1,
	turninplace		= false,
	reclaimable=false,
	Builder = false,
	CanAttack = true,
	CanGuard = true,
	CanMove = true,
	CanPatrol = true,
	CanStop = true,
	onoffable = true,
	activateWhenbuilt = false,

	footprintX = 2,
	footprintZ = 2,
	script 			= "tubleweedspyderscript.lua",
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
				[1]={name  = "ssied",
					onlyTargetCategory = [[BUILDING GROUND]],
					},
				[2]={name  = "s16rocket",
					onlyTargetCategory = [[BUILDING GROUND]],
					},
				[3]={name  = "s16rocket",
					onlyTargetCategory = [[BUILDING GROUND]],
					},
					
		},	
}


return lowerkeys({
	["ground_tumbleweedspyder"]	= ground_tumbleweedspyder:New(),

	
})