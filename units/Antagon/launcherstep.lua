local BuildLauncherStep = Abstract:New{
	name =  "Launcher",
	description = " build xth step out of n",
	maxDamage         	  = 500,
	mass                = 500,
	buildCostEnergy    	  = 0,
	buildCostMetal     	  = 5000,
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
		baseclass		= "Abstract", 
    },
	
	category = [[NOTARGET]],
}


return lowerkeys({
	["launcherstep"] = BuildLauncherStep:New()
})

