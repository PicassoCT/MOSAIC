local AntiSat = Satellite:New{
	name = "Spacecraft  Destroyer",
	Description = "Destroys other satellites ",
	isFirePlatform 				 = true,
	corpse						= "",
	transportSize  = 4,
	transportCapacity = 1,
	maxDamage          		= 500,
	mass              	= 500,
	buildCostEnergy    		= 5,
	buildCostMetal      		= 5,
	explodeAs					= "none",
	maxVelocity					= 7.15, --14.3, --86kph/20
	acceleration   		 	= 1.7,
	brakeRate      		 	= 0.1,
	turninplace					= true,
	sightDistance 				= 320,
	footprintX 					= 1,
	footprintZ 					= 1,
	noAutoFire                = false,
	script 						= "satelliteantitscript.lua",
	objectName        		= "satellite.s3o",
	usePieceCollisionVolumes = false,
	customparams = {
		helptext		= "Observationsatellite",
		baseclass		= "Satellite", -- TODO: hacks
    },
		category = [[ORBIT]],
		

}

return lowerkeys({
	--Temp
	["satelliteanti"] = AntiSat:New(),
	
})