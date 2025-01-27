--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "icarusglidebomb" --
local weaponDef = {
    name = "Glidebomb",
    weaponType = [[MissileLauncher]],
	--damage
	damage = {
	default = 512
	},
	noSelfDamage = true,
	reloadtime = 8, -- seconds

	--orders behaviour
	--commandFire  = true,	
	canAttackGround = true,
	canManualFire = true,
	--aiming behaviour
	range = 512 + 64,
	turnRate = 4096,
	turret = true,
	tracks = false,
	castshadow = true,
	predictBoost = 1.0,
	avoidFeature = true,
	avoidGround = true,
	
	alwaysVisible = true,
	--flight behaviour
	startVelocity  = 0,
	trajectoryHeight = 1.0 ,
	flightTime = 150.5 ,
	weaponVelocity = 2050,
	weaponAcceleration = 150,

	--impact behaviour
	impulseBoost  = 0,
	impulseFactor = 0.4,
    areaOfEffect = 128,
    fireStarter  = 50.0,
 	
	--visuals
	smokeTrail = false,
	model = "air_plane_artillery_projectile.dae",
	explosionScar = true, 
	cameraShake = 0.5,
    explosionGenerator = "custom:missile_explosion",
    soundStart = "sounds/weapons/rocket/launch.wav",
    soundHit = "sounds/weapons/rocket/impact.wav",
}

return lowerkeys({ [weaponName] = weaponDef })
