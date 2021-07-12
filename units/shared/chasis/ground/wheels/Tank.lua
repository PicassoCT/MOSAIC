local ground_tank_day = Tank:New{
	name = "Tank",
	description = "Heavily Armoured <Redundant Vehicle>",
	
	corpse				= "",
	maxDamage = 1250,
	mass = 5000,
	buildCostEnergy = 5000,
	buildCostMetal = 5000,
	buildTime = 5*60,
	
	canMove = true,
	canAttack = true,
	canGuard = true,
	canStop = true,
	fireState= 1,
	
	explodeAs			= "none",
	maxVelocity		= 3.15*0.5 , --14.3, --86kph/20
	maxReverseVelocity=  1.15,
	acceleration = 0.7,
	brakeRate = 0.1,
	turninplace		= true,
	footprintX = 5,
	footprintZ = 5,
	script 			= "tankscript.lua",
	objectName 	= "ground_tank_day.dae",
	buildPic = "tank.png",

	LeaveTracks = true,
	trackType ="arm_acv_tracks",
	trackStrength=32,
	trackWidth =64,
	trackOffset =0,

	iconType ="ground_tank_day",
	collisionVolumeType = "box",
	collisionvolumescales = "70 50 70",
	
	customparams = {
		normaltex = "unittextures/tank_day_normal.dds",
		helptext		= "Military Tank",
		baseclass		= "Tank", -- TODO: hacks
	},
	
	weapons = {
				[1]={name  = "tankcannon",
					onlyTargetCategory = [[BUILDING GROUND]],
					},
					
		},	
}

 ground_tank_night = Tank:New{
		name = "Tank",
	description = "Heavily Armoured <Redundant Vehicle>",
	
	corpse				= "",
	maxDamage = 1500,
	mass = 5000,
	buildCostEnergy = 5000,
	buildCostMetal = 5000,
	buildTime = 5*60,
	
	canMove = true,
	canAttack = true,
	canGuard = true,
	canStop = true,
	fireState= 1,	

	explodeAs			= "none",
	maxVelocity		= 3.15*0.5 , --14.3, --86kph/20
	maxReverseVelocity=  1.15,
	acceleration = 0.7,
	brakeRate = 0.1,
	turninplace		= true,
	footprintX = 5,
	footprintZ = 5,
	script 			= "tankscript.lua",
	objectName 	= "ground_tank_night.dae",
	buildPic = "tank.png",

	LeaveTracks = true,
	trackType ="arm_acv_tracks",
	trackStrength=32,
	trackWidth =64,
	trackOffset =0,

	iconType = "ground_tank_night",
	
	collisionVolumeType = "box",
	collisionvolumescales = "70 50 70",
	
	customparams = {
		normaltex = "unittextures/tank_day_normal.dds",
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
	["ground_tank_night"]	= ground_tank_night:New(),
	["ground_tank_day"]	= ground_tank_day:New()

	
})