
local CivilianTruck = Truck:New{
	buildtime= 30,
	name = "Civilian Truck",
	description = "",
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
			normaltex = "unittextures/apc_normal.dds",
	},
	

	
	LeaveTracks = true,
	trackType ="armst_tracks",
	trackStrength=12,
	trackWidth =28,	
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
	["truck_arab0"]			 	= CivilianTrucks["truck_arab0"],
	["truck_arab1"]			 	= CivilianTrucks["truck_arab1"],
	["truck_arab2"]			 	= CivilianTrucks["truck_arab2"],
	["truck_arab3"]			 	= CivilianTrucks["truck_arab3"],
	["truck_arab4"]			 	= CivilianTrucks["truck_arab4"],
	["truck_arab5"]			 	= CivilianTrucks["truck_arab5"],
	["truck_arab6"]			 	= CivilianTrucks["truck_arab6"],
	["truck_arab7"]			 	= CivilianTrucks["truck_arab7"],
	["truck_arab8"]			 	= CivilianTrucks["truck_arab8"],
})
