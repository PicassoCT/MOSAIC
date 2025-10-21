local BioWeaponsPayload = Abstract:New{
	name 				= "Bio Rocket Payload (transport to launcher)",
	description 		= "Snythetic Virus / Nano-tech Plague / Genocidefungi",
	maxDamage           = 5000,
	mass                = 5000,
	buildtime			= 5*60,
	buildCostMetal     	= 9000,
	buildCostEnergy     = 9000,
	explodeAs			= "none",
	script 				= "warheadpayloadscript.lua",
	objectName        	= "WarHeadIcon.dae",
	buildPic 			= "biologicalpayload.png",
	alwaysupright		= true,
	iconType 			= "launcher",
	cantBeTransported 	= false,
	MaxSlope 			= 100,

	customparams = {
		helptext		= "Launcher step",
		baseclass		= "Abstract", 
		normaltex 		= "unittextures/component_atlas_normal.dds",
    },
	
	category = [[GROUND]],
}


return lowerkeys({
	["biopayload"] = BioWeaponsPayload:New()
})

