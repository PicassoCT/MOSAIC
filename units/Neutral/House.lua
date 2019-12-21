local House = Building:New{
	corpse					= "",
	maxDamage        	= 1500,
	mass           	= 500,
	buildCostEnergy    	= 5,
	buildCostMetal    	= 5,
	explodeAs				= "none",
	name = "Housing Block",
	description = "houses civilians",
	Builder					= true,
	levelground				= true,
	FootprintX = 8,
	FootprintZ = 8,
	script 					= "Housescript.lua",
	objectName       	= "house.dae",
	
	YardMap = 	[[hoooyyyyyyyyyyyyyyyyyyyyyyyyyooo
				   oyyyyyyyyyyyyyyyyyyyyyyyyyyyyyo
				   oyyyyyyyyyyyyyyyyyyyyyyyyyyyyyo
				   yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
				   yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
				   yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
				   yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
				   yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
				   yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
				   yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
				   yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
				   yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
				   yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
				   yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
				   yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
				   yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
				   yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
				   yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
				   yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
				   yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
				   yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
				   yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
				   yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
				   yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
				   oyyyyyyyyyyyyyyyyyyyyyyyyyyyyyo
				   oyyyyyyyyyyyyyyyyyyyyyyyyyyyyyo
				   oooyyyyyyyyyyyyyyyyyyyyyyyyyooo]]	,
	

	customparams = {	
		helptext			= "Civilian Building",
		baseclass			= "Building", -- TODO: hacks
    },
	
	buildoptions = 
	{
	"civilian"
	},
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "130 120 130",
	category =  [[GROUND BUILDING ARRESTABLE]],
}


return lowerkeys({
	--Temp
	["house"] = House:New(),
	
})