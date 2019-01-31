local Propagandaserver = Building:New{
	corpse				= "",
	maxDamage           = 500,
	mass                = 500,

	buildCostMetal      = 150,
	EnergyStorage = 0,
	EnergyUse = 0,
	MetalStorage = 0,
	EnergyMake = 5, 
	MakesMetal = 5, 
	MetalMake = 0,	
	
	acceleration = 0,
	
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