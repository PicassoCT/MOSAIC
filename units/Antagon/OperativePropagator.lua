local OperativePropagator = Human:New{
	corpse					  = "",
	maxDamage         	  = 500,
	mass                = 500,
	buildCostEnergy    	  = 5,
	buildCostMetal     	  = 5,

	explodeAs				  = "none",
	name = "Propagator",
	description= "Propaganda Operative <recruits Agents/ builds Safehouses / interrogates Intruders>",
	Acceleration = 0.4,
	BrakeRate = 0.3,
	TurnRate = 900,
	MaxVelocity = 2.2,
	MetalStorage = 5000,
	metalMake  = 3,
	buildtime = 60,
	
	--orders
	canMove					  = true,
	CanAttack = true,
	CanGuard = true,

	CanMove = true,
	CanPatrol = true,
	CanStop = true,
	script 				= "operativePropagatorInvestigatorScript.lua",
	objectName        	= "operative_investigator.dae",
	
	Builder = true,
	nanocolor=[[0.20 0.411 0.611]],--
	CanReclaim=false,	
	workerTime = 0.75,
	buildDistance = 120,
	terraformSpeed = 350,
	showNanoFrame= true,
	
	canCloak =true,
	cloakCost=0.0001,
	ActivateWhenBuilt=1,
	cloakCostMoving =0.0001,
	minCloakDistance = 0,
	onoffable=true,
	kamikaze = true,
	kamikazeDistance  = 10,
	kamikazeUseLOS = false,

	buildoptions = 
	{
		"recruitcivilian",
		"antagonsafehouse",
		"air_copter_ssied",
	},

	customparams = {
		helptext		= "Propaganda Operative",
		baseclass		= "Human", -- TODO: hacks
    },
	category = "GROUND ARRESTABLE",
	
	fireState= 1,
	
		weapons={
			[1]={name  = "raidarrest", --prevents other weapon usage
				onlyTargetCategory = [[ARRESTABLE]],
			},				
			[2]={name  = "stunpistol",
				onlyTargetCategory = [[GROUND]],
			}
		},	
		
	category = "ARRESTABLE GROUND",


	
}


return lowerkeys({
	--Temp
	["operativepropagator"] = OperativePropagator:New(),
	
})

