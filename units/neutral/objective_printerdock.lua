local objective_printerdock = Building:New{
	corpse					= "",
	maxDamage        	= 15000,
	mass           	= 500,
	buildCostEnergy    	= 5,
	buildCostMetal    	= 5,
	explodeAs				= "none",
	name = "3D Printing Dock",
	description = "owned by Prosperia Inc.",
	buildPic = "house.png",
	iconType = "house",
	Builder					= false,
	levelground				= true,
	FootprintX = 8,
	FootprintZ = 8,
	script 					= "objective_PrinterDockScript.lua",
	objectName       	= "objective_printerdock.dae",

	
	
	YardMap =     [[oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo]]	, 
	                    

	customParams = {	
		normaltex = "unittextures/house_asian_normal.dds",
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
	["objective_printerdock"] = objective_printerdock:New()
	
})
