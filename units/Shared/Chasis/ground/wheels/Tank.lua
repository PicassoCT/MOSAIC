local ground_tank_day = Tank:New{
	name = "Tank",
	description = "Heavily Armoured <Redundant Vehicle>",
	
	corpse				= "",
	maxDamage = 1500,
	mass = 5000,
	buildCostEnergy = 0,
	buildCostMetal = 5000,
	explodeAs			= "none",
	buildTime = 5*60,
	
	--maxReverseVelocity= 2.15,
	acceleration = 0.7,
	brakeRate = 0.1,
	turninplace		= true,
	footprintX = 5,
	footprintZ = 5,
	script 			= "tankscript.lua",
	objectName 	= "ground_tank_day.dae",

	collisionVolumeType = "box",
	collisionvolumescales = "70 50 70",
	
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

local ground_tank_night = Tank:New{
		name = "Tank",
	description = "Heavily Armoured <Redundant Vehicle>",
	
	corpse				= "",
	maxDamage = 1500,
	mass = 5000,
	buildCostEnergy = 0,
	buildCostMetal = 5000,
	buildTime = 5*60,
	
	explodeAs			= "none",
	maxVelocity		= 3.15*0.5 , --14.3, --86kph/20
	--maxReverseVelocity= 2.15,
	acceleration = 0.7,
	brakeRate = 0.1,
	turninplace		= true,
	footprintX = 5,
	footprintZ = 5,
	script 			= "tankscript.lua",
	objectName 	= "ground_tank_night.dae",

	collisionVolumeType = "box",
	collisionvolumescales = "70 50 70",
	
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
	["ground_tank_night"]	= ground_tank_night:New(),
	["ground_tank_day"]	= ground_tank_day:New()

	
})