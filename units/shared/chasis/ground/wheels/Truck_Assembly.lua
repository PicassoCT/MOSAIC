local TruckAssembly = Truck:New{
	name = "Assembly Truck ",
	Description = " MOSAIC Standardized Vehicle Factory ",

	corpse				= "",
	
	maxDamage = 500,
	mass = 5000,
    buildCostMetal = 2500,
    buildCostEnergy = 1250,
	buildTime = 2*60,
	workerTime= 0.5,
	explodeAs			= "none",
	--conType			= "infantry",
	maxVelocity		= 7.15*0.15 , --, --43kph/20
	--maxReverseVelocity= 2.15,
	acceleration = 1.7,
	brakeRate = 0.1,
	turninplace		= true,
	footprintX = 1,
	footprintZ = 1,
	holdSteady = true,
	script 			= "Truckassemblyscript.lua",
	objectName 	= "truck_arab6.dae",
	movementClass   	= "VEHICLE",
	buildPic ="truck_assembly.png",
	iconType ="truck_assembly",
	customparams = {
		helptext		= "Military Truck/Technical",
		baseclass		= "Truck", -- TODO: hacks
		normaltex = "unittextures/truck_6_normal.dds",
		},
	
	category = [[GROUND ARRESTABLE]],
}


return lowerkeys({
	--Temp

	["ground_truck_assembly"] 		= TruckAssembly:New(),
	
})