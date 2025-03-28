local unitName = "truckpayload"

	local unitDef = {
	name = "",
	Description = "truckpayload", 
	objectName = "truckPayload.dae",
	script = "truckPayloadScript.lua",
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
	mass=2020,
	upRight=true,
	blocking=false,

	FootprintX = 1,
	FootprintZ = 1,
	cantBeTransported = false,

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
	usePieceCollisionVolumes = false,
	 
	customParams = {
	  	normaltex = "unittextures/house_arab_normal.dds",
	  },
	 sfxtypes = {
		explosiongenerators = {	    
							  },
		
				},

	 
	 
	Category = [[GROUND BUILDING]],




}

return lowerkeys({ [unitName] = unitDef })