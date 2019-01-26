local OperativePropagator = Human:New{
	corpse					  = "",
	maxDamage         	  = 500,
	mass                = 500,
	buildCostEnergy    	  = 5,
	buildCostMetal     	  = 5,

	explodeAs				  = "none",
	description= "Propaganda Operative <recruits Agents>",
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
	script 				= "operativePropagatorscript.lua",
	objectName        	= "operative_placeholder.s3o",

	-- Hack Infrastructure
	--CommandUnits (+10 Units)
	-- WithinCellsInterlinked (Recruit)
	
	Builder = true,
	nanocolor=[[0 0 0]], --
	CanReclaim=false,	
	workerTime = 0.005,
	buildDistance = 120,
	terraformSpeed = 1,
	
	canCloak =true,
	cloakCost=0.0001,
	cloakCostMoving =0.0001,
	minCloakDistance = 0,
	onoffable=true,

	buildoptions = 
	{
		"recruitcivilian",
		"antagonsafehouse"
	},

	customparams = {
		helptext		= "Propaganda Operative",
		baseclass		= "Human", -- TODO: hacks
    },
}


return lowerkeys({
	--Temp
	["operativepropagator"] = OperativePropagator:New(),
	
})

