
local AIR_COPTER_AEROSOL = VTOL:New{
	name = "Airborne Aerosol Distribution Vehicle",
	Description = " Launches a Javeline ",
	
	objectName = "air_copter_aerosol.dae",
	script = "air_copter_aerosolscript.lua",
	buildPic = "placeholder.png",
	--floater = true,
	--cost
	buildCostMetal = 5000,
	buildCostEnergy = 0,
	buildTime = 3*60,
	--Health
	maxDamage = 250,
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
	dontLand		 	= true,
	MaxVelocity = 2,
	MaxWaterDepth = 0,
	MovementClass = "Default2x2",
	TurnRate = 1450,
	nanocolor=[[0 0.9 0.9]],
	sightDistance = 1024+128,
	CanFly   = true,
	activateWhenBuilt   	= true,
	MaxSlope 					= 90,

	canHover=true,
	CanAttack = true,
	CanGuard = true,
	CanMove = true,
	CanPatrol = true,
	Canstop  = true,
	onOffable = true,
	LeaveTracks = false, 
	cruiseAlt= 128,

	ActivateWhenBuilt=1,
	maxBank=0.4,
	myGravity =0.5,
	mass                = 250,
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
				[1]={name  = "orgyanyl",
					onlyTargetCategory = [[GROUND VEHICLE]],
					},
				[2]={name  = "toolwutox",
					onlyTargetCategory = [[GROUND VEHICLE]],
					},
				[3]={name  = "depressol",
					onlyTargetCategory = [[GROUND VEHICLE]],
					},	
				[4]={name  = "wanderlost",
					onlyTargetCategory = [[GROUND VEHICLE]],
					},	
		},	

			


}

return lowerkeys({
	--Temp
	["air_copter_aerosol"] = AIR_COPTER_AEROSOL :New()
	
})
