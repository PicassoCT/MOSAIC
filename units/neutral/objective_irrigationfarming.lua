local objective_irrigationfarming = Building:New{
	corpse					= "",
	maxDamage        	= 15000,
	mass           	= 500,
	buildCostEnergy    	= 5,
	buildCostMetal    	= 5,
	explodeAs				= "none",
	name = "Irrigation Farm",
	description = "",
	buildPic = "house.png",
	iconType = "house",
	Builder					= false,
	levelground				= true,
	FootprintX = 4,
	FootprintZ = 4,
	script 					= "objectiveIrrigation_farm.lua",
	objectName       	= "objective_irrigationfarm.dae",

	
	
	YardMap =     [[yooy
					oooo
					oooo
					yooy]]	, 
					                    

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
	collisionvolumescales = "130 9000 130",
	category = [[GROUND BUILDING]],

}

return lowerkeys({
	--Temp
	["objective_irrigationfarming"] = objective_irrigationfarming:New()
	
})
