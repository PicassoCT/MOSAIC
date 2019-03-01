-- Mechs ----
local Turret = Unit:New{

	FootprintX = 1,
	FootprintZ = 1,
	maxSlope = 50,
	
	MaxWaterDepth = 0,
	MovementClass = "Default2x2",

	
	nanocolor=[[0 0.9 0.9]],
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

return {
	Turret = Turret,

}
