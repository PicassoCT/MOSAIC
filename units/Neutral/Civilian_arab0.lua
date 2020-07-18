local Civil = Civilian:New{
	--This class inherits alot from its 
	name = "Civilian",
	description = " innocent bystander <colateral>",
	objectName        	= "civilian0_arab.dae",
		customParams        = {
		normaltex = "unittextures/arab_civilian_normal.dds",
	},
	
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "10 25 10",
	buildPic = "civilian.png",
	iconType = "civilian",
	
	customparams = {
		baseclass		= "Civilian", -- TODO: hacks
    },

	

	category = [[GROUND ARRESTABLE]],
}


return lowerkeys({
	--Temp
	["civilian_arab0"] = Civil:New(),
})