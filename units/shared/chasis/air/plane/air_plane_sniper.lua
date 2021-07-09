local AIR_SNIPER = AIRCRAFT:New{

	name = "Predator VII",
	Description = "sniper drone",
	objectName = "air_plane_sniper.dae",
		customParams        = {
		normaltex = "unittextures/component_atlas_normal.dds",
	},
	script = "airplanesniperscript.lua",
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
	autoLand = false,
	dontLand		 	= true,
	Acceleration = 0.5,
	MaxVelocity = 2.5,
	MaxWaterDepth = 0,
	MovementClass = "Default2x2",
	TurnRate = 350,
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
	Canstop  = false,
	onOffable = false,
	LeaveTracks = false, 

	canSubmerge         = false,
	useSmoothMesh 		=true,
	collide             = true,
	crashDrag =0.035,


	Category = [[AIR]],
	noChaseCategory = "GROUND BUILDING AIR",

	  customParams = {
	  baseclass = "vtol"
	  },

	weapons={	
			[1]={name  = "sniperrifle",
				onlyTargetCategory = [[GROUND BUILDING]],
				turret= false
			},
			[2]={name  = "sniperrifle",
				onlyTargetCategory = [[GROUND ]],			
				turret= false			}
		},
	
}

return lowerkeys({
	--Temp
	["air_plane_sniper"] = AIR_SNIPER:New(),
	
})
