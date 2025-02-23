local OperativeInvestigator = Human:New{
	corpse = "bodybag",
	maxDamage         	  = 750,
	mass                = 100,
	buildCostEnergy    	  = 500,
	buildCostMetal     	  = 2000,
	MetalStorage = 5000,
	metalMake  = 3,
	energyMake = 1,
	buildtime = 60,
	explodeAs				  = "none",
	name = 		"Investigative Operator",
	description= " pre-incident Ground Team <recruits agents/creates safehouses/interrogates suspects>",
	Acceleration = 0.4,
	BrakeRate = 0.3,
	TurnRate = 900,
	MaxVelocity = 2.2,
	floater = true,	
	
	--orders
	canMove	= true,
	CanAttack = true,
	CanGuard = true,

	CanMove = true,
	CanPatrol = true,
	CanStop = true,

	script 				= "operativeInvestigatorScript.lua",
	objectName        	= "operative_investigator.dae",

		buildPic = "operativeinvestigator.png",
	iconType ="operativeinvestigator",
	showNanoFrame= true,
	ActivateWhenBuilt=1,
	sightDistance = 100,
--cloaking behaviour
	canCloak =true,
	cloakCost=0.0001,
	cloakCostMoving =0.0001,
	cloakTimeout =  360,
	cloakCostMoving = 0,
	minCloakDistance = 0,
	initCloaked = false,
	stealth= true,
	transportByEnemy = true,
	
	onoffable= false,
	Builder = true,
	nanocolor=[[0.20 0.411 0.611]],--
	CanReclaim=false,	
	workerTime = 1.0,
	buildDistance = 120,
	terraformSpeed = 350,
	canSelfDestruct = false,

	buildoptions = 
	{	"protagonsafehouse",
		"checkpoint",
		"brehmerwall",		
		
		"air_copter_ssied",
		"air_copter_scoutlett",
		"air_parachut",

		"stealvehicleicon",
		"recruitcivilian",
		"icon_cybercrime"
	},

	customParams = {
		helptext		= "Investigative Operative",
		baseclass		= "Human", -- TODO: hacks
		normaltex = "unittextures/operative_investigator_normal.dds",
    },
	
	fireState= 1,
	
	weapons={
			[1]={name  = "raidarrest", --prevents other weapon usage
				onlyTargetCategory = [[RAIDABLE]],
			},				
			[2]={name  = "stunpistol",
				onlyTargetCategory = [[GROUND ARRESTABLE]],
				badTargetCategory = [[BUILDING]]
			}	,
			[3]={name  = "closecombat",
			onlyTargetCategory = [[CLOSECOMBATABLE]],
			noChaseCategory = [[CLOSECOMBATABLE]],
		}
		},	
	
	category = [[GROUND ARRESTABLE CLOSECOMBATABLE]],
	
}


return lowerkeys({
	--Temp
	["operativeinvestigator"] = OperativeInvestigator:New(),
	
})

