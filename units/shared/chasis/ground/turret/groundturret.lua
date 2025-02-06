local groundturretssied =  Turret:New{
	name = "Stationary Improvised Explosive Device",
	Description = " MOSAIC Standardized  IED ",
	
	objectName = "ground_turret_sied.dae",
	script = "ground_turret_sied.lua",
	buildPic = "ground_turret_iied.png",
	iconType = "ground_turret_iied",
	--floater = true,
	--cost
	buildCostEnergy = 250,
	 buildCostMetal= 500,
	buildTime = 35,
	--Health
	maxDamage = 50,
	idleAutoHeal = 0,
	--Movement
	
	 fireState=1,
	
	FootprintX = 1,
	FootprintZ = 1,
	maxSlope = 50,
	
	MaxWaterDepth = 0,
	MovementClass = "VEHICLE",
	mass = 1000,

	sightDistance = 80,
	nanocolor=[[0.20 0.411 0.611]],
	sightDistance = 250,
	activateWhenBuilt   	= true,
	cantBeTransported = false,
	canSelfD = true,
	canManualFire  = true,
	canSelfDestruct = true,

	--canHover=true,
	CanAttack = true,
	CanGuard = true,
	CanMove = true,
	CanPatrol = true,
	Canstop  = true,
	onOffable = false,
	LeaveTracks = false, 
	canCloak =true,
	kamikaze = true,
	kamikazeDistance  = 70,
	kamikazeUseLOS = true,
	
	cloakCost=0.0001,

	minCloakDistance =  5,
	onoffable=true,
	initCloaked = true,
	decloakOnFire = true,
	cloakTimeout = 5,

	Category = [[GROUND]],

	  customParams = {
	  baseclass = "turret",
	  normaltex = "unittextures/component_atlas_normal.dds",
	  },

	 selfDestructAs  = "ssied",
	 sfxtypes = {
		explosiongenerators = {
							"custom:bigbulletimpact",
							"custom:tess"
							  },
				},
				
}

local groundturretmg =  Turret:New{
	name = "Stationary Machinegun",
	Description = "Pillbox Emplacement ",
	
	objectName = "ground_turret_mg.dae",
	mass = 2500,
	
	script = "ground_turretscript.lua",
	buildPic = "ground_turret_mg.png",
	iconType = "ground_turret_mg",

	--cost
	buildCostEnergy  = 250,
	buildCostMetal= 500,
	buildTime = 35,
	--Health
	maxDamage = 2500,
	idleAutoHeal = 0,
	--Movement
	--upright =false,
	fireState=1,
	pushResistant = true,
	FootprintX = 1,
	FootprintZ = 1,
	maxSlope = 50,
	
	MaxWaterDepth = 0,
	MovementClass = "VEHICLE",

	nanocolor=[[0.20 0.411 0.611]],
	sightDistance = 300,

	cantBeTransported = false,

	usepiececollisionvolumes = false,
	--collisionVolumeType = "box",
	--collisionvolumescales = "5 15 5",

	CanAttack = true,
	canFight  = true,
	CanGuard = true,
	CanMove = true,
	CanPatrol = true,
	Canstop  = true,
	canCloak = false,
	
	Category = [[GROUND]],

	  customParams = {
	 	 baseclass = "turret",
	 	 normaltex = "unittextures/component_atlas_normal.dds",
	  },

	 sfxtypes = {
		explosiongenerators = {
								"custom:bigbulletimpact",
								"custom:gunmuzzle"
							  },
				},
				
		weapons = {
		[1]={name  = "heavymachinegun",
			onlyTargetCategory = [[GROUND BUILDING]]
			},	
		[2]={name  = "aamachinegun",
			onlyTargetCategory = [[AIR]]
			},				
		},	
}

local groundturretmortar =  Turret:New{
	name = " Mortar",
	Description = " indirect attack unit<turret> ",
	
	objectName = "ground_turret_mortar.dae",
	mass = 2500,
	
	script = "ground_turret_mortar_script.lua",
	buildPic = "ground_turret_mg.png",
	iconType = "ground_turret_mg",

	--cost
	buildCostEnergy  = 250,
	buildCostMetal= 500,
	buildTime = 35,
	--Health
	maxDamage = 2500,
	idleAutoHeal = 0,
	--Movement
	alwaysUpright=false,
	fireState=1,
	pushResistant = true,
	FootprintX = 1,
	FootprintZ = 1,
	maxSlope = 50,
	
	MaxWaterDepth = 0,
	MovementClass = "VEHICLE",

	nanocolor=[[0.20 0.411 0.611]],
	sightDistance = 300,

	cantBeTransported = false,

	usepiececollisionvolumes = false,
	--collisionVolumeType = "box",
	--collisionvolumescales = "5 15 5",

	CanAttack = true,
	canFight  = true,
	CanGuard = true,
	CanMove = true,
	CanPatrol = true,
	Canstop  = true,
	canCloak = false,
	
	Category = [[GROUND]],

	  customParams = {
	 	 baseclass = "turret",
	 	 normaltex = "unittextures/component_atlas_normal.dds",
	  },

	 sfxtypes = {
		explosiongenerators = {
								"custom:bigbulletimpact",
								"custom:gunmuzzle"
							  },
				},
				
		weapons = {
		[1]={name  = "mortar",
			onlyTargetCategory = [[GROUND BUILDING]]
			},	
		},	
}

local ground_turret_sniper =  Turret:New{
	name = "Stationary Snipersentry",
	Description = "Pillbox Emplacement ",
	
	objectName = "ground_turret_sniper.dae",
	mass = 2500,
	
	script = "groundturretsniperscript.lua",
	buildPic = "ground_turret_mg.png",
	iconType = "ground_turret_mg",
	pushResistant = true,
	--cost
	buildCostEnergy  = 900,
	buildCostMetal= 1500,
	buildTime = 90,
	--Health
	maxDamage = 1200,
	idleAutoHeal = 0,
	--Movement
	alwaysUpright=false,
	fireState=1,
	
	FootprintX = 1,
	FootprintZ = 1,
	maxSlope = 50,
	
	MaxWaterDepth = 0,
	MovementClass = "VEHICLE",

	nanocolor=[[0.20 0.411 0.611]],
	sightDistance = 300,

	cantBeTransported = false,

	usepiececollisionvolumes = false,
	--collisionVolumeType = "box",
	--collisionvolumescales = "5 15 5",

	CanAttack = true,
	canFight  = true,
	CanGuard = true,
	CanMove = true,
	CanPatrol = true,
	Canstop  = true,
	canCloak = false,
	
	Category = [[GROUND]],

	  customParams = {
	 	 baseclass = "turret",
	 	 normaltex = "unittextures/component_atlas_normal.dds",
	  },

	 sfxtypes = {
		explosiongenerators = {
								"custom:bigbulletimpact",
								"custom:gunmuzzle"
							  },
				},
				
	weapons = {
		[1]={name  = "slowsniperrifle",
				onlyTargetCategory = [[GROUND BUILDING]],
				turret= false
			},		
		},	
}

local ground_turret_antiarmor =  Turret:New{
	name = "Deployed Anti Tank",
	-- This is a anti-tank drone body, deployed after flight
	--capable to one-time launch a projectile 
	-- It has 4 SubScout Air-Drones which seperate at deploy Time and relay target information
	Description = "Deployed Anti Armor Projectile ",
	
	objectName = "ground_turret_antiarmor.DAE",
	script = "groundturretantitankscript.lua",
	buildPic = "ground_turret_rocket.png",
	--floater = true,
	--cost
	buildCostEnergy  = 500,
	buildCostMetal= 1000,
	buildTime = 35,
	--Health
	maxDamage = 50,
	idleAutoHeal = 0,
	--Movement
	mass = 750,
	fireState=1,
	pushResistant = true,
	FootprintX = 1,
	FootprintZ = 1,
	maxSlope = 50,
	levelground = false,
	MaxWaterDepth = 0,
	MovementClass = "VEHICLE",

	
	nanocolor=[[0.20 0.411 0.611]],
	sightDistance = 250,
	activateWhenBuilt   	= true,
	cantBeTransported = false,
	canSelfD = true,
	canManualFire  = true,

	--canHover=true,
	CanAttack = true,
	CanGuard = true,
	CanMove = true,
	CanPatrol = true,
	Canstop  = true,
	onOffable = false,
	LeaveTracks = false, 
	canCloak =false,
	onoffable=true,

	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "25 5 25",
	
	Category = [[ARMOR GROUND BUILDING]],

	  customParams = {
	  	baseclass = "turret",
	  	normaltex = "unittextures/component_atlas_normal.dds",
	  },

	 sfxtypes = {
		explosiongenerators = {
							"custom:bigbulletimpact"
							  },
				},
				
	weapons = {
		[1]={name  = "javelinrocket",
			onlyTargetCategory = [[BUILDING GROUND VEHICLE]],
			},
			
		},	
}

local ground_turret_dronegrenades =  Turret:New{
	name = "Self guiding drones Turret",
	-- This is a anti-tank drone body, deployed after flight
	--capable to one-time launch a projectile 
	-- It has 4 SubScout Air-Drones which seperate at deploy Time and relay target information
	Description = "Deploy Anit Person Flying Mini-Drones",
	mass = 750,
	objectName = "ground_turret_grenadeDrone.DAE",
	script = "ground_turret_drone_script.lua",
	buildPic = "ground_turret_rocket.png",
	iconType = "ground_turret_rocket",
	--floater = true,
	--cost
	buildCostEnergy  = 250,
	buildCostMetal= 750,
	buildTime = 35,
	--Health
	maxDamage = 50,
	idleAutoHeal = 0,
	--Movement
	
	 fireState=1,
	
	FootprintX = 1,
	FootprintZ = 1,
	maxSlope = 50,
	
	MaxWaterDepth = 0,
	MovementClass = "VEHICLE",

	
	nanocolor=[[0.20 0.411 0.611]],
	sightDistance = 350,
	activateWhenBuilt   	= true,
	cantBeTransported = false,
	canSelfD = true,
	canManualFire  = true,

	--canHover=true,
	CanAttack = true,
	CanGuard = true,
	CanMove = true,
	CanPatrol = true,
	Canstop  = true,
	onOffable = false,
	LeaveTracks = false, 
	canCloak =false,
	

	minCloakDistance =  5,
	initCloaked = false,

	
	Category = [[ARMOR GROUND BUILDING]],

	  customParams = {
	  	baseclass = "turret",
	  	normaltex = "unittextures/component_atlas_normal.dds",
	  },
	 sfxtypes = {
		explosiongenerators = {
							"custom:bigbulletimpact"
							  },
				},
				
	weapons = {
		[1]={name  = "smartminedrone",
			onlyTargetCategory = [[BUILDING GROUND VEHICLE]],
			},			
		},	
}
local ground_turret_rocket =  Turret:New{
	name = "Anti-Air Rocket Turret",
	-- This is a anti-tank drone body, deployed after flight
	--capable to one-time launch a projectile 
	-- It has 4 SubScout Air-Drones which seperate at deploy Time and relay target information
	Description = "Deployed Anti Armor Projectile ",
	mass = 2500,
	objectName = "ground_turret_missile.dae",
	script = "ground_turret_rocketscript.lua",
	buildPic = "ground_turret_rocket.png",
	iconType = "ground_turret_rocket",
	--floater = true,
	--cost
	buildCostEnergy  = 250,
	buildCostMetal= 500,
	buildTime = 35,
	--Health
	maxDamage = 50,
	idleAutoHeal = 0,
	--Movement
	
	fireState=3,
	
	FootprintX = 1,
	FootprintZ = 1,
	maxSlope = 50,

	MaxWaterDepth = 0,
	MovementClass = "VEHICLE",
	pushResistant = true,
	
	nanocolor=[[0.20 0.411 0.611]],
	sightDistance = 650,
	activateWhenBuilt   	= true,
	cantBeTransported = false,
	canSelfD = true,
	canManualFire  = true,

	--canHover=true,
	CanAttack = true,
	CanGuard = true,
	CanMove = true,
	CanPatrol = true,
	Canstop  = true,
	onOffable = false,
	LeaveTracks = false, 
	canCloak =false,
	

	minCloakDistance =  5,
	initCloaked = false,

	
	Category = [[ARMOR GROUND BUILDING]],

	  customParams = {
	  	baseclass = "turret",
	  	normaltex = "unittextures/component_atlas_normal.dds",
	  },
	 sfxtypes = {
		explosiongenerators = {
							"custom:bigbulletimpact"
							  },
				},
				
	weapons = {
		[1]={
			name  = "s16rocket",
			onlyTargetCategory = [[AIR]],
			},			
		},	
}

return lowerkeys(
{
	["ground_turret_ssied"] = groundturretssied:New(),
	["ground_turret_mg"] = groundturretmg:New(),
	["ground_turret_mortar"] = groundturretmortar:New(),
	["ground_turret_antiarmor"] = ground_turret_antiarmor:New()	,
	["ground_turret_rocket"] = ground_turret_rocket:New(),
	["ground_turret_dronegrenade"] = ground_turret_dronegrenades:New(),
	["ground_turret_sniper"] = ground_turret_sniper:New() 

})
