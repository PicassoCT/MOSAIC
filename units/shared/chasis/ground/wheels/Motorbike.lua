
local MotorBike = Truck:New{
	buildtime= 30,
	name = "Civilian Vehicle",
	description = "bike",
	corpse				= "",
	maxDamage = 250,
			buildPic = "truck.png",
			iconType = "truck",
	mass = 400,
	buildCostEnergy = 5,
	buildCostMetal = 5,
	explodeAs			= "none",
	--conType			= "infantry",
	maxVelocity		= 4.2, --14.3, --86kph/20
	--maxReverseVelocity= 2.15,
	movementClass   	= "VEHICLE",
	acceleration = 1.7,
	brakeRate = 0.02,
	turninplace		= true,
	
	transportSize = 16,
	transportCapacity = 1,
	--holdSteady = true,
	cantBeTransported = true,
	isFirePlatform  = true, 
	releaseHeld = true,
	usepiececollisionvolumes = false,
	canAttack= false,
	canFight = false,
	canCloak= false,
	collisionVolumeType = "box",
	collisionvolumescales = "20 50 50",
	fireState = 1,
	footprintX = 1,
	footprintZ = 1,
	script 			= "MotorBikeScript.lua",
	objectName      = "civilian_motorbike.dae",

	category = [[GROUND]],
	
	customparams = {
		helptext		= "Motorbike",
		baseclass		= "Truck", -- TODO: hacks
		normaltex = "unittextures/civilianMotorBike_normal.dds",
	},
	
	LeaveTracks = false,
--[[	trackType ="armst_tracks",
	trackStrength=12,
	trackWidth =28,	--]]
}

return lowerkeys({
	--Temp
	["truck_arab9"]			 	= MotorBike:New(),
	["truck_western4"]			= MotorBike:New(),
})