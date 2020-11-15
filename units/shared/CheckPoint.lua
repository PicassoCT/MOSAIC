
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
	workerTime = 0.065,
	YardMap ="yyyy yyyy yyyy yyyy ",
	MaxSlope 					= 50,
	MetalStorage = 2500,
	buildingMask = 8,
	footprintX = 4,
	footprintZ = 4,
	showNanoFrame= true,
	script 					= "placeholderscript.lua",
	objectName        	= "placeholder.s3o",
		customParams        = {
		normaltex = "unittextures/component_atlas_normal.dds",
	},
	name = "Checkpoint",
	description = " reveals any disguised personal",
	buildPic = "placeholder.png",
	canCloak =true,
	canMove = true,
	cloakCost=0.0001,
	ActivateWhenBuilt=1,
	cloakCostMoving =0.0001,
	minCloakDistance = 0,
	onoffable=true,
	initCloaked = true,
	decloakOnFire = true,
	cloakTimeout = 5,

	
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
