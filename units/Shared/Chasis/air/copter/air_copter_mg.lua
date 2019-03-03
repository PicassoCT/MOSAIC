local AIRC_COPTER_MG = VTOL:New{

	name = "Airborne machinegun Drone ",
	Description = " MOSAIC Standardized Drone ",
	objectName = "aircoptermg.s3o",
	script = "aircoptermgscript.lua",
	buildPic = "placeholder.png",
	--floater = true,
	--cost
	buildCostMetal = 50,
	buildCostEnergy = 0,
	buildTime = 5,
	--Health
	maxDamage = 50,
	idleAutoHeal = 0,
	--Movement
	
	 fireState=1,
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
	MovementClass = "Default2x2",
	TurnRate = 450,
	nanocolor=[[0 0.9 0.9]],
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
	  baseclass = "vtol"
	  },
	 sfxtypes = {
		explosiongenerators = {
							"custom:bigbulletimpact"
							  },
				},
				
				weapons = {
				[1]={name  = "machinegun",
					onlyTargetCategory = [[BUILDING LAND]],
					},
					
		},	

			


}

return lowerkeys({
	--Temp
	["air_copter_mg"] = AIRC_COPTER_MG:New(),
	
})
