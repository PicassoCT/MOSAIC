local objectiverefugeegyland = Building:New{
	corpse					= "",
	maxDamage        	= 15000,
	mass           	= 500,
	buildCostEnergy    	= 5,
	buildCostMetal    	= 5,
	explodeAs				= "none",
	name = "Floating Refugee Gyland",
	description = "not recognized by any cooperationation",
	buildPic = "house.png",
	iconType = "house",
	Builder					= false,
	levelground				= true,
	FootprintX = 8,
	FootprintZ = 8,
	script 					= "placeholder.lua",
	objectName       	= "objective_refugeegyland.dae",

	
	
	YardMap =     [[oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo]]	, 
	                    

	customparams = {	
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
	["objective_refugeegyland"] = objectiverefugeegyland:New()
	
})
