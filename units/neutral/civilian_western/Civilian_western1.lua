local Civil = Civilian:New{
	--This class inherits alot from its 
	name = "Civilian",
		corpse = "bodybag",
	description = " innocent bystander <colateral>",
	objectName        	= "civilian1_western.dae",
	mass = 80,
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "10 25 10",
	pushResistant = false,
	buildPic = "civilian.png",
	iconType = "civilian",
	customParams = {
		baseclass		= "Civilian", -- TODO: hacks
		normaltex = "unittextures/western_civilian_normal.dds",
    },

	
	category = [[GROUND ARRESTABLE CLOSECOMBATABLE]],
}


return lowerkeys({
	--Temp
	["civilian_western1"] = Civil:New(),
})
