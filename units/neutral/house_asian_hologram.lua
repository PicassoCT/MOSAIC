
local house_asian_hologram = Abstract:New{
	
	maxDamage        	= 9000,
	mass           		= 0,
	name = "Western Style Housing",	
	FootprintX = 1,
	FootprintZ = 1,
	script 				= "house_asian_hologram_script.lua",
	objectName       	= "house_asian_hologram.dae",

	
	

	customparams = {	
		normaltex = "unittextures/house_asian_normal.dds",
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
	--Temp
	["house_asian_hologram_buisness"] = house_asian_hologram:New(),
	
})
