local TruckAssembly = Truck:New{
	corpse				= "",
	
	maxDamage = 500,
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
	script 			= "Truckassemblyscript.lua",
	objectName 	= "TruckAssembly.s3o",
	movementClass   	= "VEHICLE",
	
	customparams = {
		helptext		= "Military Truck/Technical",
		baseclass		= "Truck", -- TODO: hacks
	},
}


return lowerkeys({
	--Temp

	["ground_truck_assembly"] 		= TruckAssembly:New(),
	
})