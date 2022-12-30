local advertising_blimp_hologram = Abstract:New{

	name = "Advertising Blimp Holograms ",

	objectName = "advertiseblimp_hologram.DAE",

	script = "advertisingblimphologramscript.lua",
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
	  	normaltex = "unittextures/component_atlas_normal.dds",
	  },
	
							


}

return lowerkeys({
	--Temp
	["advertising_blimp_hologram"] = advertising_blimp_hologram:New(),
	
})
