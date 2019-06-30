local CivilianAgent = Human:New{
	name = "Civilian Asset",
	Description = " Agent ",

	corpse					  = "",
	maxDamage         	  = 500,
	mass                = 500,
	buildCostEnergy    	  = 5,
	buildCostMetal     	  = 5,
	canMove					  = true,
	MetalStorage 		= 250,

	explodeAs				  = "none",
	Acceleration = 0.4,
	BrakeRate = 0.3,
	TurnRate = 900,
	MaxVelocity = 4.5*0.35,
	
	buildtime			 = 40,
	CanAttack = false,
	CanGuard = true,

	CanMove = true,
	CanPatrol = true,
	CanStop = true,
	script 					= "civilianagentscript.lua",
	objectName        	= "civilian.dae",

	canCloak =true,
	cloakCost=0.0001,
	ActivateWhenBuilt=1,
	cloakCostMoving =0.0001,
	minCloakDistance = 0,
	onoffable=true,
	initCloaked = true,
	decloakOnFire = true,
	cloakTimeout = 5,
	
	customparams = {
		helptext		= "Civilian Building",
		baseclass		= "Human", -- TODO: hacks
    },
	
	weapons ={
		[1]={name  = "pistol",
				onlyTargetCategory = [[GROUND ARRESTABLE]],
			},
	
	},
}


return lowerkeys({
	--Temp
	["civilianagent"] = CivilianAgent:New(),
	
})