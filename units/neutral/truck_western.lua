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
			normaltex = "unittextures/apc_normal.dds",
	},
	

	
	LeaveTracks = true,
	trackType ="armst_tracks",
	trackStrength=12,
	trackWidth =28,	
}


CivilianTrucks ={}
for i=0, 1 do
	CivilianTruck.objectName = "truck_arab"..i..".dae"
	if not CivilianTruck.customparams then CivilianTruck.customparams ={} end
	CivilianTruck.customparams.normaltex = "unittextures/truck_normal.dds"
	if i >=6 then
		CivilianTruck.customparams.normaltex = "unittextures/truck_"..i.."_normal.dds"
	end
	CivilianTrucks["truck_western"..i] = CivilianTruck:New()
end

return lowerkeys({
	--Temp
	["truck_western0"]			 	= CivilianTrucks["truck_western0"]
})
