
local RiotPolice = Civilian:New{
	--This class inherits alot from its 
	name = "Riot Police",
	corpse = "bodybag",
	description = " Riot police",
	objectName        	= "riotPolice.dae",
	mass = 100,
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "10 25 10",
	script = "policescript.lua",
	buildPic = "civilian.png",
	iconType = "civilian",
	customParams = {
		baseclass		= "Civilian", -- TODO: hacks
		normaltex = "unittextures/western_civilian_normal.dds",
    },
		weapons={
			[1]={name  = "policebatton", --prevents other weapon usage
				onlyTargetCategory = [[GROUND]],
			},	
			}

	
	category = [[GROUND ARRESTABLE]],
}


return lowerkeys({
	--Temp
	["riotpolice"] = RiotPolice:New(),
})
