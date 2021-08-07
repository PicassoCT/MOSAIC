local SatelliteShrapnell = Satellite:New{
	name = "Shrapnellcloud  ",
	Description = " damages satellites",
	buildTime= 15,
	corpse				= "",
	maxDamage 			= 15000,
	mass 				= 500,
	buildCostEnergy 	= 250,
	buildCostMetal 		= 250,
	explodeAs			= "none",
	--conType			= "infantry", 
	maxVelocity			= 7.15, --14.3, --86kph/20
	--maxReverseVelocity= 2.15,
	acceleration 		= 1.7,
	brakeRate 			= 0.1,
	turninplace			= true,

	footprintX 			= 1,
	footprintZ 			= 1,
	script 				= "satelliteshrapnellcloudscript.lua",
	objectName 			= "satShrapnell.dae",

	buildPic = "ShrapnellSatellite.png",
	sightDistance		= 	500, --formula offset:  radius^2 =  altitude^2   + (radius+x)  ^2
	upright= true,

	customparams = {
		helptext		= "Observationsatellite",
		baseclass		= "Satellite", -- TODO: hacks,
		normaltex = "unittextures/component_atlas_normal.dds",
	},

	sfxtypes = {
		explosiongenerators = {
							"custom:glowingshrapnell", --1024
							"custom:meteor", --1024
							  },
				},
	

	category = [[ORBIT]],
}

return lowerkeys({
	["satelliteshrapnell"] = SatelliteShrapnell:New(),
	
})