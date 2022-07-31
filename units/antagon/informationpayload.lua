local InformationPayload = Abstract:New{
	name 				= "Rocket Payload",
	description 		= "Information payload",
	maxDamage           = 5000,
	mass                = 500,
	buildtime			= 3*60,
	buildCostMetal     	= 15000,
	buildCostEnergy     = 15000,
	explodeAs			= "none",
	script 				= "warheadpayloadscript.lua",
	objectName        	= "WarHeadIcon.dae",
	buildPic = "intelligencepayload.png",

		cantBeTransported = false,
	iconType 			= "launcher",

	
		alwaysUpright = true,
	MaxSlope 			= 100,

	customparams = {
		helptext		= "Launcher step",
		baseclass		= "Abstract", 
		normaltex = "unittextures/component_atlas_normal.dds",
    },
	
	category = [[GROUND]],
}


return lowerkeys({
	["informationpayload"] = InformationPayload:New()
})

