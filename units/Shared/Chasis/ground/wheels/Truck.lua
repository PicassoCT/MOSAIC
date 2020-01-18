local ground_truck_mg = Truck:New{
	name = "Machinegun Truck",
	description = "Selfdriving Truck with Machinegun <Assault Vehicle>",
	
	corpse				= "",
	maxDamage = 1500,
	mass = 500,
	buildCostEnergy = 5,
	buildCostMetal = 5,
	explodeAs			= "none",
	--conType			= "infantry",
	maxVelocity		= 3.5 , --14.3, --86kph/20
	--maxReverseVelocity= 2.15,
	acceleration = 1.7,
	brakeRate = 0.1,
	turninplace		= true,
	footprintX = 1,
	footprintZ = 1,
	script 			= "Truckscript.lua",
	objectName 	= "apc.dae",
	movementClass   	= "VEHICLE",
	
	category = [[GROUND]],
	transportSize = 16,
	transportCapacity = 2,
	isFirePlatform  = true,
	collisionVolumeType = "box",
	collisionvolumescales = "40 50 70",
	
	customparams = {
		helptext		= "Military Truck/Technical",
		baseclass		= "Truck", -- TODO: hacks
	},
}

local ground_truck_ssied = Truck:New{
	name = "SSIED Truck",
	description = "Selfdriving explosive truck <Assault Vehicle>",
	
	corpse				= "",
	maxDamage = 1500,
	mass = 500,
	buildCostEnergy = 5,
	buildCostMetal = 5,
	explodeAs			= "none",
	--conType			= "infantry",
	maxVelocity		= 3.5 , --14.3, --86kph/20
	--maxReverseVelocity= 2.15,
	acceleration = 1.7,
	brakeRate = 0.1,
	turninplace		= true,
	footprintX = 1,
	footprintZ = 1,
	script 			= "Truckscript.lua",
	objectName 	= "apc.dae",
	movementClass   	= "VEHICLE",
	collisionVolumeType = "box",
	collisionvolumescales = "40 50 70",
	category = [[GROUND]],
	transportSize = 16,
	transportCapacity = 2,
	isFirePlatform  = true,
	
	customparams = {
		helptext		= "Military Truck/Technical",
		baseclass		= "Truck", -- TODO: hacks
	},
}

local ground_truck_antiarmor = Truck:New{
	name = "AntiArmor Truck",
	description = "Selfdriving anti vehicle truck <Assault Vehicle>",
	
	corpse				= "",
	maxDamage = 1500,
	mass = 500,
	buildCostEnergy = 5,
	buildCostMetal = 5,
	explodeAs			= "none",
	--conType			= "infantry",
	maxVelocity		= 3.5, --14.3, --86kph/20
	--maxReverseVelocity= 2.15,
	acceleration = 1.7,
	brakeRate = 0.1,
	turninplace		= true,
	footprintX = 1,
	footprintZ = 1,
	script 			= "Truckscript.lua",
	objectName 	= "apc.dae",
	movementClass   	= "VEHICLE",
	collisionVolumeType = "box",
	collisionvolumescales = "40 50 70",
	category = [[GROUND]],
	transportSize = 16,
	transportCapacity = 2,
	isFirePlatform  = true,
	fireState= 0,
	
	customparams = {
		helptext		= "Military Truck/Technical",
		baseclass		= "Truck", -- TODO: hacks
	},
}

local CivilianTruck = Truck:New(){
	name = "Civilian Vehicle",
	description = "Locally assembled electric truck",
	corpse				= "",
	maxDamage = 500,
	mass = 500,
	buildCostEnergy = 5,
	buildCostMetal = 5,
	explodeAs			= "none",
	--conType			= "infantry",
	maxVelocity		= 4.2, --14.3, --86kph/20
	--maxReverseVelocity= 2.15,
	movementClass   	= "VEHICLE",
	acceleration = 1.7,
	brakeRate = 0.1,
	turninplace		= true,
	
	transportSize = 16,
	transportCapacity = 1,
	isFirePlatform  = true, 
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "40 50 70",
	footprintX = 1,
	footprintZ = 1,
	script 			= "Truckscript.lua",

	-- objectName 	= "Truck.s3o",

	category = [[GROUND]],
	
	customparams = {
		helptext		= "Transportation Truck",
		baseclass		= "Truck", -- TODO: hacks
	},
}

local PoliceTruck = Truck:New{
	name = "Police Vehicle",
	description = "corrupt, chaotic - local authority",
	corpse				= "",
	maxDamage = 500,
	mass = 500,
	buildCostEnergy = 5,
	buildCostMetal = 5,
	explodeAs			= "none",
	--conType			= "infantry",
	maxVelocity		= 4.2, --14.3, --86kph/20
	--maxReverseVelocity= 2.15,
	movementClass   	= "VEHICLE",
	acceleration = 1.7,
	brakeRate = 0.1,
	turninplace		= true,
	canAttack = true,
	canMove = true,
	
	transportSize = 16,
	transportCapacity = 1,
	isFirePlatform  = true, 
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "40 50 70",
	footprintX = 1,
	footprintZ = 1,
	script 			= "Policetruckscript.lua",
	objectName 	= "apc.dae",

	weapons = {
				[1]={name  = "pistol",
					onlyTargetCategory = [[GROUND]],
					},
					
	},	
	

	category = [[GROUND]],
	
	customparams = {
		helptext		= "Transportation Truck",
		baseclass		= "Truck", -- TODO: hacks
	},
}
truck_arab0		 	= CivilianTruck:New()
truck_arab0.objectName = [[truck_arab0.dae]]
local truck_arab1		 	= truck_arab0
truck_arab1.objectName = [[truck_arab1.dae]]
local truck_arab2		 	=	truck_arab0
truck_arab2.objectName = [[truck_arab2.dae]]
local truck_arab3		 	=  truck_arab0
truck_arab3.objectName = [[truck_arab3.dae]]

return lowerkeys({
	--Temp
	["policetruck"]			 	= PoliceTruck:New(),
	["truck_arab0"]			 	= truck_arab0,
	["truck_arab1"]			 	= truck_arab1,
	["truck_arab2"]			 	= truck_arab2,
	["truck_arab3"]			 	= truck_arab3,
	["ground_truck_mg"]		= ground_truck_mg:New(),
	["ground_truck_ssied"]	= ground_truck_ssied:New(),
	["ground_truck_antiarmor"]	= ground_truck_antiarmor:New()

	
})