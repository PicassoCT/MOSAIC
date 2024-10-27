
local house_asian_standalone = Building:New{
	corpse					= "",
	maxDamage        	= 3500,
	mass           		= 500,
	buildCostEnergy    	= 5,
	buildCostMetal    	= 5,
	explodeAs				= "none",
	name = "Arcology",
	description = "housing mega project",
	buildPic = "house.png",
	iconType = "house",
	Builder					= true,
	levelground				= true,
	FootprintX = 8,
	FootprintZ = 8,
	script 				= "house_asian_standalone_script.lua",
	objectName       	= "house_asian_standalone.dae",


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
	--Temp
	["house_asian1"] = house_asian_standalone:New()
	
})
