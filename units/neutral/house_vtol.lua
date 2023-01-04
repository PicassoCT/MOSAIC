local house_vtol = VTOL:New{

	name = " civilian vtol plane ",

	objectName = "house_western_vtol.dae",

	script = "housevtolscript.lua",
	
	--floater = true,
	--cost
	buildCostMetal = 500,
	buildCostEnergy = 250,
	buildTime = 30,
	--Health
	maxDamage = 250,
	idleAutoHeal = 0,
	--Movement
	mass = 200,
	fireState = -1,
	BrakeRate = 1,
	FootprintX = 1,
	FootprintZ = 1,

	steeringmode        = [[1]],
	maneuverleashlength = 1380,
	turnRadius		  	= 80,
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
	cruiseAlt= 542,

	ActivateWhenBuilt=1,
	maxBank=0.4,
	myGravity =0.5,
	canSubmerge         = false,
	useSmoothMesh 		=false,
	collide             = false,
	crashDrag =0.035,


	Category = [[AIR]],

	  customParams = {
	  	baseclass = "vtol",
	  	normaltex = "unittextures/house_europe_normal.dds",
	  },

}

return lowerkeys({
	--Temp
	["house_vtol"] = house_vtol:New(),
	
})
