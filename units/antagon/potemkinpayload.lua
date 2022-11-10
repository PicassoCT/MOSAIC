local PotemkinPayload = Abstract:New{
	name 				= "Rocket Payload (bring to launcher)",
	description 		= "made pretend Warhead",
	maxDamage           = 5000,
	mass                = 5000,
	buildtime			= 5*60,
	buildCostMetal     	= 900,
	buildCostEnergy     = 900,
	explodeAs			= "none",
	script 				= "warheadpayloadscript.lua",
	objectName        	= "WarHeadIcon.dae",
	buildPic 			= "physicalpayload.png",
	cantBeTransported 	= false,
	alwaysupright		= true,
	iconType 			= "launcher",
	MaxSlope 			= 100,

	customparams = {
		helptext		= "Warhead",
		baseclass		= "Abstract", 
		normaltex = "unittextures/component_atlas_normal.dds",
    },
	
	category = [[GROUND]],
}


return lowerkeys({
	["potemkinpayload"] = PotemkinPayload:New()
})

