local CivilianTruck = Truck:New{
	buildtime= 30,
	name = "Car",
	description = " western style vehicle",
	corpse				= "",
	maxDamage = 500,
	buildPic = "truck.png",
	iconType = "truck",
	mass = 500,
	buildCostEnergy = 5,
	buildCostMetal = 5,
	explodeAs			= "none",
	--conType			= "infantry",
	maxVelocity		= 5.2, --14.3, --86kph/20
	--maxReverseVelocity= 2.15,
	movementClass   	= "VEHICLE",
	acceleration = 2.7,
	brakeRate = 0.3,
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
			normaltex = "unittextures/house_europe_normal.dds",
	},
	
	objectName = "truck_western0.dae",
	
	LeaveTracks = true,
	trackType ="armst_tracks",
	trackStrength=12,
	trackWidth =28,	
}
Velocity = {
	[0] =5.2,
	[1] =5.2,
	[2] =3.2,
}

CivilianTrucks ={}
for i=0, 2 do
	CivilianTruck.objectName = "truck_western"..i..".dae"
	CivilianTruck.customparams.normaltex = "unittextures/house_europe_normal.dds"
	CivilianTruck.customparams.maxVelocity = Velocity[i]
	CivilianTrucks["truck_western"..i] = CivilianTruck:New()
end

return lowerkeys({
	--Temp
	["truck_western0"]			 	=  CivilianTrucks["truck_western0"],
	["truck_western1"]			 	=  CivilianTrucks["truck_western1"],
	["truck_western2"]			 	=  CivilianTrucks["truck_western2"],
})
