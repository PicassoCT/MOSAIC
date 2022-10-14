local Civil = Civilian:New{
	--This class inherits alot from its 
	name = "Civilian",
		corpse = "bodybag",
	description = " innocent bystander <colateral>",
	objectName        	= "civilian3_arab.dae",

	mass = 80,
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "10 25 10",
	buildPic = "civilian.png",
	iconType = "civilian",
	customParams = {
		baseclass		= "Civilian", -- TODO: hacks
		normaltex = "unittextures/arab_civilian_normal.dds",
    },

	

	category = [[GROUND ARRESTABLE CLOSECOMBATABLE]],
}


return lowerkeys({
	--Temp
	["civilian_arab3"] = Civil:New(),
})