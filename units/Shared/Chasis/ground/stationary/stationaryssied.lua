local unitName = "stationaryssied"
local unitDef = {
	name = "SIED",
	Description = " 3.. 2... 1 <Projectile>",
	objectName = "ssied.s3o",
	script = "placeholder.lua",
	buildPic = "placeholder.png",
	--cost
	buildCostMetal = 25,
	buildCostEnergy = 0,
	buildTime = 5,
	--Health
	maxDamage = 50,
	idleAutoHeal = 3,
	--Movement
	Acceleration = 0,
	BrakeRate = 0,
	FootprintX = 1,
	FootprintZ = 1,
	MaxSlope = 5,
	MaxVelocity = 0,
	MaxWaterDepth = 20,
	MovementClass = "Default2x2",
	TurnRate = 5,
	mass=950,
	nanocolor=[[0 0.9 0.9]],
	sightDistance = 450,
	selfDestructAs= [[NOWEAPON]],
	Builder = false,
	CanAttack = true,
	CanGuard = false,
	CanMove = true,
	CanPatrol = false,
	CanStop = true,
	LeaveTracks = false, 
	levelGround =false,
	Category = [[LAND]],
	sfxtypes = {
		explosiongenerators = {				 
			-- "custom:tess",
			-- "custom:redlight"
			
			
		},
	},
	  customParams           = {

  },

	explodeAs = [[NOWEAPON]],
	selfDestructAs= [[NOWEAPON]], 
	
	
}
return lowerkeys({ [unitName] = unitDef })