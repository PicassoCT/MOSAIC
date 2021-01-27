
local Brehmerwall = Building:New{
	corpse				= "",
	maxDamage           = 10000,
	mass                = 500,
	buildCostEnergy     = 100,
	buildCostMetal      = 50,
	explodeAs			= "none",


	buildTime =    60,
	Builder = true,
	nanocolor=[[0.20 0.411 0.611]], --
	CanReclaim=false,	
	workerTime = 0.065,
	YardMap =    [[oo
				   oo
				   oo
				   oo]],

	MaxSlope = 50,
	MetalStorage = 2500,
	buildingMask = 8,
	footprintX = 2,
	footprintZ = 4,
	showNanoFrame= true,
	script 					= "placeholder.lua",
	objectName        	= "brehmerwall.dae",

	name = "Wall",
	description = " divides & conquers",
	buildPic = "placeholder.png",
	
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
