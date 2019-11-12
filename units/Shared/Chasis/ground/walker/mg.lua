local ground_walker_mg = Walker:New{
	name = "Weevil",
	description = "Walker <spot-class>",
	
	corpse				= "",
	maxDamage = 800,
	mass = 600,
	buildCostEnergy = 0,
	buildCostMetal = 5000,
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
	script 			= "groundwalkerscript.lua",
	objectName 	= "ground_walker_mg.dae",

	usepiececollisionvolumes = true,
	customparams = {
		helptext		= "Military Tank",
		baseclass		= "Tank", -- TODO: hacks
	},
	
				weapons = {
				[1]={name  = "tankcannon",
					onlyTargetCategory = [[BUILDING GROUND]],
					},
					
		},	
}


return lowerkeys({
	["ground_walker_mg"]	= ground_walker_mg:New(),

	
})