
local house_ruin = Building:New{
	corpse					= "",
	maxDamage        	= 3500,
	mass           		= 500,
	buildCostEnergy    	= 5,
	buildCostMetal    	= 5,
	explodeAs				= "none",
	name = "Ruins",
	description = "remnants of the warming wars",
	buildPic = "house.png",
	iconType = "house",
	Builder					= true,
	levelground				= true,
	FootprintX = 8,
	FootprintZ = 8,
	script 				= "house_ruin_script.lua",
	objectName       	= "house_ruin.dae",


	isFirePlatform  = true, 	
		
	YardMap =  [[yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy]]	,  
	

	customparams = {	
		normaltex = "unittextures/house_asian_normal.dds",
		helptext			= "Civilian Building",
		baseclass			= "Building", -- TODO: hacks
    },
	
	buildoptions = 
	{
	"civilian_arab0"
	},
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "130 60 130",
	collisionVolumeOffsets  = {0.0, 30.0,  0.0},
	category = [[BUILDING RAIDABLE]],

}



return lowerkeys({
	["house_ruin"] = house_ruin:New(),
	
})
