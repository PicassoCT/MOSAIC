local PhysicsPayload = Abstract:New{
	name 				= "Rocket Payload (transport to launcher)",
	description 		= "Diamond Anvil Cascadefusion / Anti-Matter - Warhead",
	maxDamage           = 5000,
	mass                = 5000,
	buildtime			= 5*60,
	buildCostMetal     	= 9000,
	buildCostEnergy     = 9000,
	script 				= "warheadpayloadscript.lua",
	objectName        	= "WarHeadIcon.dae",
	buildPic 			= "physicalpayload.png",
	cantBeTransported 	= false,
	alwaysupright		= true,
	iconType 			= "launcher",
	MaxSlope 			= 100,
	--"explodeAs"			= "commanderexplosion",

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

