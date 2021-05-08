local objectiveFactoryShip = Building:New{
	corpse					= "",
	maxDamage        	= 15000,
	mass           	= 500,
	buildCostEnergy    	= 5,
	buildCostMetal    	= 5,
	explodeAs				= "none",
	name = "Factory Ship",
	description = "fully automated offshore factory <Objective> Protagon protect or Antagon destroy",
	buildPic = "house.png",
	iconType = "house",
	Builder					= false,
	levelground				= true,
	FootprintX = 8,
	FootprintZ = 8,
	script 					= "objectiveFactoryShipScript.lua",
	objectName       	= "objective_factoryship.dae",

	
	
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
	floater = true,
	waterline = 25.0,
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "130 900 130",
	category = [[GROUND BUILDING]],

}

return lowerkeys({
	--Temp
	["objective_factoryship"] = objectiveFactoryShip:New()
	
})
