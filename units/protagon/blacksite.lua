local BlackSite = Building:New{
	corpse				= "",
	maxDamage           = 1500,
	mass                = 500,
	buildCostEnergy     = 5000,
	buildCostMetal      = 2500,
	explodeAs			= "none",

	UnitRestricted = 1,
    buildtime			= 5*60,
	showNanoFrame		= true,
	Builder 			= true,
	nanocolor			= [[0.20 0.411 0.611]],--
	CanReclaim			= false,	
	workerTime 			= 1,
	YardMap 			= "oooo oooo oooo oooo ",
	maxSlope 			= 50.0,
	levelGround 		= false,
	blocking 			= false,
	footprintX 			= 4,
	footprintZ 			= 4,
	buildingMask 		= 8,
	
	script 				= "blacksitescript.lua",
	objectName        	= "blacksite.dae",
	customParams  = {
		normaltex = "unittextures/component_atlas_normal.dds",
	},
	buildPic 			= "blacksite.png",
	iconType 			= "blacksite",
	name 				= "BlackSite",
	description 		= "creates aerosol drones",

	canCloak 			= true,
	cloakCost 			= 0.0001,
	ActivateWhenBuilt	= 1,
	cloakCostMoving 	= 0.0001,
	minCloakDistance 	= -1.0,
	onoffable			= true,
	initCloaked 		= true,
	decloakOnFire 		= false,
	cloakTimeout 		= 5,

	usepiececollisionvolumes 	= false,
  	collisionVolumeType 		= "box",
  	collisionvolumescales 		= "100 70 100",
  	collisionVolumeOffsets  	= {0.0, 30.0,  0.0},

	customparams = {
		helptext		= "Aerosol drone center",
		baseclass		= "Building", -- TODO: hacks
    },
	
	buildoptions = 
	{
		"air_copter_aerosol_orgyanyl" ,
		"air_copter_aerosol_wanderlost" ,
		"air_copter_aerosol_tollwutox" , 
		"air_copter_aerosol_depressol" ,
		"biopayload"
		
	},
  category =  [[GROUND BUILDING RAIDABLE]],
}

return lowerkeys(
	{
	["blacksite"] = BlackSite:New()	
	}
)
