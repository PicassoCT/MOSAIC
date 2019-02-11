local OperativeAsset = Human:New{
	corpse					  = "",
	maxDamage         	  = 1500,
	mass                = 500,
	buildCostEnergy    	  = 5,
	buildCostMetal     	  = 5,

	explodeAs				  = "none",
	description= "Assasination Operative <recruits Agents>",
	Acceleration = 0.8,
	BrakeRate = 0.6,
	TurnRate = 1200,
	MaxVelocity = 9,
	
	--orders
	canMove	= true,
	CanAttack = true,
	CanGuard = true,

	CanMove = true,
	CanPatrol = true,
	CanStop = true,
	script 				= "operativeassetscript.lua",
	objectName        	= "operative_placeholder.s3o",
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
	
	fireState= 1,
	
		weapons={
			[1]={name  = "pistol",
				onlyTargetCategory = [[LAND ]],
			},
			,
			[2]={name  = "machinegun",
				onlyTargetCategory = [[LAND]],
			}
			[3]={name  = "sniperrifle",
				onlyTargetCategory = [[LAND ]],
			}
		},
		
		
	Builder = true,
	nanocolor=[[0 0 0]], --
	CanReclaim=false,	
	workerTime = 0.25,
	buildDistance = 45,
	terraformSpeed = 1,
	buildoptions = {
		"stationaryssied"
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

