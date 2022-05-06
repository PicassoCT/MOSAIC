local objective_military_gyland = Building:New{
	corpse					= "",
	maxDamage        	= 15000,
	mass           	= 500,
	buildCostEnergy    	= 5,
	buildCostMetal    	= 5,
	explodeAs				= "none",
	name = "Floating Military Gyland",
	description = "not recognized by any cooperationation",
	buildPic = "house.png",
	iconType = "house",
	Builder					= false,
	levelground				= true,
	FootprintX = 8,
	FootprintZ = 8,
	script 					= "placeholder.lua",
	objectName       	= "objective_military_gyland.dae",

	
	
	YardMap =     [[oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo]]	, 
	                    

	customParams = {	
		normaltex = "unittextures/component_atlas_normal.dds",
		helptext			= "Civilian Building",
		baseclass			= "Building", -- TODO: hacks
    },
	
	buildoptions = 
	{
	"civilian_arab0"
	},
	floater = true,
	waterline = 0.0,
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "130 200 130",
	category = [[GROUND BUILDING]],

}

return lowerkeys({
	--Temp
	["objective_military_gyland"] = objective_military_gyland:New()
	
})
