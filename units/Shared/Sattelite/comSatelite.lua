local ComSatellit = Satellite:New{
	corpse				= "",
	maxDamage           = 500,
	mass                = 500,
	buildCostEnergy     = 5,
	buildCostMetal      = 5,
	explodeAs			= "none",
	--conType			= "infantry",
	maxVelocity		= 7.15, --14.3, --86kph/20
	--maxReverseVelocity= 2.15,
	acceleration    = 1.7,
	brakeRate       = 0.1,
	turninplace		= true,
	
	footprintX = 1,
	footprintZ = 1,
	script = "Satellite.lua",
	objectName        	= "satellite.s3o",

	--cruisealt = 50,
	--canfly = true,
	--hoverattack = true,
	--airhoverfactor = 10,
	--canLoopbackAttack = true,
	--usesmoothmesh = false,

	
	customparams = {
		helptext		= "Observationsatellite",
		baseclass		= "satellite", -- TODO: hacks
    },
}

return lowerkeys({
	--Temp
	["comsatellite"] = ComSatellit:New(),
	
})