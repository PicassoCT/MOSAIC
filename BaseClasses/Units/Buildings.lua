-- Satellite ----
local Building = Unit:New{

	canMove 					= false,
	explodeAs          			= "mechexplode",

	footprintX					= 4,
	footprintZ 					= 4,
	iconType					= "house",
	moveState					= 0, -- Hold Position
	script						= "House.lua",
	usepiececollisionvolumes 	= true,
	
	customparams = {
    },
}
	

return {
	Building = Building
}
