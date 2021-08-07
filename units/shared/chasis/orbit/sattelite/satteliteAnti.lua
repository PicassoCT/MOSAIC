local AntiSat = Satellite:New{
	name = "Project Excalibur: Anti-Satellite",
	buildTime= 80,
	Description = "destroys other satellites ",
	isFirePlatform 				= true,
	corpse						= "",
	transportSize				= 1024  ,
	transportCapacity 			= 18,
	maxDamage          			= 500,
	mass              			= 500,
	buildCostEnergy    			= 750,
	buildCostMetal      		= 750,
	explodeAs					= "none",
	maxVelocity					= 7.15, --14.3, --86kph/20
	acceleration   		 		= 1.7,
	brakeRate      		 		= 0.01,
	turninplace					= true,
	canattack					= true,
	sightDistance 				= 320,
	footprintX 					= 1,
	footprintZ 					= 1,
	noAutoFire                	= false,
	script 						= "satelliteantiscript.lua",
	objectName        			= "orbit_satellite_cyclops.dae",

	buildPic = "antisattelit_sat.png",
	usePieceCollisionVolumes 	= false,
	upright= true,
	fireState = 2,
	collisionVolumeType = "box",
	collisionVolumeScales = {1.0,1.0,1.0},
	collisionVolumeOffsets  ={0.0,0.0,0.0},
	
	customParams = {
		helptext		= "Anti-Satellite Satellite",
		baseclass		= "Satellite", -- TODO: hacks
		normaltex = "unittextures/component_atlas_normal.dds",
    },
		
	category = [[ORBIT]],
		

	
	

}

return lowerkeys({
	--Temp
	["satelliteanti"] = AntiSat:New(),
	
})