
local house_asian = Building:New{
	corpse					= "",
	maxDamage        	= 3500,
	mass           		= 500,
	buildCostEnergy    	= 5,
	buildCostMetal    	= 5,
	explodeAs				= "none",
	name = "Asian Style Housing",
	description = "houses civilians",
	buildPic = "house.png",
	iconType = "house",
	Builder					= true,
	levelground				= true,
	FootprintX = 8,
	FootprintZ = 8,
	script 				= "placeholder.lua",
	objectName       	= "house_asian.dae",

	
	
		
	YardMap =  [[yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy]]	,  
	

	customparams = {	
		normaltex = "unittextures/house_asia_normal.dds",
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
	category = [[GROUND BUILDING RAIDABLE]],

}

return lowerkeys({
	--Temp
	["house_asian0"] = house_asian:New()
	
})
