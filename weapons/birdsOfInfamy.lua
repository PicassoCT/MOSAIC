--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "icarusglidebomb" --
local weaponDef = {
    name = "Glidebomb",
    -- Native bomber release after the unit script finishes folding its wings.
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
	-- Ordinary shots inherit the native aircraft's motion. Glide exhaustion
	-- spawns this same native projectile once, locally, even without a target.

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
