local OperativeAsset = Human:New{

	name = "Operative Assset",
	description= "Assasination Operative <stealth Assasin>",
	corpse = "bodybag",
	maxDamage         	  	 = 1500,
	mass               		 = 100,
	buildCostEnergy    	 	 = 2000,
	buildCostMetal     	 	 = 2000,
	MetalStorage 			 = 1500,

	buildDistance 			 = 200,
	explodeAs				 = "none",
	Acceleration 			 = 0.8,
	BrakeRate = 0.6,
	TurnRate = 1200,
	MaxVelocity = 4.4,
	buildtime	= 1 * 60,
	workerTime = 0.5,
	--orders
	canMove	= true,
	CanAttack = true,
	CanGuard = true,
	showNanoFrame= true,
	buildPic = "operativeasset.png",
	iconType = "operativeasset",
	CanMove = true,
	CanPatrol = true,
	CanStop = true,
	script 				= "operativeassetscript.lua",
	objectName        	= "operative_asset.dae",

	onoffable = false,
	  	
	sightDistance = 400,
		--cloaking behaviour
	canCloak =true,
	cloakCost=0.0001,
	cloakCostMoving =0.0001,
	--decloakOnFire = true,
	minCloakDistance = 0,
	cloakTimeout =  360,
	initCloaked = true,
	stealth = true,
	--idleAutoHeal = 1500/120,
	--idleTime = 10*30,
	canSelfDestruct = true,
	selfDestructCountdown = 0.5*30,
	category = "GROUND ARRESTABLE CLOSECOMBATABLE",
	fireState= 1,
	moveState = 0,
	transportByEnemy = true,
	
		weapons={
			[1]={name  = "pistol",
				onlyTargetCategory = [[GROUND AIR]],
				noChaseCategory = [[GROUND AIR]],
				badTargetCategory = [[RAIDABLE]]
			},
			[2]={name  = "submachingegun",
				onlyTargetCategory = [[GROUND AIR]],
				badTargetCategory = [[RAIDABLE]]
			},
			[3]={name  = "sniperrifle",
				onlyTargetCategory = [[GROUND]],
				badTargetCategory = [[RAIDABLE]]
			},
			[4]={name  = "closecombat",
				onlyTargetCategory = [[CLOSECOMBATABLE]],
				noChaseCategory = [[CLOSECOMBATABLE]],
			}
		},
		
		
	Builder = true,
	nanocolor=[[0.20 0.411 0.611]],--
	CanReclaim=false,	

	buildDistance = 120,
	terraformSpeed = 1,
	buildoptions = {
		"ground_turret_ssied",
		"ground_stickybomb",
		"bribeicon",
		"stealvehicleicon",
		"air_parachut",
		"rooftopicon",
	},
	
	customParams = {
		helptext		= "Stealth Assasin",
		baseclass		= "Human", -- TODO: hacks,
		normaltex = "unittextures/operative_asset_normalpha.dds",
    },
}


return lowerkeys({
	--Temp
	["operativeasset"] = OperativeAsset:New(),
	
})

