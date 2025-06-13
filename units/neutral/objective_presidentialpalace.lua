local objective_presidentialpalace_land = Building:New{
	corpse					= "",
	maxDamage        	= 15000,
	mass           	= 500,
	buildCostEnergy    	= 5,
	buildCostMetal    	= 5,
	explodeAs				= "none",
	name = "Presidential Palace",
	description = "houses his Excellency Dr. Dr. General Alladeen",
	buildPic = "house.png",
	iconType = "house",
	Builder					= false,
	levelground				= true,
	FootprintX = 8,
	FootprintZ = 8,
	script 				= "objective_presidentialpalacescript.lua",
	objectName       	= "objective_presidentialpalace.dae",

	
	
	YardMap =     [[oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo]]	, 
	                    

	customparams = {	
		normaltex = "unittextures/house_europe_normal.dds",
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
	["objective_presidentialalace"] = objective_presidentialpalace_land:New()	
})
