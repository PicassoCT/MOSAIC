local AIR_ARTILLERY = AIRCRAFT:New{

	name = "Icarus Gliderbomb",
	Description = "Burning the angles of orc fell/ Loitering Ammonition",
	objectName = "air_plane_artillery.dae",
	script = "airplaneartilleryscript.lua",
	buildPic = "air_sniper.png",
	iconType = "air_sniper",
	--floater = true,
	--cost
	buildCostMetal = 250,
	buildCostEnergy = 250,
	buildTime =  10,
	--Health
	maxDamage = 100,
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
	cruiseAlt = 1024 + 512,
	steeringmode        = [[1]],
	maneuverleashlength = 900,
	turnRadius		  	= 12,
	TurnRate = 350,

	dontLand		 	= true,
	Acceleration = 0.5,
	MaxVelocity = 2.5,
	MaxWaterDepth = 0,
	MovementClass = "AIRUNIT",
 
	nanocolor=[[0.20 0.411 0.611]],
	sightDistance = 400,
	CanFly   = true,
	activateWhenBuilt   	= true,
	MaxSlope 					= 75,
	--canHover=true,

	CanAttack = true,
	CanGuard = false,
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
	noChaseCategory = "GROUND BUILDING AIR",

	  customParams = {
	  	baseclass = "vtol",
	  	normaltex = "unittextures/component_atlas_normal.dds",
	  },

	weapons={	
			[1]={name  = "icarusglidebomb",
				onlyTargetCategory = [[GROUND]],
				turret= false
			},		
		},	
}

return lowerkeys({
	--Temp
	["air_plane_artillery"] = AIR_ARTILLERY:New(),
	
})
