--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "s16rocket" --
local weaponDef = {
    name = "Unguided Rocket",
    weaponType = [[MissileLauncher]],
	--damage
	damage = {
	default = 250
	},
	noSelfDamage = true,
	reloadtime = 2, -- seconds

	--orders behaviour
	--commandFire  = true,	
	canAttackGround = true,

	--aiming behaviour
	range = 1024,
	turnRate = 150,
	turret = true,
	tracks = true,

	avoidFeature = true,
	avoidGround = true,
	
	--flight behaviour
	startVelocity  = 580,
	trajectoryHeight = 1.0 ,
	flightTime = 5.5 ,
	weaponVelocity = 1050,
	weaponAcceleration = 100,

	--impact behaviour
	impulseBoost            = 0,
	impulseFactor = 0.4,
    areaOfEffect = 128,
    fireStarter  = 50.0,

	--visuals
	smokeTrail = true,
	model = "unaimedRocketProjectile.s3o",
	explosionScar = true, 
	cameraShake = 0.5,
    explosionGenerator = "custom:missile_explosion",
    soundStart = "sounds/weapons/rocket/launch.wav",
    soundHit = "sounds/weapons/rocket/impact.wav",

}

return lowerkeys({ [weaponName] = weaponDef })