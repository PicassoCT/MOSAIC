--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "javelinrocket" --this is the actually maschinegune of the inferno trooper
local weaponDef = {
    name = "Indirect Self Aiming Rocket with Shaped Charge",
    weaponType = [[MissileLauncher]],

    damage = {
        default = 1500
    },
	range = 1024,
	impulseBoost            = 0,
	impulseFactor = 0.4,
	reloadtime = 10,
    areaOfEffect = 256,
	 noSelfDamage = true,
	trajectoryHeight = 2.1 ,
	avoidFeature            = false,
	avoidGround = false,
	smokeTrail = true,
	startVelocity  = 380,
	weaponAcceleration = 100,
	turnRate = 150,
	weaponVelocity = 450,
	tracks = true,
	flightTime = 14.5 ,
	turret = true,
	model = "air_copter_antiarmor_projectile.s3o",
	explosionScar = true, 
    explosionGenerator = "custom:missile_explosion",
    cegTag = "gunprojectile",
    texture1 = "gunshot",
	fireStarter  = 50.0,
	cameraShake =1.0
	
    }
  
return lowerkeys({ [weaponName] = weaponDef })