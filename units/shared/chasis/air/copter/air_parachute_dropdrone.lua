
local AIRC_PARACHUTE_DROPDRONE = VTOL:New{
	name = "Airborne Parachute Drone",
	Description = " MOSAIC Standardized Gun Drone ",	
	objectName = "dropDroneParachute.DAE",	
	script = "parachute_drone_script.lua",
	buildPic = "placeholder.png",
	iconType = "air_iied",
	--cost
	buildCostMetal = 500,
	buildCostEnergy = 250,
	buildTime = 60,
	--Health
	maxDamage = 50,
	idleAutoHeal = 0,
	--Movement
	Acceleration = 0.5,
	fireState=-1,
	BrakeRate = 1,
	FootprintX = 1,
	FootprintZ = 1,
	steeringmode = [[1]],
	maneuverleashlength = 1380,
	turnRadius	= 8,
	dontLand = true,
	MaxVelocity = 2.5,
	MaxWaterDepth = 0,
	MovementClass = "AIRUNIT",
	TurnRate = 900,
	nanocolor=[[0.20 0.411 0.611]],
	sightDistance = 250,
	CanFly   = true,
	activateWhenBuilt   	= true,

	--canHover=true,
	CanAttack = true,
	CanGuard = true,
	CanMove = true,
	CanPatrol = true,
	Canstop  = true,
	onOffable = false,
	LeaveTracks = false, 
	cruiseAlt= 150,

	maxBank = 0.4,
	myGravity = 0.5,
	mass                = 350,
	canSubmerge         = false,
	useSmoothMesh 		=true,
	collide             = true,
	crashDrag = 0.035,
	Category = [[AIR]],

	customparams = {
				  	baseclass ="vtol",
				  	normaltex = "unittextures/component_atlas_normal.dds",
	  				},
	  
	 sfxtypes = {
		explosiongenerators = {
							"custom:bigbulletimpact"
							  },
				},	

	weapons = 	{
				[1]={
						name = "machinegun",
						onlyTargetCategory = [[BUILDING GROUND]],
						turret = true
					},				
				},	
}

return lowerkeys({
	--Temp
	["air_parachut_dropdrone"] = AIRC_PARACHUTE_DROPDRONE:New()
	
})