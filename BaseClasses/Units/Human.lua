-- Mechs ----
local Human = Unit:New{
	activateWhenBuilt   	= true,
	canMove					= true,
	category 				= "ground",
	noChaseCategory		 	= "air building",
	onoffable        	= true,
	script					= "Civillian.lua",
	upright					= true,
	usepiececollisionvolumes = true,
	movementClass   		= "BIPEDAL",
	customparams = {
    },
}


return {
	Human = Human,

}
