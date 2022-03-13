local AIRC_COPTER_MG = VTOL:New{

	name = "Airborne Machinegun Drone ",
	Description = " harasses ground units ",
	objectName = "air_copter_mg.dae",

	script = "air_copter_mg_script.lua",
	buildPic = "air_gun.png",
	iconType = "air_gun",
	--floater = true,
	--cost
	buildCostMetal = 500,
	buildCostEnergy = 250,
	buildTime = 30,
	--Health
	maxDamage = 250,
	idleAutoHeal = 0,
	--Movement
	
	fireState = -1,
	BrakeRate = 1,
	FootprintX = 1,
	FootprintZ = 1,

	steeringmode        = [[1]],
	maneuverleashlength = 1380,
	turnRadius		  	= 8,
	dontLand		 	= false,
	Acceleration = 0.5,
	MaxVelocity = 2.5,
	MaxWaterDepth = 0,
	MovementClass = "AIRUNIT",
	TurnRate = 450,
	nanocolor=[[0.20 0.411 0.611]],
	sightDistance = 250,
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
	cruiseAlt= 42,

	ActivateWhenBuilt=1,
	maxBank=0.4,
	myGravity =0.5,
	mass                = 150,
	canSubmerge         = false,
	useSmoothMesh 		=false,
	collide             = true,
	crashDrag =0.035,


	Category = [[AIR]],

	  customParams = {
	  	baseclass = "vtol",
	  	normaltex = "unittextures/component_atlas_normal.dds",
	  },
	 sfxtypes = {
		explosiongenerators = {
							"custom:bigbulletimpact"
							  },
				},
				
				weapons = {
				[1]={name  = "machinegun",
					onlyTargetCategory = [[BUILDING GROUND]],
					},
					
		},	

			


}

return lowerkeys({
	--Temp
	["air_copter_mg"] = AIRC_COPTER_MG:New(),
	
})
