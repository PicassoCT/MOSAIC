local unitName = "innerCityDeco_inter3"

	local unitDef = {
	name = "",
	Description = "Camerapole",
	objectName = "innerCityDeco_inter3.dae",
	script = "innerCityDeco_inter3script.lua",
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
	 
	  customParams = {
			normaltex = "unittextures/house_europe_normal.dds",

	  },
	 sfxtypes = {
		explosiongenerators = {	    
							  },
		
				},

	 
	 
	Category = [[GROUND BUILDING]],




}

return lowerkeys({ [unitName] = unitDef })