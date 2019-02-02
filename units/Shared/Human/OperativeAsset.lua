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
	cloakCostMoving =0.0001,
	minCloakDistance = 0,
	onoffable=true,
		
	fireState= 1,
	
		weapons={
			[1]={name  = "pistol",
				onlyTargetCategory = [[LAND ]],
			},
			[2]={name  = "gun",
				onlyTargetCategory = [[LAND AIR ]],
			},
			[3]={name  = "sniperrifle",
				onlyTargetCategory = [[LAND ]],
			},
			[4]={name  = "c4",
				onlyTargetCategory = [[LAND ]],
			}
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

