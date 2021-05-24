--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "rpg7"
local weaponDef = {
    name = "Rocket Propelled Grenade",
    weaponType = [[MissileLauncher]],
	--damage
	damage = {
	default = 350
	},
	noSelfDamage = false,
	reloadtime = 15, -- seconds

	--orders behaviour
	--commandFire  = true,	
	canAttackGround = true,

	--aiming behaviour
	range = 800,
	turnRate = 1,
	turret = true,
	tracks = false,

	avoidFeature = true,
	avoidGround = true,
	
	--flight behaviour
	startVelocity  = 1000,
	trajectoryHeight = 0.1 ,
	flightTime = 2.5 ,
	weaponVelocity = 1050,
	weaponAcceleration = 100,

	--impact behaviour
	impulseBoost            =2,
	impulseFactor = 0.4,
    areaOfEffect = 128,
    fireStarter  = 90.0,

	--visuals
	smokeTrail = true,
	
	model = "rpg7rocket.s3o",
	explosionScar = true, 
	cameraShake = 0.5,
    explosionGenerator = "custom:missile_explosion",
    soundStart = "sounds/weapons/rocket/launch.wav",
    soundHit = "sounds/weapons/rocket/impact.wav",

}

return lowerkeys({ [weaponName] = weaponDef })
