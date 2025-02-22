
local AIR_COPTER_AEROSOL = VTOL:New{

	objectName = "air_copter_aerosol.dae",

	
	description 		= "sprays arerosols to influence people",
	script 				= "air_copter_aerosolscript.lua",
	buildPic 			= "AeroSolDrone.png",
	iconType 			= "AeroSolDrone",
	--floater = true,
	--cost
	buildCostMetal 		= 250,
	buildCostEnergy 	= 1500,
	buildTime 			= 1*60,
	--Health
	maxDamage 			= 250,
	idleAutoHeal 		= 0,
	--Movement
	Acceleration 		= 0.5,
	 fireState 			= 1,
	BrakeRate 			= 1,
	FootprintX 			= 1,
	FootprintZ 			= 1,

	steeringmode        = [[1]],
	maneuverleashlength = 1380,
	turnRadius		  	= 8,
	dontLand		 	= true,
	MaxVelocity 		= 2,
	MaxWaterDepth 		= 0,
	MovementClass 		= "AIRUNIT",
	TurnRate 			= 1450,
	nanocolor 			= [[0.20 0.411 0.611]],
	sightDistance 		= 250 +128,
	CanFly   			= true,
	activateWhenBuilt 	= true,
	MaxSlope 			= 90,

	canHover			=true,
	CanAttack 			= true,
	CanGuard 			= true,
	CanMove 			= true,
	CanPatrol 			= true,
	Canstop  			= true,
	onOffable 			= true,
	LeaveTracks 		= false, 
	cruiseAlt			= 128,

	ActivateWhenBuilt	= 0,
	maxBank				= 0.4,
	myGravity 			= 0.5,
	mass                = 250,
	canSubmerge         = false,
	useSmoothMesh 		= true,
	collide             = true,
	crashDrag 			= 0.035,

	Category = [[AIR]],

	  customParams = {
	  baseclass ="vtol",
	  normaltex = "unittextures/component_atlas_normal.dds",
	  },
	  
	 sfxtypes = {
		explosiongenerators = {
							"custom:depressol" ,
							"custom:tollwutox" ,
							"custom:orgyanyl"  ,
							"custom:wanderlost",
							
							  },
				},

}

AIR_COPTER_AEROSOL_ORGYANYL = AIR_COPTER_AEROSOL:New()
AIR_COPTER_AEROSOL_ORGYANYL.name, AIR_COPTER_AEROSOL_ORGYANYL.description ="Aerosoldrone: Orgyanyl", "Makes citizens copulate to death"

AIR_COPTER_AEROSOL_WANDERLOST = AIR_COPTER_AEROSOL:New()
AIR_COPTER_AEROSOL_WANDERLOST.name, AIR_COPTER_AEROSOL_WANDERLOST.description ="Aerosoldrone: Wanderlost", "Makes citizens wander aimless till death"

AIR_COPTER_AEROSOL_TOLLWUTOX = AIR_COPTER_AEROSOL:New()
AIR_COPTER_AEROSOL_TOLLWUTOX.name, AIR_COPTER_AEROSOL_TOLLWUTOX.description ="Aerosoldrone: Tollwutox", "Makes citizens dangerously aggressive"

AIR_COPTER_AEROSOL_DEPRESSOL = AIR_COPTER_AEROSOL:New()
AIR_COPTER_AEROSOL_DEPRESSOL.name, AIR_COPTER_AEROSOL_DEPRESSOL.description ="Aerosoldrone: Depressol", "Makes citizens catatonic till suicide"


return lowerkeys({
	--Temp
	["air_copter_aerosol_orgyanyl"] = AIR_COPTER_AEROSOL_ORGYANYL,
	["air_copter_aerosol_wanderlost"] = AIR_COPTER_AEROSOL_WANDERLOST,
	["air_copter_aerosol_tollwutox"] = AIR_COPTER_AEROSOL_TOLLWUTOX,
	["air_copter_aerosol_depressol"] = AIR_COPTER_AEROSOL_DEPRESSOL,	
})
