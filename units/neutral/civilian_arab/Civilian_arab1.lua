local Civil = Civilian:New{
	--This class inherits alot from its 
	name = "Civilian",
		corpse = "bodybag",
	description = " innocent bystander <colateral>",
	objectName        	= "civilian1_arab.dae",
	
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "10 25 10",
	mass = 80,
	buildPic = "civilian.png",
	iconType = "civilian",
	customparams = {
		baseclass		= "Civilian", -- TODO: hacks
		normaltex = "unittextures/arab_civilian_normal.dds",
    },

	
	category = [[GROUND ARRESTABLE CLOSECOMBATABLE]],
}


return lowerkeys({
	--Temp
	["civilian_arab1"] = Civil:New(),
})