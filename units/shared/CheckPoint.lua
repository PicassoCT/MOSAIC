
local Checkpoint = Building:New{
	corpse				= "",
	maxDamage           = 500,
	mass                = 500,
	buildCostEnergy     = 5,
	buildCostMetal      = 5,
	explodeAs			= "none",


	buildTime =    60,
	Builder = true,
	nanocolor=[[0.20 0.411 0.611]], --
	CanReclaim=false,	
	workerTime = 0.0,
	YardMap = [[yooooooy
				yyyooyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyooyyy
				yooooooy]],

	MaxSlope 					= 50,
	MetalStorage = 2500,
	buildingMask = 8,
	footprintX = 8,
	footprintZ = 8,
	showNanoFrame= true,
	script 					= "checkpointscript.lua",
	objectName        	= "CheckPoint.dae",
		customParams        = {
		normaltex = "unittextures/CheckPoint_normal.dds",
	},
	name = "Checkpoint",
	description = " reveals any disguised unit",
	buildPic = "placeholder.png",
	usepiececollisionvolumes = false,
	
	customparams = {
		helptext		= "MOSAIC Checkpoint",
		baseclass		= "Building",
    },
	
	
	category = [[GROUND BUILDING]],
	}



return lowerkeys({
	--Temp
	["checkpoint"] = Checkpoint:New(),
	
})
