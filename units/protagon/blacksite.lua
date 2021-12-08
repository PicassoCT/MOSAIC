local BlackSite = Building:New{
	corpse				= "",
	maxDamage           = 500,
	mass                = 500,
	buildCostEnergy     = 5000,
	buildCostMetal      = 2500,
	explodeAs			= "none",

	buildtime			 = 2*60,
	showNanoFrame= true,
	Builder = true,
	nanocolor=[[0.20 0.411 0.611]],--
	CanReclaim=false,	
	workerTime = 1,
	YardMap ="oooo oooo oooo oooo ",
	MaxSlope 					= 50,

	footprintX = 4,
	footprintZ = 4,
	buildingMask = 8,
	
	script 					= "blacksitescript.lua",
	objectName        	= "blacksite.dae",
		customParams        = {
		normaltex = "unittextures/component_atlas_normal.dds",
	},
	buildPic = "blacksite.png",
	iconType = "blacksite",
	name = "BlackSite",
	description = "creates aerosol drones",

	canCloak =true,
	cloakCost=0.0001,
	ActivateWhenBuilt=1,
	cloakCostMoving =0.0001,
	minCloakDistance = -1.0,
	onoffable=true,
	initCloaked = true,
	decloakOnFire = false,
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
  category =  [[GROUND BUILDING RAIDABLE]],
}

return lowerkeys(
	{
	["blacksite"] = BlackSite:New()	
	}
)