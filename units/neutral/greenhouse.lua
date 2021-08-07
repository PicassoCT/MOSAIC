local unitName = "greenhouse"

	local unitDef = {
	name = "Greenhouse",
	Description = "",
	objectName = "GreenHouse.dae",
	script = "greenhousescript.lua",
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
	mass=18020,
	upRight=true,
	blocking=false,
	pushResistant=true,
	Acceleration = 0.0000001,
	BrakeRate = 0.0001,
	FootprintX = 4,
	FootprintZ = 4,


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


	 
	  customParams = {
				normaltex = "unittextures/house_arab_normal.dds",
	  },
	  
	 sfxtypes = {
		explosiongenerators = {	    
							  },
				},
	Category = [[NOTARGET]],

}

return lowerkeys({ [unitName] = unitDef })