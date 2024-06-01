
local house_western_hologram = Abstract:New{
	
	maxDamage        	= 9000,
	mass           		= 0,
	name = "Western Style Housing",	
	FootprintX = 1,
	FootprintZ = 1,
	script 				= "house_western_hologram_script.lua",
	objectName       	= "house_western_hologram.dae",

	
	

	customparams = {	
		normaltex = "unittextures/house_europe_normal.dds",
		helptext			= "Civilian Building",
		baseclass			= "Abstract", -- TODO: hacks
    },
	
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "130 60 130",
	collisionVolumeOffsets  = {0.0, 30.0,  0.0},
	category = [[NOTARGET ABSTRACT]],

}


local house_western_hologram_brothel = Abstract:New{
	
	maxDamage        	= 9000,
	mass           		= 0,
	name = "Western Style Housing",	
	FootprintX = 1,
	FootprintZ = 1,
	script 				= "house_western_brothel_hologram_script.lua",
	objectName       	= "house_western_brothel_hologram.dae",

	
	

	customparams = {	
		normaltex = "unittextures/house_europe_normal.dds",
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
	["house_western_hologram_buisness"] = house_western_hologram:New(),
	["house_western_hologram_brothel"] = house_western_hologram_brothel:New(),
	["house_western_hologram_casino"] = house_western_hologram:New(),
})
