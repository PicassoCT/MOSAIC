local InformationPayload = Abstract:New{
	name 				= "Rocket Payload",
	description 		= "Information payload",
	maxDamage           = 5000,
	mass                = 500,
	buildtime			= 5*60,
	buildCostMetal     	= 9000,
	buildCostEnergy     = 9000,
	explodeAs			= "none",
	script 				= "warheadpayloadscript.lua",
	objectName        	= "WarHeadIcon.dae",
	buildPic 			= "intelligencepayload.png",
	alwaysupright		= true,
	cantBeTransported 	= false,
	iconType 			= "launcher",

	MaxSlope 			= 100,

	customparams = {
		helptext		= "Launcher step",
		baseclass		= "Abstract", 
		normaltex 		= "unittextures/component_atlas_normal.dds",
    },
	
	category = [[GROUND]],
}


return lowerkeys({
	["informationpayload"] = InformationPayload:New()
})

