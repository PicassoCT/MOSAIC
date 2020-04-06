local House = Building:New{
	corpse					= "",
	maxDamage        	= 1500,
	mass           	= 500,
	buildCostEnergy    	= 5,
	buildCostMetal    	= 5,
	explodeAs				= "none",
	name = "Housing Block",
	description = "houses civilians",
			buildPic = "house.png",
	Builder					= true,
	levelground				= true,
	FootprintX = 8,
	FootprintZ = 8,
	script 					= "Housescript.lua",
	objectName       	= "house.dae",
			customParams        = {
		normaltex = "unittextures/house_arab_normal.png",
	},
	
	
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
	"civilian_arab0"
	},
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "130 120 130",
	category = [[GROUND BUILDING RAIDABLE]],

}


return lowerkeys({
	--Temp
	["house_arab0"] = House:New(),
	
})