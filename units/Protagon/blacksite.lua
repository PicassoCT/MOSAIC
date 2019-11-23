local BlackSite = Building:New{
	corpse				= "",
	maxDamage           = 500,
	mass                = 500,
	buildCostEnergy     = 5,
	buildCostMetal      = 5,
	explodeAs			= "none",

	buildtime			 = 2*60,

	Builder = true,
	nanocolor=[[0 0 0]], --
	CanReclaim=false,	
	workerTime = 0.005,
	YardMap ="oooo oooo oooo oooo ",
	MaxSlope 					= 50,

	footprintX = 4,
	footprintZ = 4,
	buildingMask = 8,
	
	script 					= "blacksitescript.lua",
	objectName        	= "placeholder.s3o",
	name = "BlackSite",
	description = "creates aerosol drones",

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
		helptext		= "Aerosol drone center",
		baseclass		= "Building", -- TODO: hacks
    },
	
		buildoptions = 
	{
		"air_copter_aerosol_orgyanyl",
		"air_copter_aerosol_wanderlost",
		"air_copter_aerosol_tollwutox", 
		"air_copter_aerosol_depressol" 
		
	},
	category = [[GROUND BUILDING ARRESTABLE]],
}

return lowerkeys(
	{
	["blacksite"] = BlackSite:New()	
	}
)