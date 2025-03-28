local AIR_PARACHUT = VTOL:New{

	name = "EGP ",
	Description = "Electrostatic Graphene Parachut",
	objectName = "air_parachut.dae",

	script = "parachutscript.lua",
	buildPic = "parachute.png",

	--floater = true,
	--cost
	buildCostMetal = 50,
	buildCostEnergy = 0,
	buildTime = 5,
	--Health
	maxDamage = 50,
	idleAutoHeal = 0,
	--Movement
	mass = 25,
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
	MovementClass = "AIRUNIT",
	TurnRate = 450,
	nanocolor=[[0.20 0.411 0.611]],
	sightDistance = 250,
	CanFly   = true,
	activateWhenBuilt   	= true,
	MaxSlope 					= 75,
	releaseHeld = true,
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
	canSubmerge         = false,
	useSmoothMesh 		=false,
	collide             = true,
	crashDrag =0.035,

	canCloak =false,
	--cloakCost=0.0001,
	--cloakCostMoving =0.0001,
	--cloakCostMoving = 0,
	--minCloakDistance = 0,
	--initCloaked = true,

	Category = [[AIR]],

	  customParams = {
	  	baseclass = "vtol",
	  	normaltex = "unittextures/component_atlas_normal.dds",
	  },


			


}

return lowerkeys({
	--Temp
	["air_parachut"] = AIR_PARACHUT:New(),
	
})
