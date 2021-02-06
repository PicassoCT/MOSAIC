local SatelliteShrapnell = Satellite:New{
	name = "Shrapnellcloud Projectile ",
	Description = " MOSAIC Standardized Reconnisance Satellite ",
	buildTime= 15,
	corpse				= "",
	maxDamage 			= 5000,
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
	
		customParams        = {
		normaltex = "unittextures/component_atlas_normal.dds",
	},
	buildPic = "ShrapnellSatellite.png",
	sightDistance		= 	500, --formula offset:  radius^2 =  altitude^2   + (radius+x)  ^2
		upright= true,	
	customparams = {
		helptext		= "Observationsatellite",
		baseclass		= "Satellite", -- TODO: hacks
	},
	category = [[ORBIT]],
}

return lowerkeys({
	["satelliteshrapnell"] = SatelliteShrapnell:New(),
	
})