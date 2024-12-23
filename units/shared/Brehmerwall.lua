
local Brehmerwall = Building:New{
	corpse				= "",
	maxDamage           = 10000,
	mass                = 500,
	buildCostEnergy     = 100,
	buildCostMetal      = 50,
	explodeAs			= "none",


	buildTime =    20,
	Builder = true,
	nanocolor=[[0.20 0.411 0.611]], --
	CanReclaim=false,	

	workerTime = 0.065,
	YardMap =    [[oo
				   oo
				   oo
				   oo]],
	buildingMask = 1,
	maxSlope = 50.0,
	levelGround = false,
	blocking =false,
	MetalStorage = 2500,
	upright  = false,

	footprintX = 2,
	footprintZ = 4,
	showNanoFrame= true,
	script 					= "wallscript.lua",
	objectName        	= "brehmerwall.dae",

	name = "Wall",
	description = " divides & conquers",
	buildPic = "Brehmerwall.png",
	
	customparams = {
		helptext		= "MOSAIC Checkpoint",
		baseclass		= "Building",
		normaltex = "unittextures/CheckPoint_normal.dds",
    },
	
	
	category = [[GROUND BUILDING]],
	}



return lowerkeys({
	--Temp
	["Brehmerwall"] = Brehmerwall:New(),
	
})
