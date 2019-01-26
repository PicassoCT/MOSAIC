local unitName = "gcvehiccorpsemini"

local unitDef = {
	name = "burned out Vehicle",
	Description = "Where towers in ruins lie",
	objectName = "cvehicorpsemini.s3o",
	script = "gCVehicScrap.lua",
	buildPic = "placeholder.png",
	--cost
	buildCostMetal = 200,
	buildCostEnergy = 50,
	buildTime =1,
	--Health
	maxDamage = 666,
	idleAutoHeal = 0,
	--Movement
	
	FootprintX = 1,
	FootprintZ = 1,
	
	--MaxVelocity = 0.5,
	MaxWaterDepth =400,
	--MovementClass = "Default2x2",--
	
	cantBeTransported=false,
	
	transportByEnemy =true,
	sightDistance = 50,
	
	reclaimable=true,
	Builder = false,
	CanAttack = false,
	CanGuard = false,
	CanMove = false,
	CanPatrol = false,
	CanStop = false,
	
	
	
	-- Building	
	
	
	
	
	
	
	
	
	
	Category = [[NOTARGET]],
	
	EnergyStorage = 0,
	EnergyUse = 0,
	MetalStorage = 0,
	EnergyMake = 0, 
	MakesMetal = 0, 
	MetalMake = 0,	
	acceleration = 0,
	
	
	-- bmcode = [[0]],
	
	--
	
	
	--extractsMetal = 0.005,
	--floater = false,
	
	
	
	levelGround = false,
	mass = 9900,
	
	
	
	
	
	
	
	-- TEDClass = [[METAL]],
	
	customParams = {},
	sfxtypes = {
		explosiongenerators = {
			"custom:330rlexplode",
			"custom:flames",
			"custom:glowsmoke",
			"custom:vehsmokepillar",
			"custom:vehsmokepillar",
			"custom:vortflames",--1029
			"custom:volcanolightsmall",--1030
			"custom:cburningwreckage",--1031
			--
			--Bulletof The Cannon
		},
		
	},
	
	
}
return lowerkeys({ [unitName] = unitDef })