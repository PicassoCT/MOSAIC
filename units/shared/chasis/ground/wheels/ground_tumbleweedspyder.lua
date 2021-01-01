local ground_tumbleweedspyder = Walker:New{
	name = "TumbleWeedSpyder",
	description = "2 mines in rolling configuration <spot-class>",
	
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
	turninplace		= true,
	reclaimable=false,
	Builder = false,
	CanAttack = true,
	CanGuard = true,
	CanMove = true,
	CanPatrol = true,
	CanStop = true,

	footprintX = 2,
	footprintZ = 2,
	script 			= "placeholderscript.lua",
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
				[1]={name  = "tankcannon",
					onlyTargetCategory = [[BUILDING GROUND]],
					},
					
		},	
}


return lowerkeys({
	["ground_tumbleweedspyder"]	= ground_tumbleweedspyder:New(),

	
})