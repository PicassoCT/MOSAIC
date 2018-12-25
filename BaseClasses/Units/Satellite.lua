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
	
	customparams = {
		baseclass			= "satellite",
    },
}
	
-- local Aero = Aircraft:New{
	-- category 			= "aero air notbeacon",
	-- noChaseCategory		= "beacon ground",
	-- cruiseAlt			= 300,
	-- canLoopbackAttack 	= true,
	
	-- customparams = {
		-- baseclass			= "aero",
	-- },
-- }

-- local VTOL = Aircraft:New{
	-- category 			= "vtol air notbeacon",
	-- noChaseCategory		= "beacon air vtol",
	-- cruiseAlt			= 250,
	-- hoverAttack			= true,
	-- airHoverFactor		= -0.0001,
	
	-- customparams = {
		-- hasturnbutton		= "1",
		-- baseclass			= "vtol",
    -- },
-- }

return {
	satellite =satellite
}
