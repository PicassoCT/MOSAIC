local MilitaryTruck = Truck:New{
	corpse				= "",
	maxDamage = 1500,
	mass = 500,
	buildCostEnergy = 5,
	buildCostMetal = 5,
	explodeAs			= "none",
	--conType			= "infantry",
	maxVelocity		= 7.15*0.5 , --14.3, --86kph/20
	--maxReverseVelocity= 2.15,
	acceleration = 1.7,
	brakeRate = 0.1,
	turninplace		= true,
	footprintX = 1,
	footprintZ = 1,
	script 			= "Truckscript.lua",
	objectName 	= "Truck.s3o",
	movementClass   	= "VEHICLE",
	
	 transportSize = 16,
	transportCapacity = 2,
	isFirePlatform  = true,
	
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
	transportSize = 4,
	isFirePlatform  = true,
 
	 
	footprintX = 1,
	footprintZ = 1,
	script 			= "Truckscript.lua",
	objectName 	= "Truck.s3o",
	transportCapacity = 1,
	
	
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