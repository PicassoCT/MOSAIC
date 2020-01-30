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
	canCloak= false,
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
	canCloak= false,
	customparams = {
		helptext		= "Military Truck/Technical",
		baseclass		= "Truck", -- TODO: hacks
	},
}

local CivilianTruck = Truck:New{
	name = "Civilian Vehicle",
	description = "locally assembled electric truck",
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
	canAttack= true,
	canFight = true,
	canCloak= false,
	collisionVolumeType = "box",
	collisionvolumescales = "40 50 70",
	footprintX = 1,
	footprintZ = 1,
	script 			= "Truckscript.lua",

	-- objectName 	= "Truck.s3o",
		weapons = {
				[1]={name  = "pistol",
					onlyTargetCategory = [[NIL]],
					},
				},

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
	canCloak= false,
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

CivilianTrucks ={}
for i=0, 8 do
CivilianTruck.objectName = "truck_arab"..i..".dae"
CivilianTrucks["truck_arab"..i] = CivilianTruck:New()
end

return lowerkeys({
	--Temp
	["policetruck"]			 	= PoliceTruck:New(),
	["truck_arab0"]			 	= CivilianTrucks["truck_arab0"],
	["truck_arab1"]			 	= CivilianTrucks["truck_arab1"],
	["truck_arab2"]			 	= CivilianTrucks["truck_arab2"],
	["truck_arab3"]			 	= CivilianTrucks["truck_arab3"],
	["truck_arab4"]			 	= CivilianTrucks["truck_arab4"],
	["truck_arab5"]			 	= CivilianTrucks["truck_arab5"],
	["truck_arab6"]			 	= CivilianTrucks["truck_arab6"],
	["truck_arab7"]			 	= CivilianTrucks["truck_arab7"],
	["truck_arab8"]			 	= CivilianTrucks["truck_arab8"],
	["ground_truck_mg"]		= ground_truck_mg:New(),
	["ground_truck_ssied"]	= ground_truck_ssied:New(),
	["ground_truck_antiarmor"]	= ground_truck_antiarmor:New()

	
})