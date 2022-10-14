local unitName = "civilianloot"

	local unitDef = {
	name = "",
	Description = "it just fell of a truck", 
	objectName = "civilian_loot.dae",
	script = "civilianlootscript.lua",
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
	mass= 100,
	upRight=true,
	blocking=false,

	FootprintX = 1,
	FootprintZ = 1,
	cantBeTransported = false,

	sightDistance = 80,

	reclaimable=false,
	Builder = false,
	cantBeTransported = false,
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

	 
	 
	Category = [[NOTARGET]],




}

return lowerkeys({ [unitName] = unitDef })