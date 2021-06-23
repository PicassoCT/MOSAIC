local ScanSat = Satellite:New{
	name = "Surveilance & Data Collector Satellite ",
	Description = "Transfers Data gathered in Raids home",
	buildTime 			= 15,
	corpse				= "",
	maxDamage 			= 500,
	mass 				= 500,
	buildCostEnergy 	= 500,
	buildCostMetal 		= 500,
	explodeAs			= "none",
	--conType			= "infantry", 
	maxVelocity			= 7.15, --14.3, --86kph/20
	--maxReverseVelocity= 2.15,
	acceleration 		= 1.7,
	brakeRate 			= 0.1,
	turninplace			= true,

	footprintX 			= 1,
	footprintZ 			= 1,
	script 				= "satellitescript.lua",
	objectName 			= "SpySat.dae",
		customParams        = {
		normaltex = "unittextures/component_atlas_normal.dds",
	},
	buildPic = "surveilance_sat.png",
	sightDistance		= 	500, --formula offset:  radius^2 =  altitude^2   + (radius+x)  ^2
		upright= true,	
	customparams = {
		helptext		= "Observationsatellite",
		baseclass		= "Satellite", -- TODO: hacks
	},
	category = [[ORBIT]],
}

return lowerkeys({
	["satellitescan"] = ScanSat:New(),
	
})