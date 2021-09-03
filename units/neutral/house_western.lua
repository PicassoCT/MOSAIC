
local house_western = Building:New{
	corpse					= "",
	maxDamage        	= 3500,
	mass           		= 500,
	buildCostEnergy    	= 5,
	buildCostMetal    	= 5,
	explodeAs				= "none",
	name = "Housing Block",
	description = "houses civilians",
	buildPic = "house.png",
	iconType = "house",
	Builder					= true,
	levelground				= true,
	FootprintX = 8,
	FootprintZ = 8,
	script 				= "house_europe_script.lua",
	objectName       	= "house_europe.dae",

	
	
		
	YardMap =  [[yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy]]	,  
	

	customparams = {	
		normaltex = "unittextures/house_europe_normal.dds",
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

