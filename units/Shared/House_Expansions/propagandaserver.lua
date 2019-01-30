local Propagandaserver = Building:New{
	corpse				= "",
	maxDamage           = 500,
	mass                = 500,
	buildCostEnergy     = 5,
	buildCostMetal      = 5,
	explodeAs			= "none",

	MaxSlope 					= 50,

	footprintX = 1,
	footprintZ = 1,
	script 			= "propagandaserverscript.lua",
	objectName        	= "propagandaserver.s3o",


	

}


return lowerkeys({
	--Temp
	["propagandaserver"] = Propagandaserver:New(),
	
})