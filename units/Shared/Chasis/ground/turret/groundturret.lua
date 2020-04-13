local groundturretssied =  Turret:New{
	name = "Stationary SSIED",
	Description = " MOSAIC Standardized Smart Improvised Explosive Device ",
	
	objectName = "ground_turret_sied.dae",
	script = "ground_turret_sied.lua",
	buildPic = "placeholder.png",
	--floater = true,
	--cost
	buildCostMetal = 50,
	buildCostEnergy = 0,
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
		customParams        = {
		normaltex = "unittextures/component_atlas_normal.dds",
	},
	script = "ground_turretscript.lua",
	buildPic = "placeholder.png",
	--floater = true,
	--cost
	buildCostMetal = 50,
	buildCostEnergy = 0,
	buildTime = 35,
	--Health
	maxDamage = 500,
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

	--canHover=true,
	CanAttack = true,
	CanGuard = true,
	CanMove = true,
	CanPatrol = true,
	Canstop  = true,
	onOffable = false,
	LeaveTracks = false, 
	canCloak =false,	
	
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
			onlyTargetCategory = [[BUILDING GROUND AIR]],
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
	buildPic = "placeholder.png",
	--floater = true,
	--cost
	buildCostMetal = 50,
	buildCostEnergy = 0,
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
	
	cloakCost=0.0001,

	minCloakDistance =  5,
	onoffable=true,
	initCloaked = true,
	decloakOnFire = true,
	cloakTimeout = 5,

	
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

local ground_turret_cruisemissilepod =  Turret:New{
	name = "Cruise Missile Pod",
	-- This is a anti-tank drone body, deployed after flight
	--capable to one-time launch a projectile 
	-- It has 4 SubScout Air-Drones which seperate at deploy Time and relay target information
	Description = "Deploys a Unit via rocketlaunch ",
	
	objectName = "ground_turret_cruisemissilepod.dae",
	script = "ground_turret_cruisemissilepod_script.lua",
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
	
	MaxWaterDepth = 60,

	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "5 25 5",
	
	nanocolor=[[0.20 0.411 0.611]],
	sightDistance = 250,
	activateWhenBuilt   	= true,
	cantBeTransported = false,

	--canHover=true,
	CanAttack = true,
	CanGuard = true,

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
CruiseMissilePods["ground_turret_cm_airdrop"].Description = " deploys air ied drones pre impact"

ground_turret_cruisemissilepod.weapons  = {
											[1] = { name =  "cm_walker"	,
											
													onlyTargetCategory = [[BUILDING GROUND VEHICLE]],
											}
										}
CruiseMissilePods["ground_turret_cm_walker"] = ground_turret_cruisemissilepod:New()
CruiseMissilePods["ground_turret_cm_walker"].Description = " drops 2 walkers preimpact"

ground_turret_cruisemissilepod.weapons  = {
											[1] = { name =  "cm_antiarmor"	,
													
													onlyTargetCategory = [[BUILDING GROUND VEHICLE]],
											}
										}
CruiseMissilePods["ground_turret_cm_antiarmor"] = ground_turret_cruisemissilepod:New()
CruiseMissilePods["ground_turret_cm_antiarmor"].Description = " launches anti armour pods pre impact"

ground_turret_cruisemissilepod.weapons  = {
											[1] = { name =  "cm_turret_ssied",
												
													onlyTargetCategory = [[BUILDING GROUND VEHICLE]],
											}
										}
CruiseMissilePods["ground_turret_cm_ssied"] = ground_turret_cruisemissilepod:New()
CruiseMissilePods["ground_turret_cm_ssied"].Description = " launches a deadly cruise missile"

return lowerkeys(
{
	["ground_turret_cm_airdrop"] = CruiseMissilePods["ground_turret_cm_airdrop"],
	["ground_turret_cm_walker"] = CruiseMissilePods["ground_turret_cm_walker"],
	["ground_turret_cm_antiarmor"] = CruiseMissilePods["ground_turret_cm_antiarmor"],
	["ground_turret_cm_ssied"] = CruiseMissilePods["ground_turret_cm_ssied"],
	["ground_turret_ssied"] = groundturretssied:New(),
	["ground_turret_mg"] = groundturretmg:New(),
	["ground_turret_antiarmor"] = ground_turret_antiarmor:New()	
})
