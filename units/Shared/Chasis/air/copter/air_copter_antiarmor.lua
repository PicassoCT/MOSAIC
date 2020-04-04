
local AIRC_COPTER_ANTIARMOR = VTOL:New{
	name = "Airborne Anti Vehicle Drone ",
	Description = " Launches a Javeline ",
	
	objectName = "air_copter_antiarmor.dae",
		customParams        = {
		normaltex = "unittextures/component_atlas_normal.png",
	},
	script = "airantiarmorscript.lua",
	buildPic = "placeholder.png",
	--floater = true,
	--cost
	buildCostMetal = 50,
	buildCostEnergy = 0,
	buildTime = 1*45,
	--Health
	maxDamage = 50,
	idleAutoHeal = 0,
	--Movement
	Acceleration = 0.5,
	 fireState=1,
	BrakeRate = 1,
	FootprintX = 1,
	FootprintZ = 1,

	steeringmode        = [[1]],
	maneuverleashlength = 1380,
	turnRadius		  	= 8,
	dontLand		 	= false,
	MaxVelocity = 2.5,
	MaxWaterDepth = 0,
	MovementClass = "Default2x2",
	TurnRate = 450,
	nanocolor=[[0.20 0.411 0.611]],
	sightDistance = 1024+128,
	CanFly   = true,
	activateWhenBuilt   	= true,
	MaxSlope 					= 75,

	--canHover=true,
	CanAttack = true,
	CanGuard = true,
	CanMove = true,
	CanPatrol = true,
	Canstop  = true,
	onOffable = false,
	LeaveTracks = false, 
	cruiseAlt= 15,

	ActivateWhenBuilt=1,
	maxBank=0.4,
	myGravity =0.5,
	mass                = 150,
	canSubmerge         = false,
	useSmoothMesh 		=true,
	collide             = true,
	crashDrag =0.035,


	Category = [[AIR]],

	  customParams = {
	  baseclass ="vtol"
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
	--Temp
	["air_copter_antiarmor"] = AIRC_COPTER_ANTIARMOR:New()
	
})
