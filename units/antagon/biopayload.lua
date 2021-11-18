local BioWeaponsPayload = Abstract:New{
	name 				= "Biological Warfare Payload",
	description 		= "Snythetic Virus / Nano-tech Plague / Fungigenocide",
	maxDamage           = 500,
	mass                = 500,
	buildtime			= 3*60,
	buildCostMetal     	= 5000,
	buildCostEnergy     = 5000,
	explodeAs			= "none",
	script 				= "launcherstepscript.lua",
	objectName        	= "launcherstep.dae",
	buildPic = "launcherstep.png",

	
	iconType 			= "launcher",

	canCloak 			= true,
	cloakCost 			= 0.0001,
	ActivateWhenBuilt	= 1,
	cloakCostMoving 	= 0.0001,
	minCloakDistance 	= 0,
	onoffable			= true,
	initCloaked 		= true,
	decloakOnFire 		= false,
	cloakTimeout 		= 5,
	MaxSlope 			= 100,

	customparams = {
		helptext		= "Launcher step",
		baseclass		= "Abstract", 
		normaltex = "unittextures/testtex2.dds",
    },
	
	category = [[NOTARGET]],
}


return lowerkeys({
	["biopayload"] = BioWeaponsPayload:New()
})

