-- Aircraft ----
local AIRCRAFT = Unit:New{
	canFly						= true,
	canMove 					= true,
	factoryHeadingTakeoff 		= false,
	cruiseAlt					= 600,
	footprintX					= 2,
	footprintZ 					= 2,
	iconType					= "aero",
	moveState					= 0, -- Hold Position
	script						= "Vehicle.lua",
	usepiececollisionvolumes 	= true,
	
	customparams = {
		baseclass ="aero"
    },
}
	
local Aero = Unit:New{
	category 			= [[AIR]],
	cruiseAlt			= 300,
	canLoopbackAttack 	= true,
	canFly						= true,
	canMove 					= true,
	factoryHeadingTakeoff 		= false,
	footprintX					= 2,
	footprintZ 					= 2,
	iconType					= "aero",
	moveState					= 0, -- Hold Position
	script						= "Vehicle.lua",
	usepiececollisionvolumes 	= true,
	
	customparams = {
		baseclass			= "aero",
	},
}

local VTOL = Unit:New{
	category 			= [[AIR]],
	cruiseAlt			= 250,
	hoverAttack			= true,
	airHoverFactor		= -0.0001,
	canFly						= true,
	canMove 					= true,
	factoryHeadingTakeoff 		= false,
	footprintX					= 2,
	footprintZ 					= 2,
	iconType					= "aero",
	moveState					= 0, -- Hold Position
	script						= "Vehicle.lua",
	usepiececollisionvolumes 	= true,
	
	customparams = {

		baseclass			= "aircraft",
    },
}

local Rocket = Unit:New{
	category 			= [[ORBIT]],
	cruiseAlt			= 2048,
	hoverAttack			= false,
	airHoverFactor		= -0.0001,
	canFly						= true,
	canMove 					= true,
	factoryHeadingTakeoff 		= false,
	footprintX					= 2,
	footprintZ 					= 2,
	iconType					= "aero",
	moveState					= 0, -- Hold Position
	script						= "Vehicle.lua",
	usepiececollisionvolumes 	= true,
	
	customparams = {

		baseclass			= "aircraft",
    },
}

return {
	AIRCRAFT = AIRCRAFT,
	Aero = Aero,
	VTOL = VTOL,
	Rocket= Rocket
}
