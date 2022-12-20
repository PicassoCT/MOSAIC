local objective_spaceport_land = Building:New{
	corpse					= "",
	maxDamage        	= 15000,
	mass           	= 500,
	buildCostEnergy    	= 5,
	buildCostMetal    	= 5,
	explodeAs				= "none",
	name = "Spaceport",
	description = "launches and refuels rockets ",
	buildPic = "house.png",
	iconType = "house",
	Builder					= false,
	levelground				= true,
	FootprintX = 8,
	FootprintZ = 8,
	script 					= "objective_spaceportscript.lua",
	objectName       	= "objective_spaceport.dae",

	
	
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
	collisionvolumescales = "130 9000 130",
	category = [[GROUND BUILDING]],

}

local objective_spaceport_sea = Building:New{
	corpse					= "",
	maxDamage        	= 15000,
	mass           	= 500,
	buildCostEnergy    	= 5,
	buildCostMetal    	= 5,
	explodeAs				= "none",
	name = "Spaceport",
	description = "launches and refuels rockets ",
	buildPic = "house.png",
	iconType = "house",
	Builder					= false,
	levelground				= true,
	FootprintX = 8,
	FootprintZ = 8,
	script 					= "objective_spaceportscript.lua",
	objectName       	= "objective_spaceport.dae",

	
	
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
	collisionvolumescales = "130 9000 130",
	category = [[GROUND BUILDING]],

}

return lowerkeys({
	--Temp
	["objective_spaceport_water"] = objective_spaceport_sea:New(),
	["objective_spaceport_land"] = objective_spaceport_land:New()	
})
