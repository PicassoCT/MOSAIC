-- Mechs ----
local Human = Unit:New{
	activateWhenBuilt   	= true,
	canMove					= true,
	category 				= "GROUND",
	noChaseCategory		 	= "AIR BUILDING",
	onoffable        		= true,
	script					= "Civillian.lua",
	upright					= true,
	usepiececollisionvolumes = true,
	movementClass   		= "BIPEDAL",
	customparams = {
    },
}


-- Mechs ----
local Civilian = Human:New{
corpse					  = "",
	maxDamage         	  = 500,
	mass                = 500,
	buildCostEnergy    	  = 5,
	buildCostMetal     	  = 5,
	canMove					  = true,

	explodeAs				  = "none",
	Acceleration = 0.4,
	BrakeRate = 0.3,
	TurnRate = 900,
	MaxVelocity = 0.7875,
	

	CanAttack = true, -- todo undo
	CanGuard = true,

	CanMove = true,
	CanPatrol = true,
	CanStop = true,
	script 					= "civilianscript.lua",
	
		
	weapons ={
		[1]={name  = "ak47",
				onlyTargetCategory = [[GROUND ARRESTABLE]],
			},	
		[2]={name  = "molotow",
				onlyTargetCategory = [[GROUND]],
			},
	
	},
	
}



return {
	Human = Human,
	Civilian = Civilian,

}
