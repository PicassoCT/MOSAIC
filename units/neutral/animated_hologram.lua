
local animated_hologram = Abstract:New{
	
	maxDamage        	= 9000,
	mass           		= 0,
	name = "Animated Hologram",	
	FootprintX = 1,
	FootprintZ = 1,
	script 				= "animated_hologramscript.lua",
	objectName       	= "animated_hologram.dae",

	
	

	customparams = {	
		helptext			= "Civilian Building",
		baseclass			= "Abstract", -- TODO: hacks
    },
	
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "130 60 130",
	collisionVolumeOffsets  = {0.0, 30.0,  0.0},
	category = [[NOTARGET ABSTRACT]],

}

return lowerkeys({
	["animated_hologram"] = animated_hologram:New(),	
})
