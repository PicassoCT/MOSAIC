local BuildLauncherStep = Abstract:New{
	name =  "Launcher",
	description = " build xth step out of n",
	maxDamage         	  = 500,
	mass                = 500,
	buildCostEnergy    	  = 0,
	buildCostMetal     	  = 5000,
	explodeAs				  = "none",
	script 				= "placeholder.lua",
	objectName        	= "launcherstep.s3o",
	
	canCloak =true,
	cloakCost=0.0001,
	ActivateWhenBuilt=1,
	cloakCostMoving =0.0001,
	minCloakDistance = 0,
	onoffable=true,
	initCloaked = true,
	decloakOnFire = true,
	cloakTimeout = 5,
	MaxSlope 					= 100,


	customparams = {
		helptext		= "Launcher step",
		baseclass		= "Abstract", 
    },
	
	category = [[NOTARGET]],
}


return lowerkeys({
	["launcherstep"] = BuildLauncherStep:New()
})

