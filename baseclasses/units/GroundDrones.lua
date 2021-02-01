-- Mechs ----
local Turret = Unit:New{

	FootprintX = 1,
	FootprintZ = 1,
	maxSlope = 50,
	
	MaxWaterDepth = 0,
	MovementClass = "Default2x2",
	fireState=1,
	
	nanocolor=[[0.20 0.411 0.611]],
	sightDistance = 250,
	activateWhenBuilt   	= true,
	cantBeTransported = false,

	--canHover=true,
	CanAttack = true,
	CanGuard = false,
	CanMove = false,
	CanPatrol = false,
	Canstop  = false,
	onOffable = false,
	LeaveTracks = false, 
	canCloak =true,
	upright				= true,
	onoffable           = true,
	script				= "placeholder.lua",

	usepiececollisionvolumes = true,
	
	customparams = {
		hasturnbutton	= true,
		baseclass		= "unit",
    },
}

local Walker = Unit:New{

	
	category 			= "VEHICLE GROUND",
	explodeAs          	= "mechexplode",
	leaveTracks			= true,	
	movementClass   	= "QUADRUPED",
	noChaseCategory		= "civilian air",
	trackType			= "Thick",
	script				= "placeholder.lua",
		usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "40 50 70",
	
	trackOffset			= 10,
	turnRate			= 300,
	customparams = {
    },
  }

return {
	Turret = Turret,
	Walker = Walker,

}
