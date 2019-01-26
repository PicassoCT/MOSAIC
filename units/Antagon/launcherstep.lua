local BuildLauncherStep = Abstract:New{
	maxDamage         	  = 500,
	mass                = 500,
	buildCostEnergy    	  = 5,
	buildCostMetal     	  = 5,
	explodeAs				  = "none",
	script 				= "placeholder.lua",
	objectName        	= "placeholder.s3o",
	
	canCloak =true,
	cloakCost=0.000001,
	cloakCostMoving =0.0001,
	minCloakDistance = 5,
	onoffable=true,
	MaxSlope 					= 100,


	customparams = {
		helptext		= "Launcher step",
		baseclass		= "Human", 
    },
}


return lowerkeys({
	["launcherstep"] = BuildLauncherStep:New()
})

