local BioWeaponsPayload = Abstract:New{
	name 				= "Biological Warfare Payload",
	description 		= "Snythetic Virus / Nano-tech Plague / Fungigenocide",
	maxDamage           = 500,
	mass                = 500,
	buildtime			= 3*60,
	buildCostMetal     	= 15000,
	buildCostEnergy     = 15000,
	explodeAs			= "none",
	script 				= "warheadpayloadscript.lua",
	objectName        	= "WarHeadIcon.dae",
	buildPic = "biologicalpayload.png",

	iconType 			= "launcher",
	cantBeTransported = false,

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
	["biopayload"] = BioWeaponsPayload:New()
})
