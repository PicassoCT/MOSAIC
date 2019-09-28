local Test = Human:New{
	corpse					  = "",
	maxDamage         	  = 500,
	mass                = 500,
	buildCostEnergy    	  = 5,
	buildCostMetal     	  = 5,
	canMove					  = true,
	name = "Test",
	description = " innocent colateral bystander",
	explodeAs				  = "none",
	Acceleration = 0.4,
	BrakeRate = 0.3,
	TurnRate = 900,
	MaxVelocity = 4.5*0.35,
	

	CanAttack = false,
	CanGuard = true,

	CanMove = true,
	CanPatrol = true,
	CanStop = true,
	script 					= "placeholder.lua",
	objectName        	= "test.dae",
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
	["test"] = Test:New(),
	
})