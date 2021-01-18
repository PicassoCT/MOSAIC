local OperativeAsset = Human:New{

	name = "Operative Assset",
	description= "Assasination Operative <stealth Assasin>",
	corpse = "bodybag",
	maxDamage         	  	 = 1500,
	mass               		 = 500,
	buildCostEnergy    	 	 = 2000,
	buildCostMetal     	 	 = 2000,
	MetalStorage 			 = 1500,

	explodeAs				  = "none",

	Acceleration = 0.8,
	BrakeRate = 0.6,
	TurnRate = 1200,
	MaxVelocity = 4.4,
	buildtime			 = 2 * 60,
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
	customParams        = {
		normaltex = "unittextures/operative_asset_normalpha.tga",
	},
	onoffable = false,
	  
		--cloaking behaviour
	canCloak =true,
	cloakCost=0.0001,
	cloakCostMoving =0.0001,
	--decloakOnFire = true,
	minCloakDistance = 0,
	cloakTimeout =  360,
	initCloaked = true,
	stealth = true,

	category = "GROUND ARRESTABLE",
	fireState= 1,
	
		weapons={
			[1]={name  = "pistol",
				onlyTargetCategory = [[GROUND AIR]],
			},
			[2]={name  = "submachingegun",
				onlyTargetCategory = [[GROUND AIR]],
			},
			[3]={name  = "sniperrifle",
				onlyTargetCategory = [[GROUND]],
			}
		},
		
		
	Builder = true,
	nanocolor=[[0.20 0.411 0.611]],--
	CanReclaim=false,	
	workerTime = 0.25,
	buildDistance = 45,
	terraformSpeed = 1,
	buildoptions = {
		"ground_turret_ssied",
		"air_parachut"
	},
	
	customparams = {
		helptext		= "Stealth Assasin",
		baseclass		= "Human", -- TODO: hacks
    },
}


return lowerkeys({
	--Temp
	["operativeasset"] = OperativeAsset:New(),
	
})

