
local Spycam = Building:New{
	corpse				= "",
	maxDamage           = 10,
	mass                = 50,
	buildCostEnergy     = 100,
	buildCostMetal      = 50,
	explodeAs			= "none",
	buildTime =    3,
	nanocolor=[[0.20 0.411 0.611]], --
	YardMap =    [[o]],
	buildingMask = 8,
	maxSlope = 50.0,
	levelGround = false,
	blocking =false,

	upright  = false,

	footprintX = 1,
	footprintZ = 1,
	showNanoFrame= true,
	script 				= "spycamscript.lua",
	objectName        	= "spycam.dae",

	name = "Camera",
	description = " watches & surveils",
	buildPic = "Placeholder.png",
	
	customparams = {
		helptext		= "surveils the surrounding area",
		baseclass		= "Building",
    },
	
	
	category = [[GROUND BUILDING SURVEILANCE]],
	}



return lowerkeys({
	--Temp
	["spycam"] = Spycam:New(),
	
})
