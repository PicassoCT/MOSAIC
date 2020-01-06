local OperativeInvestigator = Human:New{
	corpse					  = "",
	maxDamage         	  = 500,
	mass                = 500,
	buildCostEnergy    	  = 5,
	buildCostMetal     	  = 5,
	MetalStorage = 5000,
	metalMake  = 3,
	buildtime = 60,
	explodeAs				  = "none",
	name = 		"Investigator",
	description= " pre-incident investigation <recruits Agents/ creates safehouses/ interrogates terrorists>",
	Acceleration = 0.4,
	BrakeRate = 0.3,
	TurnRate = 900,
	MaxVelocity = 2.2,
	
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
		"protagonsafehouse",
		"air_copter_ssied"
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
			[2]={name  = "stunpistol",
				onlyTargetCategory = [[GROUND]],
			}
		},	
	
	category = [[GROUND ARRESTABLE]],
	
}


return lowerkeys({
	--Temp
	["operativeinvestigator"] = OperativeInvestigator:New(),
	
})

