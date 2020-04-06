local Civil = Civilian:New{
	--This class inherits alot from its 
	name = "Civilian",
	description = " innocent bystander <colateral>",
	objectName        	= "civilian3_arab.dae",
			customParams        = {
		normaltex = "unittextures/arab_civilian_normal.png",
	},
	
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "10 25 10",
		buildPic = "civilian.png",
	
	customparams = {
		baseclass		= "Civilian", -- TODO: hacks
    },

	

	category = [[GROUND ARRESTABLE]],
}


return lowerkeys({
	--Temp
	["civilian_arab3"] = Civil:New(),
})