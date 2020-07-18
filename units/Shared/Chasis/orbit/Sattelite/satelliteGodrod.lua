local satteliteGodrod = Satellite:New{
	name = "Orbital Strike Satellite ",
	Description = " MOSAIC Standardized Assault Satellite ",

	maxDamage          		= 500,
	mass              		= 500,
	buildCostEnergy    		= 5,
	buildCostMetal      	= 5,
	explodeAs				= "none",
	maxVelocity				= 7.15, --14.3, --86kph/20
	acceleration   		 	= 1.7,
	brakeRate      		 	= 0.1,
	turninplace				= true,
	footprintX 				= 1,
	footprintZ 				= 1,
	script 					= "satellitegodscript.lua",
	objectName        		= "SatGodRod.dae",
		customParams        = {
		normaltex = "unittextures/component_atlas_normal.dds",
	},
	
	fireState				=0,
	alwaysupright			= true,
		upright= true,
	canManualFire = true,
	customparams			= {
		helptext		= "Observationsatellite",
		baseclass		= "Satellite", -- TODO: hacks
    },
	category = [[ORBIT]],
	buildPic = "orbitalstrike_sat.png",
	weapons = {
		[1]={
			name  = "godrod",   
			-- mainDir = "0 1 0",
			-- maxAngleDif = 90,
			onlyTargetCategory = [[GROUND]],
			},
					
		},	
		
}

return lowerkeys({
	--Temp
	["satellitegodrod"] = satteliteGodrod:New(),
	
})