local unitName = "cegtest"

local unitDef = {
	name = "cegtestunit",
	Description = "Testing the Cegs all day long",
	objectName = "placeholder.s3o",
	script = "placeholder.lua",
	buildPic = "placeholder.png",
	levelGround =false,
	--cost
	buildCostMetal = 15,
	buildCostEnergy = 1,
	buildTime = 1,
	--Health
	maxDamage = 6660,
	idleAutoHeal = 15,
	autoheal=10,
	--Movement
	mass=180020,
	upRight=true,
	blocking=false,
	pushResistant=true,
	Acceleration = 0.0000001,
	BrakeRate = 0.0001,
	FootprintX = 1,
	FootprintZ = 1,
	
	
	MaxSlope = 90,
	MaxVelocity = 0.000001,
	MaxWaterDepth = 55,
	MovementClass = "TANK",
	TurnRate = 1,
	
	sightDistance = 80,
	
	reclaimable=false,
	Builder = false,
	CanAttack = true,
	CanGuard = false,
	CanMove = true,
	CanPatrol = false,
	CanStop = true,
	LeaveTracks = false,
	useSmoothMesh = false,
	

	
	customParams = {},
	sfxtypes = {
		explosiongenerators = {
			"custom:glowingshrapnell",

			
		},
		
	},
	
	
	
	weapons = {

		[1]={name = "slicergun",
			
			onlyTargetCategory = [[GROUND]],
		},
			[2]={name = "jbeanstalkshield",
		},

		
	},
	Category = [[GROUND]],
	
	
	
	
}

return lowerkeys({ [unitName] = unitDef })