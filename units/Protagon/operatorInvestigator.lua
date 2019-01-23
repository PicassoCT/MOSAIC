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
	cloakCostMoving =0.0001,
	minCloakDistance = 15,
	onoffable=true,
	
	Builder = true,
	nanocolor=[[0 0 0]], --
	CanReclaim=false,	
	workerTime = 0.005,
	buildDistance = 60,
	terraformSpeed = 1,
		

	buildoptions = 
	{
		"recruitcivilian",
		"antagonsafehouse"
	},

	customparams = {
		helptext		= "Investigative Operative",
		baseclass		= "Human", -- TODO: hacks
    },
}


return lowerkeys({
	--Temp
	["operativinvestigator"] = OperativeInvestigator:New(),
	
})

