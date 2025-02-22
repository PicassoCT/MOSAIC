
local AIRC_COPTER_ANTIARMOR = VTOL:New{
	name = "Airborne Anti Vehicle Drone ",
	Description = " Launches a Javeline ",
	
	objectName = "air_copter_antiarmor.dae",

	script = "airantiarmorscript.lua",
	buildPic = "air_antiarmour.png",
	iconType = "air_antiarmour",
	--floater = true,
	--cost
	buildCostMetal = 50,
	buildCostEnergy = 150,
	buildTime = 45,
	--Health
	maxDamage = 250,
	idleAutoHeal = 0,
	--Movement
	Acceleration = 0.5,
	 fireState=-1,
	BrakeRate = 1,
	FootprintX = 1,
	FootprintZ = 1,
	mass = 150,
	steeringmode        = [[1]],
	maneuverleashlength = 1380,
	turnRadius		  	= 8,
	dontLand		 	= false,
	MaxVelocity = 2.5,
	MaxWaterDepth = 0,
	MovementClass = "AIRUNIT",
	TurnRate = 450,
	nanocolor=[[0.20 0.411 0.611]],
	sightDistance = 640,
	CanFly   = true,
	activateWhenBuilt = true,
	MaxSlope  = 75,

	--canHover=true,
	CanAttack = true,
	CanGuard = true,
	CanMove = true,
	CanPatrol = true,
	Canstop  = true,

	onOffable = false,
	LeaveTracks = false, 
	cruiseAlt= 30,

	ActivateWhenBuilt=1,
	maxBank=0.4,
	myGravity =0.5,

	canSubmerge         = false,
	useSmoothMesh 		= true,
	collide             = true,
	crashDrag = 0.035,
	fireState = 1,

	Category = [[AIR]],

	  customParams = {
	  	baseclass ="vtol",
	  	normaltex = "unittextures/component_atlas_normal.dds",
	  },
	  
	 sfxtypes = {
		explosiongenerators = {
							"custom:bigbulletimpact"
							  },
				},
				
		weapons = {
				[1]={name  = "javelinrocket",
					onlyTargetCategory = [[BUILDING GROUND VEHICLE]],
					},
					
		},	
}

return lowerkeys({
	["air_copter_antiarmor"] = AIRC_COPTER_ANTIARMOR:New()	
})
