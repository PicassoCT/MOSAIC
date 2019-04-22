local groundturretssied =  Turret:New{
	name = "Stationary SSIED",
	Description = " MOSAIC Standardized Smart Improvised Explosive Device ",
	
	objectName = "groundturretssied.s3o",
	script = "turretscript.lua",
	buildPic = "placeholder.png",
	--floater = true,
	--cost
	buildCostMetal = 50,
	buildCostEnergy = 0,
	buildTime = 5,
	--Health
	maxDamage = 50,
	idleAutoHeal = 0,
	--Movement
	
	 fireState=1,
	
	FootprintX = 1,
	FootprintZ = 1,
	maxSlope = 50,
	
	MaxWaterDepth = 0,
	MovementClass = "Default2x2",

	
	nanocolor=[[0 0.9 0.9]],
	sightDistance = 250,
	activateWhenBuilt   	= true,
	cantBeTransported = false,

	--canHover=true,
	CanAttack = true,
	CanGuard = false,
	CanMove = false,
	CanPatrol = false,
	Canstop  = false,
	onOffable = false,
	LeaveTracks = false, 
	canCloak =true,
	
	cloakCost=0.0001,

	minCloakDistance =  5,
	onoffable=true,
	initCloaked = true,
	decloakOnFire = true,
	cloakTimeout = 5,

	Category = [[LAND]],

	  customParams = {
	  baseclass = "turret"
	  },
	 sfxtypes = {
		explosiongenerators = {
							"custom:bigbulletimpact"
							  },
				},
				
				weapons = {
				[1]={name  = "ssied",
					onlyTargetCategory = [[BUILDING LAND]],
					},
					
		},	

			


}local groundturretmg =  Turret:New{
	name = "Stationary Machinegun",
	Description = " MOSAIC Standardized Machine Gun Emplacement ",
	
	objectName = "ground_turret_mg.dae",
	script = "turretscript.lua",
	buildPic = "placeholder.png",
	--floater = true,
	--cost
	buildCostMetal = 50,
	buildCostEnergy = 0,
	buildTime = 5,
	--Health
	maxDamage = 50,
	idleAutoHeal = 0,
	--Movement
	
	 fireState=1,
	
	FootprintX = 1,
	FootprintZ = 1,
	maxSlope = 50,
	
	MaxWaterDepth = 0,
	MovementClass = "Default2x2",

	
	nanocolor=[[0 0.9 0.9]],
	sightDistance = 250,
	activateWhenBuilt   	= true,
	cantBeTransported = false,

	--canHover=true,
	CanAttack = true,
	CanGuard = false,
	CanMove = false,
	CanPatrol = false,
	Canstop  = false,
	onOffable = false,
	LeaveTracks = false, 
	canCloak =true,
	
	
	Category = [[LAND]],

	  customParams = {
	  baseclass = "turret"
	  },
	 sfxtypes = {
		explosiongenerators = {
							"custom:bigbulletimpact"
							  },
				},
				
				weapons = {
				[1]={name  = "machinegun",
					onlyTargetCategory = [[BUILDING LAND]],
					},
					
		},	

			


}


return lowerkeys({

	["ground_turret_ssied"] = groundturretssied:New(),
	["ground_turret_mg"] = groundturretmg:New(),
	
})
