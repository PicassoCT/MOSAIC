local Hologram = Abstract:New{

	name = "asian_advertisement_hologram",

	objectName = "blimp_asian_hologram1.DAE",

	script = " projectedHologramAddScript.lua",
	mass = 1,
	--floater = true,
	--cost	
	--Health
	maxDamage = 9000,
	idleAutoHeal = 0,
	--Movement
	FootprintX = 1,
	FootprintZ = 1,


	MovementClass = "AIRUNIT",
	TurnRate = 50,

	--canHover=true,
	
	ActivateWhenBuilt=1,
	

	Category = [[AIR]],

	  customParams = {
	  	baseclass = "Abstract",
	  	normaltex = "unittextures/house_asian_normal.dds",
	  },
	
							


}

return lowerkeys({
	--PornoRama
	["advertising_blimp_asian_hologram1"] = Hologram:New(),
	
})
