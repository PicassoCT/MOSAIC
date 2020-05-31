--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "s16rocket" --this is the actually maschinegune of the inferno trooper
local weaponDef = {
    name = "Unguided Rattler Rocket",
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
	trajectoryHeight = 1.0 ,
	avoidFeature            = true,
	avoidGround = true,
	smokeTrail = true,
	startVelocity  = 580,
	weaponAcceleration = 100,
	turnRate = 150,
	weaponVelocity = 1050,
	tracks = false,
	flightTime = 5.5 ,
	turret = true,
	model = "air_copter_antiarmor_projectile.s3o",
	explosionScar = true, 
    explosionGenerator = "custom:missile_explosion",
    cegTag = "gunprojectile",
    texture1 = "gunshot",
	fireStarter  = 50.0,
	cameraShake = 0.5
	
    }
  
return lowerkeys({ [weaponName] = weaponDef })