
local Civil = Civilian:New{
	--This class inherits alot from its 
	name = "Civilian",
		corpse = "bodybag",
	description = " innocent bystander <colateral>",
	objectName        	= "civilian0_western.dae",
	mass = 80,
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "10 25 10",

	buildPic = "civilian.png",
	iconType = "civilian",
	customParams = {
		baseclass		= "Civilian", -- TODO: hacks
		normaltex = "unittextures/western_civilian_normal.dds",
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
	["civilian_western0"] = Civil:New(),
})
