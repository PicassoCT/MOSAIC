local objective_powerplant = Building:New{
	corpse					= "",
	maxDamage        	= 15000,
	mass           	= 500,
	buildCostEnergy    	= 5,
	buildCostMetal    	= 5,
	explodeAs				= "none",
	name = "Orbital Microwave  Collector Powerplant",
	description = "can provide power for a whole arcology",
	buildPic = "house.png",
	iconType = "house",
	Builder					= false,
	levelground				= true,
	FootprintX = 8,
	FootprintZ = 8,
	script 					= "objectivePowerPlantScript.lua",
	objectName       	= "objective_powerplant.dae",

	
	
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
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "130 200 130",
	category = [[GROUND BUILDING]],

}

return lowerkeys({
	--Temp
	["objective_powerplant"] = objective_powerplant:New()
	
})
