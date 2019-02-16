-- Satellite ----
local Building = Unit:New{

	canMove 					= false,
	explodeAs          			= "mechexplode",

	footprintX					= 4,
	footprintZ 					= 4,
	iconType					= "house",
	MaxSlope 					= 50,	
	moveState					= 0, -- Hold Position
	script						= "House.lua",
	usepiececollisionvolumes 	= true,
	
	metalStorage = 2500,
	
	customparams = {
    },
}
	

return {
	Building = Building
}
