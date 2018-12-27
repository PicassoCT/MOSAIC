-- Satellite ----
local Satellite = Unit:New{
	canFly						= true,
	canMove 					= true,
	explodeAs          			= "mechexplode",
	factoryHeadingTakeoff 		= false,
	footprintX					= 2,
	footprintZ 					= 2,
	iconType					= "satellite",
	moveState					= 0, -- Hold Position
	script						= "Satellite.lua",
	usepiececollisionvolumes 	= true,
	cruiseAlt					= 1500,
	myGravity 					= 0,
	wantedHeight				= 1500,
	maxElevator 				= 0,

	
	customparams = {
    },
}
	

return {
	Satellite =Satellite
}
