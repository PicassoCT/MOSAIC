local CivilianAgent = Human:New{
	name = "Civilian Asset",
	Description = " recruited Civilian <spies/hidden militia> ",

	corpse = "bodybag",
	maxDamage         	  = 500,
	mass                = 500,
	buildCostEnergy    	  = 150,
	buildCostMetal     	  = 500,
	canMove					  = true,
	MetalStorage 		= 250,

	explodeAs				  = "none",
	Acceleration = 0.4,
	BrakeRate = 0.3,
	TurnRate = 900,
	MaxVelocity = 0.7875,
	showNanoFrame= true,
	
	buildtime			 = 40,
	CanAttack = true,
	CanGuard = true,

	CanMove = true,
	CanPatrol = true,
	CanStop = true,
	script 					= "civilianagentscript.lua",
	objectName        	= "civilian0_arab.dae",
	customParams        = {
		normaltex = "unittextures/arab_civilian_normal.tga",
	},
	buildPic = "civilianagent.png",
	iconType = "civilianagent",
	canCloak =true,
	cloakCost=0.0001,
	cloakCostMoving =0.0001,
	minCloakDistance = 0,
	initCloaked = true,
	decloakOnFire = true,
	cloakTimeout = 5,
	
	customparams = {
		helptext		= "Civilian ",
		baseclass		= "Human", -- TODO: hacks
    },
	
	weapons ={
		[1]={name  = "ak47",
				onlyTargetCategory = [[GROUND ARRESTABLE]],
			},
	
	},
}


return lowerkeys({
	--Temp
	["civilianagent"] = CivilianAgent:New(),
	
})