
local Checkpoint = Building:New{
	corpse				= "",
	maxDamage           = 500,
	mass                = 5000,
	buildCostEnergy     = 500,
	buildCostMetal      = 100,
	explodeAs			= "none",


	buildTime =    40,
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
	buildingMask = 1,			
	maxSlope = 50.0,
	levelGround = false,
	blocking =false,
	MetalStorage = 2500,
	footprintX = 8,
	footprintZ = 8,

	usepiececollisionvolumes = false,
  	collisionVolumeType = "box",
  	collisionvolumescales = "100 50 100",
  	collisionVolumeOffsets  = {0.0, 25.0,  0.0},

	showNanoFrame = true,
	script 					= "checkpointscript.lua",
	objectName        	= "CheckPoint.dae",

	name = "Checkpoint",
	description = " reveals any disguised unit",
	buildPic = "CheckPoint.png",
	usepiececollisionvolumes = false,
	
	customparams = {
		helptext		= "MOSAIC Checkpoint",
		baseclass		= "Building",
		normaltex = "unittextures/CheckPoint_normal.dds",
    },
	
	onoffable = true,
	activatewhenbuilt = true,

	category = [[GROUND BUILDING]],
	}



return lowerkeys({
	--Temp
	["checkpoint"] = Checkpoint:New(),
	
})
