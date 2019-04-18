local ground_truck_mg = Truck:New{
	name = "Machinegun Truck",
	description = "MOSAIC standardized selfdriving Truck with Machinegun <Assault Vehicle>",
	
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
	objectName 	= "apc.dae",
	movementClass   	= "VEHICLE",
	
	category = [[LAND]],
	transportSize = 16,
	transportCapacity = 2,
	isFirePlatform  = true,
	usepiececollisionvolumes = true,
	
	customparams = {
		helptext		= "Military Truck/Technical",
		baseclass		= "Truck", -- TODO: hacks
	},
}

local ground_truck_ssied = Truck:New{
	name = "SSIED Truck",
	description = "MOSAIC standardized explosive truck <Assault Vehicle>",
	
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
	objectName 	= "apc.dae",
	movementClass   	= "VEHICLE",
	
	category = [[LAND]],
	transportSize = 16,
	transportCapacity = 2,
	isFirePlatform  = true,
	
	customparams = {
		helptext		= "Military Truck/Technical",
		baseclass		= "Truck", -- TODO: hacks
	},
}

local CivilianTruck = Truck:New{
	name = "Civilian Vehicle",
	description = "Locally assembled electric truck",
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
	
	transportSize = 16,
	transportCapacity = 1,
	isFirePlatform  = true, 
 usepiececollisionvolumes = true,
	 
	footprintX = 1,
	footprintZ = 1,
	script 			= "Truckscript.lua",
	objectName 	= "truck.dae",
	-- objectName 	= "Truck.s3o",

	category = [[LAND]],
	
	customparams = {
		helptext		= "Transportation Truck",
		baseclass		= "Truck", -- TODO: hacks
	},
}

return lowerkeys({
	--Temp
	["truck"]			 	= CivilianTruck:New(),
	["ground_truck_mg"]		= ground_truck_mg:New(),
	["ground_truck_ssied"]	= ground_truck_ssied:New(),

	
})