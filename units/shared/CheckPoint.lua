
local Checkpoint = Building:New{
	corpse				= "",
	maxDamage           = 500,
	mass                = 500,
	buildCostEnergy     = 500,
	buildCostMetal      = 100,
	explodeAs			= "none",


	buildTime =    60,
	Builder = true,
	nanocolor=[[0.20 0.411 0.611]], --
	CanReclaim=false,	
	workerTime = 0.0,
	YardMap = [[oooooooo
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				oooooooo
				]],

	MaxSlope = 50,
	MetalStorage = 2500,
	buildingMask = 8,
	footprintX = 8,
	footprintZ = 8,
	showNanoFrame = true,
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
	},

	onoffable = true,
	activatewhenbuilt = true,



return lowerkeys({
	--Temp
	["checkpoint"] = Checkpoint:New(),
	
})
