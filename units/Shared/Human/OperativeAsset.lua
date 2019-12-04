local OperativeAsset = Human:New{

	name = "Operative Assset",
	description= "Assasination Operative <stealth Assasin>",
	
	corpse					  = "",
	maxDamage         	  = 1500,
	mass                = 500,
	buildCostEnergy    	  = 5,
	buildCostMetal     	  = 5,
	MetalStorage = 1500,

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

	CanMove = true,
	CanPatrol = true,
	CanStop = true,
	script 				= "operativeassetscript.lua",
	objectName        	= "operative_asset.dae",
	firestate = 1,
	
	canCloak =true,
	cloakCost=0.0001,
	ActivateWhenBuilt=1,
	cloakCostMoving =0.0001,
	minCloakDistance = 0,
	onoffable=true,
	initCloaked = true,
	decloakOnFire = true,
	cloakTimeout = 5,
	category = "GROUND ARRESTABLE",
	fireState= 1,
	
		weapons={
			[1]={name  = "pistol",
				onlyTargetCategory = [[GROUND ]],
			},
			[2]={name  = "machinegun",
				onlyTargetCategory = [[GROUND]],
			},
			[3]={name  = "sniperrifle",
				onlyTargetCategory = [[GROUND ]],
			}
		},
		
		
	Builder = true,
	nanocolor=[[0 0 0]], --
	CanReclaim=false,	
	workerTime = 0.25,
	buildDistance = 45,
	terraformSpeed = 1,
	buildoptions = {
		"ground_turret_ssied"
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

