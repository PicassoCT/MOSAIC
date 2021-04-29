


local groundturretssied =  Turret:New{
	name = "Stationary SSIED",
	Description = " MOSAIC Standardized Smart Improvised Explosive Device ",
	
	objectName = "ground_turret_sied.dae",
	script = "ground_turret_sied.lua",
	buildPic = "ground_turret_iied.png",
	iconType = "ground_turret_iied",
	--floater = true,
	--cost
	buildCostEnergy = 50,
	 buildCostMetal= 0,
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
	MovementClass = "Default2x2",

	
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
	canCloak =true,
	kamikaze = true,
	kamikazeDistance  = 10,
	kamikazeUseLOS = false,
	
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
							"custom:bigbulletimpact",
							"custom:tess"
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
	Description = "Pillbox Emplacement ",
	
	objectName = "ground_turret_mg.dae",
		customParams        = {
		normaltex = "unittextures/component_atlas_normal.dds",
	},
	
	script = "ground_turretscript.lua",
	buildPic = "ground_turret_mg.png",
	iconType = "ground_turret_mg",
	--floater = true,
	--cost
	buildCostEnergy  = 500,
	buildCostMetal= 500,
	buildTime = 35,
	--Health
	maxDamage = 500,
	idleAutoHeal = 0,
	--Movement
	alwaysUpright=false,
	fireState=1,
	
	FootprintX = 1,
	FootprintZ = 1,
	maxSlope = 50,
	
	MaxWaterDepth = 0,
	MovementClass = "Default2x2",

	nanocolor=[[0.20 0.411 0.611]],
	sightDistance = 300,
	activateWhenBuilt   	= true,
	cantBeTransported = false,
	usepiececollisionvolumes = true,

	canAttackGround = true,
	CanAttack = true,
	CanGuard = true,
	CanMove = true,
	CanPatrol = true,
	Canstop  = true,
	onOffable = false,
	LeaveTracks = false, 
	canCloak =false,	
	canManualFire = true, 
	
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
		[1]={name  = "machingegun",
			onlyTargetCategory = [[GROUND BUILDING]],
			turret = true
			},	
		[2]={name  = "aamachinegun",
			onlyTargetCategory = [[AIR]],
			turret = true
			},					
		},	
}

local ground_turret_antiarmor =  Turret:New{
	name = "Deployed Anti Tank",
	-- This is a anti-tank drone body, deployed after flight
	--capable to one-time launch a projectile 
	-- It has 4 SubScout Air-Drones which seperate at deploy Time and relay target information
	Description = "Deployed Anti Armor Projectile ",
	
	objectName = "ground_turret_sied.dae",
	script = "groundturretantitankscript.lua",
	buildPic = "ground_turret_rocket.png",
	--floater = true,
	--cost
	buildCostEnergy  = 50,
	buildCostMetal= 0,
	buildTime = 35,
	--Health
	maxDamage = 50,
	idleAutoHeal = 0,
	--Movement
	
	 fireState=1,
	
	FootprintX = 1,
	FootprintZ = 1,
	maxSlope = 50,
	levelground = false,
	MaxWaterDepth = 0,
	MovementClass = "Default2x2",

	
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
	
	cloakCost=0.0001,

	minCloakDistance =  5,
	onoffable=true,
	initCloaked = true,
	decloakOnFire = true,
	cloakTimeout = 5,

	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "25 5 25",
	
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
	
	objectName = "ground_turret_grenadeDrone.DAE",
	script = "placeholderscript.lua",
	buildPic = "ground_turret_rocket.png",
	iconType = "ground_turret_rocket",
	--floater = true,
	--cost
	buildCostEnergy  = 50,
	buildCostMetal= 0,
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
	MovementClass = "Default2x2",

	
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
	

	minCloakDistance =  5,
	initCloaked = false,

	
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
		[1]={name  = "s16rocket",
			onlyTargetCategory = [[GROUND]],
			},			
		},	
}
local ground_turret_rocket =  Turret:New{
	name = "Unguided Rocket Turret",
	-- This is a anti-tank drone body, deployed after flight
	--capable to one-time launch a projectile 
	-- It has 4 SubScout Air-Drones which seperate at deploy Time and relay target information
	Description = "Deployed Anti Armor Projectile ",
	
	objectName = "ground_turret_missile.dae",
	script = "ground_turret_rocketscript.lua",
	buildPic = "ground_turret_rocket.png",
	iconType = "ground_turret_rocket",
	--floater = true,
	--cost
	buildCostEnergy  = 50,
	buildCostMetal= 0,
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
	MovementClass = "Default2x2",

	
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
	

	minCloakDistance =  5,
	initCloaked = false,

	
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
		[1]={
			name  = "s16rocket",
			onlyTargetCategory = [[GROUND]],
			},			
		},	
}

local ground_turret_cruisemissilepod =  Walker:New{
	name = "Cruise Missile Pod",
	-- This is a anti-tank drone body, deployed after flight
	--capable to one-time launch a projectile 
	-- It has 4 SubScout Air-Drones which seperate at deploy Time and relay target information
	description = "Fires a cruise missile at target",
	
		objectName = "ground_turret_cruisemissilepod.dae",
	script = "ground_turret_cruisemissilepod_script.lua",
	buildPic = "ground_turret_cm.png",
	iconType = "ground_turret_cm",
	--floater = true,
	--cost
	buildCostEnergy = 50,
	buildCostMetal = 0,
	buildTime = 5,
	--Health
	maxDamage = 50,
	idleAutoHeal = 0,
	--Movement
	maxVelocity		= 0.5 , --14.3, --86kph/20
	--maxReverseVelocity= 2.15,
	acceleration = 0.15,
	brakeRate = 0.1,
	turninplace		= true,
	 fireState=1,
	alwaysUpright = true,
	FootprintX = 1,
	FootprintZ = 1,
	maxSlope = 50,
	
	MaxWaterDepth = 60,

	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "5 25 5",
	
	nanocolor=[[0.20 0.411 0.611]],
	sightDistance = 250,
	activateWhenBuilt   	= true,
	cantBeTransported = false,

	canMove =true,
	CanAttack = true,
	CanGuard = true,

	Canstop  = true,
	onOffable = false,
	LeaveTracks = false, 
	canCloak =true,
	
	Category = [[ARMOR GROUND BUILDING]],

	  customParams = {
	  baseclass = "tank"
	  },

	 sfxtypes = {
		explosiongenerators = {
							"custom:cruisemissiletrail"
							  },
				},
				
	weapons = {
		[1]={name  = "javelinrocket",
			onlyTargetCategory = [[BUILDING GROUND VEHICLE ARMOR]],
			},
			
		},	
}


CruiseMissilePods ={}

ground_turret_cruisemissilepod.weapons  = {
											[1] = { name =  "cm_airstrike"	,																							
													onlyTargetCategory = [[BUILDING GROUND VEHICLE]],
											}
										}
CruiseMissilePods["ground_turret_cm_airdrop"] = ground_turret_cruisemissilepod:New()
CruiseMissilePods["ground_turret_cm_airdrop"].name = "Airstrike"
CruiseMissilePods["ground_turret_cm_airdrop"].description = " fires a cruise missile"

ground_turret_cruisemissilepod.weapons  = {
											[1] = { name =  "cm_walker"	,											
													onlyTargetCategory = [[BUILDING GROUND VEHICLE]],
											}
										}
CruiseMissilePods["ground_turret_cm_walker"] = ground_turret_cruisemissilepod:New()
CruiseMissilePods["ground_turret_cm_walker"].name = "Walker AirDrop Cruise Missile"
CruiseMissilePods["ground_turret_cm_walker"].description = " drops 2 walkers preimpact"

ground_turret_cruisemissilepod.weapons  = {
											[1] = { name =  "cm_antiarmor"	,													
													onlyTargetCategory = [[BUILDING GROUND VEHICLE]],
											}
										}
CruiseMissilePods["ground_turret_cm_antiarmor"] = ground_turret_cruisemissilepod:New()
CruiseMissilePods["ground_turret_cm_antiarmor"].name = "Anti-Armor Cruise Missile"
CruiseMissilePods["ground_turret_cm_antiarmor"].description = " fire anti armour salvoes pre impact"

ground_turret_cruisemissilepod.weapons  = {
											[1] = { name =  "cm_turret_ssied",
												
													onlyTargetCategory = [[BUILDING GROUND VEHICLE]],
											}
										}
CruiseMissilePods["ground_turret_cm_ssied"] = ground_turret_cruisemissilepod:New()
CruiseMissilePods["ground_turret_cm_ssied"].name = "IED-Drone Cruise Missile"
CruiseMissilePods["ground_turret_cm_ssied"].description = " drops IEDs and Turret into the warzone"

return lowerkeys(
{
	["ground_turret_cm_airdrop"] = CruiseMissilePods["ground_turret_cm_airdrop"],
	["ground_turret_cm_walker"] = CruiseMissilePods["ground_turret_cm_walker"],
	["ground_turret_cm_antiarmor"] = CruiseMissilePods["ground_turret_cm_antiarmor"],
	["ground_turret_cm_ssied"] = CruiseMissilePods["ground_turret_cm_ssied"],
	["ground_turret_ssied"] = groundturretssied:New(),
	["ground_turret_mg"] = groundturretmg:New(),
	["ground_turret_antiarmor"] = ground_turret_antiarmor:New()	,
	["ground_turret_rocket"] = ground_turret_rocket:New(),
	["ground_turret_dronegrenade"] = ground_turret_dronegrenades:New() 

})
