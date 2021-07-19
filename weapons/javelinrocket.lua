--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "javelinrocket" 
local weaponDef = {
    name = "Indirect Self Aiming Rocket with Shaped Charge",
    weaponType = [[StarburstLauncher]],

    damage = {
        default = 1600
    },

	range = 1024,
	impulseBoost    = 1,
	impulseFactor = 3.4,
	reloadtime = 10,
    areaOfEffect = 64,
	 noSelfDamage = true,
	avoidFeature   = false,
	avoidGround = false,
	smokeTrail = true,
	startVelocity  = 380,
	weaponTimer  = 2.0,
	weaponAcceleration = 1,
	turnRate = 12600,
	weaponVelocity = 2550,
	tracks = true,
	flightTime = 14.5 ,
	turret = true,
	model = "air_copter_antiarmor_projectile.s3o",
	explosionScar = true, 
    explosionGenerator = "custom:missile_explosion",
    soundStart = "sounds/weapons/javelin/launch.ogg",
    soundHit = "sounds/weapons/javelin/impact.ogg",
    craterMult = 0.0,
    texture1 = "gunshot",
	fireStarter  = 50.0,
	cameraShake =1.0
	
    }
  
return lowerkeys({ [weaponName] = weaponDef })