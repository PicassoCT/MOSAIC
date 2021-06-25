local ground_truck_mg = Truck:New{
	name = "Machinegun Truck",
	description = "Selfdriving Truck with Machinegun <Assault Vehicle>",
	
	corpse				= "",
	maxDamage = 1500,
	mass = 500,
	buildCostEnergy = 250,
	buildCostMetal = 250,
	explodeAs			= "none",
	--conType			= "infantry",
	maxVelocity		= 3.5 , --14.3, --86kph/20
	--maxReverseVelocity= 2.15,
	acceleration = 1.7,
	brakeRate = 0.1,
	buildtime= 80,
	turninplace		= true,
	footprintX = 1,
	footprintZ = 1,
	script 			= "Truckscript.lua",
	objectName 	= "apc.dae",
	movementClass   	= "VEHICLE",
			buildPic = "truck_mg.png",
			iconType = "truck_mg",
	category = [[GROUND]],
	transportSize = 16,
	sightDistance = 50,
	transportCapacity = 2,
	isFirePlatform  = true,
	canCloak= false,
	collisionVolumeType = "box",
	collisionvolumescales = "40 50 70",
	fireState = 1,
	customparams = {
		helptext		= "Military Truck/Technical",
		baseclass		= "Truck", -- TODO: hacks
	},
	weapons = {
			[1]={name  = "marker",
				onlyTargetCategory = [[GROUND]],
				},
			},	
	LeaveTracks = true,
		canAttack = true,
	trackType ="armst_tracks",
	trackStrength=12,
	trackWidth =28,
	
}

local ground_truck_ssied = Truck:New{
	buildtime= 80,
	name = "SSIED Truck",
	description = "Selfdriving explosive truck <Assault Vehicle>",
		buildPic = "truck_iied.png",
		iconType = "truck_iied",
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
	fireState = 1,
	customparams = {
		helptext		= "Military Truck/Technical",
		baseclass		= "Truck", -- TODO: hacks
	},
	weapons = {
			[1]={name  = "marker",
				onlyTargetCategory = [[GROUND]],
				},
			},	
	
		canAttack = true,
	LeaveTracks = true,
	trackType ="armst_tracks",
	trackStrength=12,
	trackWidth =28,
	
}

local ground_truck_antiarmor = Truck:New{
	buildtime= 80,
	name = "AntiArmor Truck",
	description = "Selfdriving anti vehicle truck <Assault Vehicle>",
			buildPic = "truck_antiarmour.png",
			iconType = "truck_antiarmour",
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
	canCloak= false,
	canAttack = true,
	fireState = 1,
	customparams = {
		helptext		= "Military Truck/Technical",
		baseclass		= "Truck", -- TODO: hacks
	},
	weapons = {
			[1]={name  = "marker",
				onlyTargetCategory = [[GROUND]],
				},
			},	
	LeaveTracks = true,
	trackType ="armst_tracks",
	trackStrength=12,
	trackWidth =28,	
}

local ground_truck_rocket = Truck:New{
	buildtime= 80,
	name = "Roketlauncher Truck",
	description = "Selfdriving rocket artillery truck <Assault Vehicle>",
			buildPic = "truck_rocket.png",
			iconType = "truck_rocket",
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
	collisionvolumescales = "40 40 70",
	category = [[GROUND]],
	transportSize = 16,
	transportCapacity = 2,
	isFirePlatform  = true,
	fireState= 1,
	
	customparams = {
		helptext		= "Military Truck/Technical",
		baseclass		= "Truck", -- TODO: hacks
	},
	weapons = {
			[1]={name  = "marker",
				onlyTargetCategory = [[GROUND]],
				},
			},	
	LeaveTracks = true,
	trackType ="armst_tracks",
	trackStrength=12,
	trackWidth =28,	
	
	canCloak= false,
	canAttack = true
}

local CivilianTruck = Truck:New{
	buildtime= 30,
	name = "Civilian Vehicle",
	description = "locally assembled electric truck",
	corpse				= "",
	maxDamage = 500,
			buildPic = "truck.png",
			iconType = "truck",
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
	fireState = 1,
	footprintX = 1,
	footprintZ = 1,
	script 			= "Truckscript.lua",

	-- objectName 	= "Truck.s3o",
	weapons = {
			[1]={name  = "marker",
				onlyTargetCategory = [[NOTARGET]],
				},
			},

	category = [[GROUND]],
	
	customparams = {
		helptext		= "Transportation Truck",
		baseclass		= "Truck", -- TODO: hacks
	},
	

	
	LeaveTracks = true,
	trackType ="armst_tracks",
	trackStrength=12,
	trackWidth =28,	
}

local PoliceTruck = Truck:New{
	name = "Police Vehicle",
	description = "corrupt, chaotic - local authority",
	corpse				= "",
			buildPic = "truck_police.png",
			iconType = "truck_police",
	maxDamage = 1500,
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
	fireState = 2,
	weapons = {
				[1]={name  = "pistol",
					onlyTargetCategory = [[GROUND]],
					},
				[2]={name  = "policeaamachinegun",
					onlyTargetCategory = [[AIR]]
					},		
	},	
	
	LeaveTracks = true,
	trackType ="armst_tracks",
	trackStrength=12,
	trackWidth =28,
	

	

	category = [[GROUND]],
	
	customparams = {
		helptext		= "Transportation Truck",
		baseclass		= "Truck", -- TODO: hacks
	},
}

CivilianTrucks ={}
for i=0, 8 do
	CivilianTruck.objectName = "truck_arab"..i..".dae"
	if not CivilianTruck.customparams then CivilianTruck.customparams ={} end
	CivilianTruck.customparams.normaltex = "unittextures/truck_normal.dds"
	if i >=6 then
		CivilianTruck.customparams.normaltex = "unittextures/truck_"..i.."_normal.dds"
	end
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
	["ground_truck_antiarmor"]	= ground_truck_antiarmor:New(),
	["ground_truck_rocket"]	= ground_truck_rocket:New()	
})