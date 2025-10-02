local PornoRama = Abstract:New{

	name = "PornoRama",

	objectName = "PornoRama.dae",

	script = "advertising_blimp_pornoramascript.lua",
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
	["advertising_blimp_pornorama"] = PornoRama:New(),
	
})
