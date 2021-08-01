local objectiverefugeecamp = Building:New{
	corpse					= "",
	maxDamage        	= 15000,
	mass           	= 500,
	buildCostEnergy    	= 5,
	buildCostMetal    	= 5,
	explodeAs				= "none",
	name = "Refugeecamp",
	description = "Food. Water. Shelter. Hopelessness.",
	buildPic = "house.png",
	iconType = "house",
	Builder					= false,
	levelground				= true,
	FootprintX = 8,
	FootprintZ = 8,
	script 					= "refugeecampscript.lua",
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

	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "130 200 130",
	category = [[GROUND BUILDING]],

}

return lowerkeys({
	--Temp
	["objective_refugeecamp"] = objectiverefugeecamp:New()
	
})
