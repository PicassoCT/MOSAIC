local house_arab = Building:New{
	corpse					= "",
	maxDamage        	= 3500,
	mass           	= 500,
	buildCostEnergy    	= 5,
	buildCostMetal    	= 5,
	explodeAs				= "none",
	name = "Housing Block",
	description = "houses civilians",
	buildPic = "house.png",
	iconType = "house",
	Builder					= true,
	levelground				= true,
	FootprintX = 6,
	FootprintZ = 6,
	script 					= "house_arab_script.lua",
	objectName       	= "house_arab.dae",

	
	
	YardMap =  [[yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy]]	, 
	

	customparams = {	
		normaltex = "unittextures/house_arab_normal.dds",
		helptext			= "Civilian Building",
		baseclass			= "Building", -- TODO: hacks
    },
	
	buildoptions = 
	{
	"civilian_arab0"
	},
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "130 50 130",
	collisionVolumeOffsets  = {0.0, 15.0,  0.0},
	category = [[GROUND BUILDING RAIDABLE]],

}

return lowerkeys({
	--Temp
	["house_arab0"] = house_arab:New()
	
})
