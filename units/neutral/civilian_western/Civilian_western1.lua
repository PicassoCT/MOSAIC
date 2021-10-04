local Civil = Civilian:New{
	--This class inherits alot from its 
	name = "Western Civilian",
		corpse = "bodybag",
	description = " innocent bystander <colateral>",
	objectName        	= "civilian4_arab.dae",
	
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "10 25 10",

	buildPic = "civilian.png",
	iconType = "civilian",
	customparams = {
		baseclass		= "Civilian", -- TODO: hacks
		normaltex = "unittextures/arab_civilian_normal.dds",
    },

	
	category = [[GROUND ARRESTABLE]],
}


return lowerkeys({
	--Temp
	["civilian_western1"] = Civil:New(),
})
