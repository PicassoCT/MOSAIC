local unitName = "tankcorpse"

local unitDef = {
	name = "Destroyed Tank",
	Description = "!",
	objectName = "tankwreckage.dae",
	script = "tankwreckagescript.lua",
	buildPic = "placeholder.png",
	--cost
	buildCostMetal = 200,
	buildCostEnergy = 50,
	buildTime =1,
	--Health
	maxDamage = 6666,
	idleAutoHeal = 0,
	--Movement

	FootprintX = 2,
	FootprintZ = 2,

	--MaxVelocity = 0.5,
	MaxWaterDepth =400,
	--MovementClass = "Default2x2",--

	cantBeTransported=false,

	transportByEnemy =false,
	sightDistance = 50,

	reclaimable=false,
	Builder = false,
	CanAttack = false,
	CanGuard = false,
	CanMove = false,
	CanPatrol = false,
	CanStop = false,

	Category = [[NOTARGET]],

	EnergyStorage = 0,
		EnergyUse = 0,
		MetalStorage = 0,
		EnergyMake = 0, 
		MakesMetal = 0, 
		MetalMake = 0,	
	  acceleration           = 0,
	  
	  levelGround            = false,
	  mass                   = 9900,  

	   customParams = {},
	 sfxtypes = {
					explosiongenerators = {
					   "custom:330rlexplode",
					   "custom:flames",
					   "custom:glowsmoke",
					   "custom:blackerThenSmoke",
					   "custom:vehsmokepillar",
					   "custom:vortflames",--1029
					   "custom:volcanolightsmall",--1030
						"custom:cburningwreckage",--1031
					},

	},


}
return lowerkeys({ [unitName] = unitDef })