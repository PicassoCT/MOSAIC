local unitName = "airssied"

local unitDef = {
	name = "SSIED",
	Description = "Standardized Smart Improvised Explosive Device ",
	objectName = "ssied.s3o",
	script = "airssiedscript.lua",
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
	Acceleration = 0.5,
	 fireState=1,
	BrakeRate = 1,
	FootprintX = 1,
	FootprintZ = 1,
	TEDClass            = "AIRUNIT",
	steeringmode        = [[1]],
	maneuverleashlength = 1380,
	turnRadius		  	= 8,
	dontLand		 	= false,
	MaxVelocity = 2.5,
	MaxWaterDepth = 0,
	MovementClass = "Default2x2",
	TurnRate = 150,
	nanocolor=[[0 0.9 0.9]],
	sightDistance = 250,
	CanFly   = true,

	Builder = true,
	--canHover=true,
	CanAttack = false,
	CanGuard = true,
	CanMove = true,
	CanPatrol = true,
	Canstop  = false,
	onOffable = true,
	LeaveTracks = false, 
	cruiseAlt= 25,

	ActivateWhenBuilt=1,
	maxBank=0.4,
	myGravity =0.5,
	mass                = 150,
	canSubmerge         = false,
	useSmoothMesh 		=false,
	collide             = true,
	crashDrag =0.035,


	Category = [[AIR]],

	  customParams = {},
	 sfxtypes = {
		explosiongenerators = {
							"custom:bigbulletimpact"
							  },
				},
				
				weapons = {
				[1]={name  = "ssied",
					onlyTargetCategory = [[BUILDING LAND]],
					},
					
		},	

			


}

return lowerkeys({ [unitName] = unitDef })