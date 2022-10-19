local unitName = "teargascloud"

	local unitDef = {
	name = "",
	Description = "Teargascloud",
	objectName = "tearGasCannister.s3o",
	script = "teargasCloudscript.lua",
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
	upRight=false,
	blocking=false,
	pushResistant=true,
	Acceleration = 0.0000001,
	BrakeRate = 0.0001,
	FootprintX = 1,
	FootprintZ = 1,


	sightDistance = 0,

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
							"custom:teargasexplode", --1024
							  },		
				},	 
	 
	Category = [[NOTARGET ABSTRACT]],
}

return lowerkeys({ [unitName] = unitDef })