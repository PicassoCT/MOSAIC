-- Satellite ----
local Satellite = Unit:New{
	canFly						= true,
	canMove 					= true,
	factoryHeadingTakeoff 		= false,
	footprintX					= 2,
	footprintZ 					= 2,
	iconType					= "satellite",
	moveState					= 0, -- Hold Position
	script						= "satellitescript.lua",
	usepiececollisionvolumes 	= true,
	cruiseAlt					= 2000,
	myGravity 					= 0,
	wantedHeight				= 2000,
	maxElevator 				= 0,

	
	customparams = {
    },
	category = [[orbit]],
}
	

return {
	Satellite =Satellite
}
