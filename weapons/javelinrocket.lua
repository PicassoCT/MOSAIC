--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "javelinrocket" 
local weaponDef = {
    name = "Indirect Self Aiming Rocket with Shaped Charge",
    weaponType = [[MissileLauncher]],

    damage = {
        default = 1600
    },
	range = 1024,
	impulseBoost            = 0,
	impulseFactor = 0.4,
	reloadtime = 10,
    areaOfEffect = 64,
	 noSelfDamage = true,
	trajectoryHeight = 200,
	avoidFeature            = false,
	avoidGround = false,
	smokeTrail = true,
	startVelocity  = 380,
	weaponAcceleration = 1,
	turnRate = 1800,
	weaponVelocity = 1250,
	tracks = true,
	flightTime = 14.5 ,
	turret = true,
	model = "air_copter_antiarmor_projectile.s3o",
	explosionScar = true, 
    explosionGenerator = "custom:missile_explosion",
    soundStart = "sounds/weapons/javelin/launch.ogg",
    soundHit = "sounds/weapons/javelin/impact.ogg",
   
    texture1 = "gunshot",
	fireStarter  = 50.0,
	cameraShake =1.0
	
    }
  
return lowerkeys({ [weaponName] = weaponDef })