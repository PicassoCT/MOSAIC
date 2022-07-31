local PhysicsPayload = Abstract:New{
	name 				= "Rocket Payload (bring to launcher)",
	description 		= "Collapse Fusion / Anti-Matter / Entanglement Warhead",
	maxDamage           = 5000,
	mass                = 500,
	buildtime			= 3*60,
	buildCostMetal     	= 15000,
	buildCostEnergy     = 15000,
	explodeAs			= "none",
	script 				= "warheadpayloadscript.lua",
	objectName        	= "WarHeadIcon.dae",
	buildPic = "physicalpayload.png",
	cantBeTransported = false,
	
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
	["physicspayload"] = PhysicsPayload:New()
})

