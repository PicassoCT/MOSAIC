local Civil = Civilian:New{
	--This class inherits alot from its 
	name = "Civilian",
	corpse = "bodybag",
	description = " innocent bystander <colateral>",
	objectName        	= "civilian0_arab.dae",

	
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "10 25 10",
	buildPic = "civilian.png",
	iconType = "civilian",
	
	customParams = {
		baseclass		= "Civilian", -- TODO: hacks
		normaltex = "unittextures/arab_civilian_normal.dds",
    },
		
	weapons ={
		[1]={name  = "ak47",
				onlyTargetCategory = [[GROUND ARRESTABLE]],
			},	
		[2]={name  = "molotow",
				onlyTargetCategory = [[GROUND]],
			},
		[3]={name  = "rpg7",
					onlyTargetCategory = [[GROUND]],
				},	
	},
	category = [[GROUND ARRESTABLE CLOSECOMBATABLE]],
}


return lowerkeys({
	--Temp
	["civilian_arab0"] = Civil:New(),
})