--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "icarusglidebomb" --
local weaponDef = {
    name = "Glidebomb",
    -- Released explicitly after folding; native gravity and collision, no motor.
    weaponType = [[AircraftBomb]],
	--damage
	damage = {
	default = 512
	},
	noSelfDamage = true,
	reloadtime = 8, -- seconds

	--orders behaviour
	--commandFire  = true,	
	canAttackGround = true,

	--aiming behaviour
	range = 1024 + 512+ 64,
	turret = true,
	avoidFeature = true,
	avoidGround = true,
	
	alwaysVisible = true,
	--flight behaviour
	-- The unit script supplies the map's gravity and initial downward velocity.

	--impact behaviour
	impulseBoost  = 1,
	impulseFactor = 1.4,
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
