local PhysicsPayload = Abstract:New{
	name 				= "Physical Warfare Payload",
	description 		= "Fusion / Entanglement Irradiation / Tectonics Bust Warhead",
	maxDamage           = 500,
	mass                = 500,
	buildtime			= 3*60,
	buildCostMetal     	= 15000,
	buildCostEnergy     = 15000,
	explodeAs			= "none",
	script 				= "warheadpayloadscript.lua",
	objectName        	= "WarHeadIcon.dae",
	buildPic = "physicalpayload.png",

	
	iconType 			= "launcher",
	MaxSlope 			= 100,

	customparams = {
		helptext		= "Launcher step",
		baseclass		= "Abstract", 
		normaltex = "unittextures/component_atlas_normal.dds",
    },
	
	category = [[GROUND]],
}


return lowerkeys({
	["physicspayload"] = PhysicsPayload:New()
})

