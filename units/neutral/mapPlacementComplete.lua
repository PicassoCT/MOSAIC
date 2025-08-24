local unitName = "map_placements_complete"

local unitDef = {
	name = "map_placements_complete",
	Description = "unit communicates by existing",
	objectName = "placeholder.s3o",
	script = "map_placements_completescript.lua",
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
	
	

	Category = [[GROUND]],
	
	
	
	
}

return lowerkeys({ [unitName] = unitDef })