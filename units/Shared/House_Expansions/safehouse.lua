local SafeHouse = Building:New{
	corpse				= "",
	maxDamage           = 500,
	mass                = 500,
	buildCostEnergy     = 5,
	buildCostMetal      = 5,
	explodeAs			= "none",


	footprintX = 4,
	footprintZ = 4,
	script 			= "safehousescript.lua",
	objectName        	= "house_safehouse.s3o",


	
	customparams = {
		helptext		= "Civilian Building",
		baseclass		= "Building", -- TODO: hacks
    },
}


return lowerkeys({
	--Temp
	["safehouse"] = SafeHouse:New(),
	
})