local OperativeInvestigator = Human:New{
	corpse					  = "",
	maxDamage         	  = 500,
	mass                = 500,
	buildCostEnergy    	  = 5,
	buildCostMetal     	  = 5,

	explodeAs				  = "none",
	description= "Investigator Operative <recruits Agents>",
	Acceleration = 0.4,
	BrakeRate = 0.3,
	TurnRate = 900,
	MaxVelocity = 4.5,
	
	--orders
	canMove					  = true,
	CanAttack = true,
	CanGuard = true,

	CanMove = true,
	CanPatrol = true,
	CanStop = true,
	script 				= "operativeInvestigatorscript.lua",
	objectName        	= "operative_placeholder.s3o",


	
	canCloak =true,
	cloakCost=0.0001,
	ActivateWhenBuilt=1,
	cloakCostMoving =0.0001,
	minCloakDistance = 0,
	onoffable=true,
	initCloaked = true,
	decloakOnFire = true,
	cloakTimeout = 5,
	
	Builder = true,
	nanocolor=[[0 0 0]], --
	CanReclaim=false,	
	workerTime = 0.75,
	buildDistance = 120,
	terraformSpeed = 350,
		

	buildoptions = 
	{
		"recruitcivilian",
		"antagonsafehouse"
	},

	customparams = {
		helptext		= "Investigative Operative",
		baseclass		= "Human", -- TODO: hacks
    },
	
	fireState= 1,
	
	weapons={
			[1]={name  = "raidarrest", --prevents other weapon usage
				onlyTargetCategory = [[ARRESTABLE]],
			},				
			[2]={name  = "pistol",
				onlyTargetCategory = [[LAND]],
			},
			[3]={name  = "machinegun",
				onlyTargetCategory = [[LAND]],
			}
		},	
	
	category = [[LAND ARRESTABLE]],
	
}


return lowerkeys({
	--Temp
	["operativeinvestigator"] = OperativeInvestigator:New(),
	
})

