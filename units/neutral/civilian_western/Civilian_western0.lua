
local Civil = Civilian:New{
	--This class inherits alot from its 
	name = "Western Civilian",
		corpse = "bodybag",
	description = " innocent bystander <colateral>",
	objectName        	= "civilian0_western.dae",
	
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "10 25 10",

	buildPic = "civilian.png",
	iconType = "civilian",
	customparams = {
		baseclass		= "Civilian", -- TODO: hacks
		normaltex = "unittextures/western_civilian_normal.dds",
    },

	
	category = [[GROUND ARRESTABLE]],
}


return lowerkeys({
	--Temp
	["civilian_western0"] = Civil:New(),
})
