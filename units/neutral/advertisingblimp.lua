local advertising_blimp = VTOL:New{

	name = "Advertising Blimp ",

	objectName = "advertiseblimp.DAE",

	script = "advertisingblimpscript.lua",
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
	mass = 200,
	fireState = -1,
	BrakeRate = 1,
	FootprintX = 1,
	FootprintZ = 1,

	steeringmode        = [[1]],
	maneuverleashlength = 1380,
	turnRadius		  	= 80,
	dontLand		 	= true,
	useSmoothMesh  = true,
	Acceleration = 0.5,
	MaxVelocity = 0.1,
	MaxWaterDepth = 0,
	MovementClass = "AIRUNIT",
	TurnRate = 50,
	nanocolor=[[0.20 0.411 0.611]],
	sightDistance = 250,
	CanFly   = true,
	activateWhenBuilt   	= true,
	MaxSlope 					= 75,
	hoverAttack = true,
	airHoverFactor = 0.1,
	--canHover=true,
	CanAttack = true,
	CanGuard = true,
	CanMove = true,
	CanPatrol = true,
	Canstop  = true,
	onOffable = false,
	LeaveTracks = false, 
	ActivateWhenBuilt=1,
	maxBank=0.4,
	myGravity =0,
	maxElevator = 0,
	cruiseAlt = 314,
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
							


}

return lowerkeys({
	--Temp
	["advertising_blimp"] = advertising_blimp:New(),
	
})
