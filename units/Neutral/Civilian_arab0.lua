local Civilian = Human:New{
	corpse					  = "",
	maxDamage         	  = 500,
	mass                = 500,
	buildCostEnergy    	  = 5,
	buildCostMetal     	  = 5,
	canMove					  = true,
	name = "Civilian",
	description = " innocent bystander <colateral>",
	explodeAs				  = "none",
	Acceleration = 0.4,
	BrakeRate = 0.3,
	TurnRate = 900,
	MaxVelocity = 0.7875,
	

	CanAttack = false,
	CanGuard = true,

	CanMove = true,
	CanPatrol = true,
	CanStop = true,
	script 					= "civilianscript.lua",
	objectName        	= "civilian0_arab.dae",
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "10 25 10",

	
	customparams = {
		helptext		= "Civilian Building",
		baseclass		= "Human", -- TODO: hacks
    },
	
	category = [[GROUND]],
}


return lowerkeys({
	--Temp
	["civilian_arab0"] = Civilian:New(),
	
})