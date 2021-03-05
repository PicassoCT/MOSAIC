local unitName = "tree_arab1"

	local unitDef = {
	name = "Pinetree",
	Description = "",
	objectName = "tree_arab1.s3o",
	script = "tree_arab1_script.lua",
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


	 
	  customParams = {},
	 sfxtypes = {
		explosiongenerators = {	    
							  },
				},
	Category = [[NOTARGET]],

}

return lowerkeys({ [unitName] = unitDef })