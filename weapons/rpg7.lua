--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "rpg7" --this is the actually maschinegune of the inferno trooper
local weaponDef = {
    name = "Rocket Propelled Grenade",
    weaponType = [[MissileLauncher]],
	--damage
	damage = {
	default = 350
	},
	noSelfDamage = true,
	reloadtime = 2, -- seconds

	--orders behaviour
	--commandFire  = true,	
	canAttackGround = true,

	--aiming behaviour
	range = 800,
	turnRate = 150,
	turret = true,
	tracks = true,

	avoidFeature = true,
	avoidGround = true,
	
	--flight behaviour
	startVelocity  = 1000,
	trajectoryHeight = 1.0 ,
	flightTime = 2.5 ,
	weaponVelocity = 1050,
	weaponAcceleration = 100,

	--impact behaviour
	impulseBoost            = 0,
	impulseFactor = 0.4,
    areaOfEffect = 128,
    fireStarter  = 50.0,

	--visuals
	smokeTrail = true,
	model = "rgp7rocket.s3o",
	explosionScar = true, 
	cameraShake = 0.5,
    explosionGenerator = "custom:missile_explosion",
    soundStart = "sounds/weapons/rocket/launch.wav",
    soundHit = "sounds/weapons/rocket/impact.wav",

}

return lowerkeys({ [weaponName] = weaponDef })
