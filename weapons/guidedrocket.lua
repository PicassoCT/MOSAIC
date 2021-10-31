--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "s16rocket" --
local weaponDef = {
    name = "Aiming Anti-Air Rocket",
    weaponType = [[MissileLauncher]],
	--damage
	damage = {
	default = 512
	},
	noSelfDamage = true,
	reloadtime = 8, -- seconds

	--orders behaviour
	--commandFire  = true,	
	canAttackGround = false,

	--aiming behaviour
	range = 1024,
	turnRate = 4096,
	turret = true,
	tracks = true,
	castshadow = false,
	predictBoost = 1.0,
	avoidFeature = true,
	avoidGround = true,
	
	--flight behaviour
	startVelocity  = 600,
	trajectoryHeight = 1.0 ,
	flightTime = 7.5 ,
	weaponVelocity = 2050,
	weaponAcceleration = 150,

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
