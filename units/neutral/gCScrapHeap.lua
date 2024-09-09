local unitName = "gCScrapHeap"

local unitDef = {
	name = "Ruined building",
	Description = " in a bad neighourhood",
	objectName = "gCScrapHeap.s3o",
	script = "gCScrapHeap.lua",
	buildPic = "placeholder.png",
	--cost
	buildCostMetal = 200,
	buildCostEnergy = 50,
	buildTime =1,
	--Health
	maxDamage = 999999999999,
	idleAutoHeal = 0,
	--Movement

	FootprintX = 5,
	FootprintZ = 5,

	--MaxVelocity = 0.5,
	MaxWaterDepth =400,

	sightDistance = 50,

	reclaimable=true,
	Builder = true,
	CanAttack = false,
	CanGuard = false,
	CanMove = false,
	CanPatrol = false,
	CanStop = false,

	Category = [[NOTARGET]],

	EnergyStorage = 0,
		EnergyUse = 75,
		MetalStorage = 0,
		EnergyMake = 0, 
		MakesMetal = 16, 
		MetalMake = 0,	
	  acceleration           = 0,
	  
	  levelGround            = false,
	  mass                   = 9900,
	  
	   customParams = {},
	


}
return lowerkeys({ [unitName] = unitDef })