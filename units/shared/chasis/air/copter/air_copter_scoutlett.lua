
local AIRC_COPTER_SCOUTLET = VTOL:New{
	name = "Airborne Scout Copter ",
	Description = "  ",	
	objectName = "air_copter_scoutlett.dae",
	script = "aircopterscoutlettscript.lua",
	buildPic = "air_antiarmour.png",
	iconType = "air_antiarmour",
	--floater = true,
	--cost
	buildCostMetal = 50,
	buildCostEnergy = 50,
	buildTime = 10,
	mass = 50,
	--Health
	maxDamage = 50,
	idleAutoHeal = 0,
	--Movement
	Acceleration = 0.5,
	 fireState=-1,
	BrakeRate = 0.03,
	FootprintX = 1,
	FootprintZ = 1,

	steeringmode        = [[1]],
	maneuverleashlength = 500,
	turnRadius		  	= 42,
	dontLand		 	= false,

	MaxVelocity = 3.5,
	MaxWaterDepth = 0,
	MovementClass = "AIRUNIT",
	TurnRate = 450,
	nanocolor=[[0.20 0.411 0.611]],
	sightDistance =  128,
	CanFly   = true,
	activateWhenBuilt = true,
	MaxSlope  = 75,

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
	useSmoothMesh 		= true,
	collide             = true,
	crashDrag = 0.035,

	Category = [[AIR]],

	  customParams = {
	  	baseclass ="vtol",
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
	["air_copter_scoutlett"] = AIRC_COPTER_SCOUTLET:New()
	
})
