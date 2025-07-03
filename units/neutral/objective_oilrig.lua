local objective_oilrig = Building:New{
	corpse					= "",
	maxDamage        	= 15000,
	mass           	= 500,
	buildCostEnergy    	= 5,
	buildCostMetal    	= 5,
	explodeAs				= "none",
	name = "Oilrig",
	description = "pumps up ",
	buildPic = "house.png",
	iconType = "house",
	Builder					= false,
	levelground				= true,
	FootprintX = 8,
	FootprintZ = 8,
	script 				= "objective_oilrigscript.lua",
	objectName       	= "objective_oilrig.dae",

	
	
	YardMap =     [[oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo]]	, 
	                    

	customparams = {	
		normaltex = "unittextures/house_asian_normal.dds",
		helptext			= "Civilian Building",
		baseclass			= "Building", -- TODO: hacks
    },
     sfxtypes = {
				explosiongenerators = {
					   "custom:volcanolightsmall",--1024
					   "custom:flames",
					   "custom:glowsmoke",
					},
	},
	
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "130 9000 130",
	category = [[GROUND BUILDING]],

}


return lowerkeys({
	--Temp
	["objective_oilrig"] = objective_oilrig:New(),
	["objective_oilrig_sea"] = objective_oilrig:New()	
})
