local unitName = "innerCityDeco_western"

	local unitDef = {
	name = "",
	Description = "Western Statue",
	objectName = "innerCityDecoStatue_western.dae",
	script = "statueScript.lua",
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
	blocking=true,
	pushResistant=true,
	FootprintX = 2,
	FootprintZ = 2,


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

	usepiececollisionvolumes = false,
	collisionVolumeType = "cylinder",
	collisionvolumescales = "10 25 10",
	 
	  customParams = {},
	 sfxtypes = {
		explosiongenerators = {	    
							  },
		
				},

	 
	 
	Category = [[GROUND BUILDING]],




}

return lowerkeys({ [unitName] = unitDef })