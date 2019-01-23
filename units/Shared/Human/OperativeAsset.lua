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

	-- Hack Infrastructure
	--CommandUnits (+10 Units)
	-- WithinCellsInterlinked (Recruit)
	
	canCloak =true,
	cloakCost=0.0001,
	cloakCostMoving =0.0001,
	minCloakDistance = 15,
	onoffable=true,
	
		weapons={
			[1]={name  = "pistol",
				onlyTargetCategory = [[LAND ]],
			},
			[2]={name  = "gun",
				onlyTargetCategory = [[LAND ]],
			},
			[3]={name  = "c4",
				onlyTargetCategory = [[BUILDING ]],
			},
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

