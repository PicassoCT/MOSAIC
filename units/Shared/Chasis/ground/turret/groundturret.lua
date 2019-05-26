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

	Category = [[GROUND]],

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
					onlyTargetCategory = [[BUILDING GROUND]],
					},
					
		},	

			


}

local groundturretmg =  Turret:New{
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
	
	
	Category = [[GROUND]],

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
					onlyTargetCategory = [[BUILDING GROUND]],
					},
					
		},	
}

local groundturretantitank =  Turret:New{
	name = "Deployed Anti Tank",
	-- This is a anti-tank drone body, deployed after flight
	--capable to one-time launch a projectile 
	-- It has 4 SubScout Air-Drones which seperate at deploy Time and relay target information
	Description = "Deployed Anti Armor Projectile ",
	
	objectName = "ground_turret_mg.dae",
	script = "groundturretantitankscript.lua",
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
	CanGuard = true,
	CanMove = false,
	CanPatrol = false,
	Canstop  = true,
	onOffable = false,
	LeaveTracks = false, 
	canCloak =true,
	
	
	Category = [[ARMOR GROUND BUILDING]],

	  customParams = {
	  baseclass = "turret"
	  },
	 sfxtypes = {
		explosiongenerators = {
							"custom:bigbulletimpact"
							  },
				},
				
	weapons = {
		[1]={name  = "antitank",
			onlyTargetCategory = [[BUILDING GROUND]],
			},
			
		},	

			


}


return lowerkeys({

	["ground_turret_ssied"] = groundturretssied:New(),
	["ground_turret_mg"] = groundturretmg:New(),
	
})
