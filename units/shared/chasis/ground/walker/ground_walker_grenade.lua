local ground_walker_grenade = Walker:New{
	name = "Weevil",
	description = "Walker <Self Guided Mine Drone>",
	
	corpse				= "",
	maxDamage = 800,
	mass = 900,
	buildCostEnergy = 500,
	buildCostMetal =  500,
	buildTime = 45,
	explodeAs			= "none",
	maxVelocity		= 3.15 , --14.3, --86kph/20
	maxReverseVelocity = 3.15*0.5,
	acceleration = 0.7,
	brakeRate = 0.1,
	turninplace		= true,
	sightDistance = 300,
	reclaimable=false,
	Builder = false,
	CanAttack = true,
	CanGuard = true,
	CanMove = true,
	CanPatrol = true,
	CanStop = true,
	fireState=1,
	footprintX = 2,
	footprintZ = 2,
	script 			= "groundwalkerscript.lua",
	objectName 	= "ground_walker_grenade.dae",
	buildPic = "ground_walker_mg.png",
	iconType ="ground_walker_mg",
	strafeToAttack = true,

	category = "GROUND",
	noChaseCategory = "NOTARGET",

	usepiececollisionvolumes = true,
	customparams = {
		helptext		= "Military Tank",
		baseclass		= "Tank", -- TODO: hacks
		normaltex = "unittextures/component_atlas_normal.dds",
	},
	
	weapons = {
	[1]={name  = "smartminedrone",
		onlyTargetCategory = [[BUILDING GROUND VEHICLE]],
		},			
	},	
}

return lowerkeys({
	["ground_walker_grenade"]	= ground_walker_grenade:New(),	
})