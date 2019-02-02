local House = Building:New{
	corpse					= "",
	maxDamage        	= 500,
	mass           	= 500,
	buildCostEnergy    	= 5,
	buildCostMetal    	= 5,
	explodeAs				= "none",
	
	Builder					= true,
	levelground				= false,
	FootprintX = 8,
	FootprintZ = 8,
	script 					= "Housescript.lua",
	objectName       	= "house.s3o",
	
	YardMap = 	[[ooyyyyoo oyyyyyyo yyyyyyyy yyyyyyyy yyyyyyyy yyyyyyyy oyyyyyyo ooyyyyoo]]	,
	

	customparams = {	
		helptext			= "Civilian Building",
		baseclass			= "Building", -- TODO: hacks
    },
	
	buildoptions = 
	{
	"civilian"
	},
	
	category =  [[BUILDING ARRESTABLE]],
}


return lowerkeys({
	--Temp
	["house"] = House:New(),
	
})