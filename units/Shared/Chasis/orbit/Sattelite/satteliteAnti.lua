local AntiSat = Satellite:New{
	name = "Cyclopian Satellite",
	Description = "destroys other satellites ",
	isFirePlatform 				= true,
	corpse						= "",
	transportSize				= 1024  ,
	transportCapacity 			= 18,
	maxDamage          			= 500,
	mass              			= 500,
	buildCostEnergy    			= 5,
	buildCostMetal      		= 5,
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
		customParams        = {
		normaltex = "unittextures/component_atlas_normal.png",
	},
	buildPic = "satellite.png",
	usePieceCollisionVolumes 	= false,
	upright= true,
	collisionVolumeType = "box",
	collisionVolumeScales = {1.0,1.0,1.0},
	collisionVolumeOffsets  ={0.0,0.0,0.0},
	
	customparams = {
		helptext		= "Anti-Satellite Satellite",
		baseclass		= "Satellite", -- TODO: hacks
    },
		category = [[ORBIT]],
		

	
	

}

return lowerkeys({
	--Temp
	["satelliteanti"] = AntiSat:New(),
	
})