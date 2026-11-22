local Suicidebomber = Human:New{
	name = "Civilian Suicide Bomber",
	Description = "Disguised bomber; attack a target to approach and commit to a final sprint",

	corpse = "bodybag",
	maxDamage         	  = 150,
	mass                = 100,
	buildCostEnergy    	  = 150,
	buildCostMetal     	  = 500,
	canMove					  = true,
	MetalStorage 		= 250,

	explodeAs				  = "none",
	Acceleration = 0.51,
	BrakeRate = 0.35,
	TurnRate = 900,
	MaxVelocity = 0.82,
	showNanoFrame= true,
	
	buildtime			 = 25,
	CanAttack = true,
	CanGuard = true,

	CanMove = true,
	CanPatrol = true,
	CanStop = true,
	script 				= "civilianagentscript.lua",
	objectName        	= "civilian0_arab.dae",
	buildPic 			= "civilianagent.png",
	iconType 			= "civilianagent",

--cloaking behaviour
	canCloak =true,
	cloakCost=0.01,
	cloakCostMoving =0,
	cloakTimeout = 9000,
	minCloakDistance = 0,
	initCloaked = true,
	stealth = true,
	
	fireState = 0,
	-- The bomber charge gadget owns contact detonation, never proximity alone.
	kamikaze = false,
	kamikazeDistance  = 70,
	kamikazeUseLOS = true,
	
	decloakOnFire = true,

	category = [[GROUND]],
	
	customParams = {
		helptext		= "Surveillance marks this bomber even in disguise. Attack a target: within sprint range, cover is lost and control is locked until detonation on contact. Gunfire kills have a 50% chance to detonate the bomb.",
		baseclass		= "Human", -- TODO: hacks
		normaltex = "unittextures/arab_civilian_normal.dds",
    },
    selfDestructAs  = "ssied",

	 sfxtypes = {
		explosiongenerators = {
							"custom:bigbulletimpact",
							"custom:tess"
							  },
				},	
	
}


return lowerkeys({
	--Temp
	["civilian_suicidebomber"] = Suicidebomber:New(),
	
})

