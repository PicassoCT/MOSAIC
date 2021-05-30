local OperativePropagator = Human:New{
	maxDamage         	  = 500,
	mass                = 500,
	buildCostEnergy    	  = 500,
	buildCostMetal     	  = 3000,
	buildPic = "operativepropagator.png",
	iconType ="operativepropagator",
	explodeAs				  = "none",
	name = "Propagator",
	corpse = "bodybag",
	description= "Propaganda Operative <recruits Agents/ builds Safehouses / interrogates Intruders>",
	Acceleration = 0.4,
	BrakeRate = 0.3,
	TurnRate = 900,
	MaxVelocity = 2.2,
	MetalStorage = 5000,
	metalMake  = 3,
	energyMake = 1,
	buildtime = 60,
	
	--orders
	canMove					  = true,
	CanAttack = true,
	CanGuard = true,

	CanMove = true,
	CanPatrol = true,
	CanStop = true,
	script 				= "operativePropagatorInvestigatorScript.lua",
	objectName        	= "operative_propagator.dae",
	customParams        = {
		normaltex = "unittextures/operative_propagator_normal.dds",
	},
	
	Builder = true,
	nanocolor=[[0.20 0.411 0.611]],--
	CanReclaim=false,	
	workerTime = 1.0,
	buildDistance = 120,
	terraformSpeed = 350,
	showNanoFrame= true,
	onoffable = false,
		
	--cloaking behaviour
	canCloak =true,
	cloakCost=0.0001,
	cloakCostMoving =0.0001,
	cloakTimeout =  360,
	cloakCostMoving = 0,
	minCloakDistance = 0,
	initCloaked = false,
	stealth= true,

	
	buildoptions = 
	{
		"recruitcivilian",
		"air_parachut",
		"antagonsafehouse",
		"air_copter_ssied",	
		"bribeicon",
		"barricade"
	},

	customparams = {
		helptext		= "Propaganda Operative",
		baseclass		= "Human", -- TODO: hacks
    },
	category = "GROUND ARRESTABLE",
	
	fireState= 1,
	
		weapons={
			[1]={name  = "raidarrest", --prevents other weapon usage
				onlyTargetCategory = [[RAIDABLE]],
			},				
			[2]={name  = "stunpistol",
				onlyTargetCategory = [[GROUND ARRESTABLE]],
			}
		},	
		
	category = [[GROUND ARRESTABLE]],


	
}


return lowerkeys({
	--Temp
	["operativepropagator"] = OperativePropagator:New(),
	
})

