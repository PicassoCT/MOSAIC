local MilitaryTruck = Truck:New{
	corpse				= "",
	maxDamage = 500,
	mass = 500,
	buildCostEnergy = 5,
	buildCostMetal = 5,
	explodeAs			= "none",
	--conType			= "infantry",
	maxVelocity		= 7.15, --14.3, --86kph/20
	--maxReverseVelocity= 2.15,
	acceleration = 1.7,
	brakeRate = 0.1,
	turninplace		= true,
	footprintX = 1,
	footprintZ = 1,
	script 			= "Truck.lua",
	objectName 	= "Truck.s3o",
	movementClass   	= "VEHICLE",
	
	customparams = {
		helptext		= "Military Truck/Technical",
		baseclass		= "Truck", -- TODO: hacks
	},
}

local CivilianTruck = Truck:New{
	corpse				= "",
	maxDamage = 500,
	mass = 500,
	buildCostEnergy = 5,
	buildCostMetal = 5,
	explodeAs			= "none",
	--conType			= "infantry",
	maxVelocity		= 7.15, --14.3, --86kph/20
	--maxReverseVelocity= 2.15,
		movementClass   	= "VEHICLE",
	acceleration = 1.7,
	brakeRate = 0.1,
	turninplace		= true,
	
	footprintX = 1,
	footprintZ = 1,
	script 			= "Truck.lua",
	objectName 	= "Truck.s3o",
	
	
	customparams = {
		helptext		= "Transportation Truck",
		baseclass		= "Truck", -- TODO: hacks
	},
}

return lowerkeys({
	--Temp
	["truck"]			 	= CivilianTruck:New(),
	["militarytruck"] 		= MilitaryTruck:New(),
	
})