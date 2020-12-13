local OperativeInvestigator = Human:New{
	corpse = "bodybag",
	maxDamage         	  = 500,
	mass                = 500,
	buildCostEnergy    	  = 500,
	buildCostMetal     	  = 3000,
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
	script 				= "operativePropagatorInvestigatorScript.lua",
	objectName        	= "operative_investigator.dae",
		customParams        = {
		normaltex = "unittextures/operative_investigator_normal.dds",
	},
		buildPic = "operativeinvestigator.png",
	iconType ="operativeinvestigator",
	showNanoFrame= true,
	ActivateWhenBuilt=1,
	
--cloaking behaviour
	canCloak =true,
	decloakSpherical = true,
	decloakOnFire = true,
	cloakCostMoving = 0,
	minCloakDistance = -1.0,
	
	onoffable= false,
	Builder = true,
	nanocolor=[[0.20 0.411 0.611]],--
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
	["operativeinvestigator"] = OperativeInvestigator:New(),
	
})

