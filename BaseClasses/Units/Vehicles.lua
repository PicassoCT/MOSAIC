-- Vehicles ----
local Vehicle = Unit:New{
	canMove 			= true,
	footprintX			= 3,-- current both TANK and HOVER movedefs are 2x2 even if unitdefs are not
	footprintZ 			= 3,
	iconType			= "vehicle",
	moveState			= 0, -- Hold Position
	onoffable           = true,
	script				= "Vehicle.lua",
	usepiececollisionvolumes = true,
	
	customparams = {
		ignoreatbeacon  = true,
		baseclass		= "vehicle",
    },
}

local Truck = Vehicle:New{
	category 			= "civilian vehicle ground",
	explodeAs          	= "mechexplode",
	leaveTracks			= true,	
	movementClass   	= "VEHICLE",
	noChaseCategory		= "civilian air",
	trackType			= "Thick",
	trackOffset			= 10,
	turnRate			= 300,
	customparams = {
    },
}


return {
	Truck = Truck

}
