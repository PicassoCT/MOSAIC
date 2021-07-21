local ground_walker_mg = Walker:New{
	name = "Weevil",
	description = "Walker Machine Gun<spot-class>",
	
	corpse = "",
	maxDamage = 800,
	mass = 600,
	buildCostEnergy = 750,
	buildCostMetal = 1000,
	buildTime = 45,
	explodeAs = "none",
	maxVelocity		= 3.15 , --14.3, --86kph/20
	maxReverseVelocity= 3.15*0.5,
	turnRate			= 900,
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
	fireState=1,
	footprintX = 2,
	footprintZ = 2,
	script 			= "groundwalkerscript.lua",
	objectName 	= "ground_walker_mg.dae",
	buildPic = "ground_walker_mg.png",
	iconType ="ground_walker_mg",
	strafeToAttack = true,

	usepiececollisionvolumes = true,
	customparams = {
		normaltex = "unittextures/component_atlas_normal.dds",
		helptext		= "Military Tank",
		baseclass		= "Tank", -- TODO: hacks
	},

	sfxtypes = {
		explosiongenerators = {
								"custom:groundwalkermuzzle",
								"custom:shells",
							  },
				},
				

	category = "GROUND",
	noChaseCategory = "AIR NOTARGET",
	
				weapons = {

				[1]={name  = "submachingegun",
				onlyTargetCategory = [[BUILDING GROUND]], 
				},
				[2]={name  = "aamachinegun",
				onlyTargetCategory = [[AIR]],
				turret = true
				},				
		},	
}


return lowerkeys({
	["ground_walker_mg"]	= ground_walker_mg:New(),

})