local AIR_ROCKET = AIRCRAFT:New{

	name = "Predator VII",
	Description = "rocket drone",
	objectName = "air_plane_rocket.dae",
	script = "airplanerocketscript.lua",
	buildPic = "air_sniper.png",
	iconType = "air_sniper",
	--floater = true,
	--cost
	buildCostMetal = 750,
	buildCostEnergy = 1000,
	buildTime =  2*60,
	--Health
	maxDamage = 500,
	idleAutoHeal = 0,
	--Movement
	
	 fireState=-1,
	BrakeRate = 1,
	FootprintX = 1,
	FootprintZ = 1,
	ActivateWhenBuilt=0,
	maxBank=0.4,
	myGravity =0.5,
	mass = 1225,
	cruiseAlt = 512,
	steeringmode        = [[1]],
	maneuverleashlength = 1380,
	turnRadius		  	= 8,
	dontLand		 	= true,
	Acceleration = 0.5,
	MaxVelocity = 2.5,
	MaxWaterDepth = 0,
	MovementClass = "AIRUNIT",
	TurnRate = 350,
	nanocolor=[[0.20 0.411 0.611]],
	sightDistance = 400,
	CanFly   = true,
	activateWhenBuilt   	= true,
	MaxSlope 					= 75,
	--canHover=true,

	CanAttack = true,
	CanGuard = true,
	CanMove = true,
	CanPatrol = true,
	Canstop  = false,
	onOffable = false,
	LeaveTracks = false, 
	crashDrag = 0.02,
	canCrash=true,
	canSubmerge         = false,
	useSmoothMesh 		=true,
	collide             = true,
	crashDrag =0.035,
	fireState = 1,


	Category = [[AIR]],
	noChaseCategory = "ABSTRACT",

	  customParams = {
	  	baseclass = "vtol",
	  	normaltex = "unittextures/component_atlas_normal.dds",
	  },

	weapons={	
			[1]={name  = "s16rocket",
				onlyTargetCategory = [[GROUND]],
				turret= false
			},
			[2]={name  = "targetlaser",
				onlyTargetCategory = [[GROUND]],
				turret= true
			},
		
		},
	
}

return lowerkeys({
	--Temp
	["air_plane_rocket"] = AIR_ROCKET:New(),
	
})
