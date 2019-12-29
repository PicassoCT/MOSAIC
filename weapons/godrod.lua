--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "godrod" --this is the actually maschinegune of the inferno trooper
local weaponDef = {
    name = "Mjoelnir Project",
    weaponType = [[MissileLauncher]],

    damage = {
        default = 3500
    },

	range = 3000,
	impulseBoost            = 0,
	impulseFactor = 0.4,
	reloadtime = 1,
    areaOfEffect = 512,
	 noSelfDamage = true,
	trajectoryHeight = 2.1 ,
	avoidFeature            = false,
	avoidGround = false,
	smokeTrail = true,
	startVelocity  = 380,
	weaponAcceleration = 100,
	turnRate = 150,
	weaponVelocity = 450,
	tracks = false,
	flightTime = 14.5 ,
	turret = true,
	model = "air_copter_antiarmor_projectile.s3o",
	explosionScar = true, 
    explosionGenerator = "custom:missile_explosion",
    cegTag = "gunprojectile",
    texture1 = "gunshot",
	fireStarter  = 100.0,
	cameraShake =1.0
	
    }
  
return lowerkeys({ [weaponName] = weaponDef })