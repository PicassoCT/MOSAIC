
local Assembly = Building:New{
	corpse				= "",
	maxDamage           = 500,
	mass                = 500,
	buildCostEnergy     = 5,
	buildCostMetal      = 5,
	explodeAs			= "none",



	Builder = true,
	nanocolor=[[0 0 0]], --
	CanReclaim=false,	
	workerTime = 0.05,
	YardMap ="oooo oooo oooo oooo ",
	MaxSlope 					= 50,

	footprintX = 4,
	footprintZ = 4,
	
	script 					= "assemblyscript.lua",
	objectName        	= "assembly.s3o",
	name = "Assembly",
	description = " create Standardized Robots <Automated Factory>",

	canCloak =true,
	cloakCost=0.0001,
	ActivateWhenBuilt=1,
	cloakCostMoving =0.0001,
	minCloakDistance = 0,
	onoffable=true,
	initCloaked = true,
	decloakOnFire = true,
	cloakTimeout = 5,

	
	customparams = {
		helptext		= "MOSAIC Assembly",
		baseclass		= "Building",
    },
	
		buildoptions = 
	{
	"airssied"	
	},
	

	}



return lowerkeys({
	--Temp
	["assembly"] = Assembly:New(),
	
})