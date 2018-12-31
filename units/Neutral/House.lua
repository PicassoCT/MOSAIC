local House = Building:New{
	corpse					= "",
	maxDamage        	= 500,
	mass           	= 500,
	buildCostEnergy    	= 5,
	buildCostMetal    	= 5,
	explodeAs				= "none",
	
	levelground				= true,
	footprintX 				= 4,
	footprintZ				= 4,
	script 					= "House.lua",
	objectName       	= "house.s3o",

	customparams = {	
		helptext			= "Civilian Building",
		baseclass			= "Building", -- TODO: hacks
    },
}


return lowerkeys({
	--Temp
	["house"] = House:New(),
	
})