local OrgyPair = {
	--This class inherits alot from its 
	name = "A Orgy",
	description = " engaged in intercourse",
	objectName        	= "orgy_pair.dae",

	
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "10 10 10",
	buildPic = "civilian.png",
	--orders	
	canAttack= false,
	canMove= false,
	canGuard=false,
	
	
	script = "civilianOrgyPairScript.lua",
	
	customParams = {
				normaltex = "unittextures/orgy_pair_normal.dds",
    },

	category = [[NOTARGET]],
}


return lowerkeys({
	--Temp
	["civilian_orgy_pair"] = OrgyPair
})