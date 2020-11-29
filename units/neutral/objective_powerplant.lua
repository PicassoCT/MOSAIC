local objective_powerplant = Building:New{
	corpse					= "",
	maxDamage        	= 15000,
	mass           	= 500,
	buildCostEnergy    	= 5,
	buildCostMetal    	= 5,
	explodeAs				= "none",
	name = "Orbital Microwave  Collector Powerplant",
	description = "provides power for major urban areas ( < 250 Mio people)",
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
	collisionvolumescales = "130 9000 130",
	category = [[GROUND BUILDING]],

}

return lowerkeys({
	--Temp
	["objective_powerplant"] = objective_powerplant:New()
	
})
