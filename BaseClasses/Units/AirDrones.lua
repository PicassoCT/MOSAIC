-- Aircraft ----
local Aircraft = Unit:New{
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
		ignoreatbeacon  = true,
    },
}
	
local Aero = Aircraft:New{
	category 			= [[AIR]],
	cruiseAlt			= 300,
	canLoopbackAttack 	= true,
	
	customparams = {
		baseclass			= "aero",
	},
}

local VTOL = Aircraft:New{
	category 			= [[AIR]],
	cruiseAlt			= 250,
	hoverAttack			= true,
	airHoverFactor		= -0.0001,
	
	customparams = {
		hasturnbutton		= "1",
		baseclass			= "aircraft",
    },
}

local Rocket = Aircraft:New{
	category 			= [[ROCKET]],
	cruiseAlt			= 2048,
	hoverAttack			= false,
	airHoverFactor		= -0.0001,
	
	customparams = {
		hasturnbutton		= "1",
		baseclass			= "aircraft",
    },
}

return {
	Aircraft = Aircraft,
	Aero = Aero,
	VTOL = VTOL,
	Rocket= Rocket
}
