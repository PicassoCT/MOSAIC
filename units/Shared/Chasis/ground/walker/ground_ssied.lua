local groundSSIED = Truck:New{
	name = "SSIED",
	Description = "Standardized Smart Improvised Explosive Device ",
	corpse				= "",
	maxDamage = 500,
	mass = 500,


	explodeAs			= "none",
	buildCostMetal = 50,
	buildCostEnergy = 0,
	buildTime = 5,
	--Health
	maxDamage = 50,
	idleAutoHeal = 0,
	--Movement
	Acceleration = 0.5,
	 fireState=1,
	turninplace		= true,
	footprintX = 1,
	footprintZ = 1,
	objectName = "ssied.s3o",
	script = "airssiedscript.lua",
	movementClass   	= "VEHICLE",
	
	customparams = {
		helptext		= "Military Truck/Technical",
		baseclass		= "Truck", -- TODO: hacks
	},
	
	Category = [[LAND]],

	  customParams = {},
	 sfxtypes = {
		explosiongenerators = {
							"custom:bigbulletimpact"
							  },
				},
				
				weapons = {
				[1]={name  = "ssied",
					onlyTargetCategory = [[BUILDING LAND]],
					},
					
		},	
}



return lowerkeys({
	--Temp
	["groundssied"]			 	= groundSSIED:New()	
})
