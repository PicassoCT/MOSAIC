local weaponName = "orbitalrailgun"
local weaponDef = {
    name = "Rail Gun",
    alphaDecay = 0.12,
    areaOfEffect = 16,
	--aiming
	accuracy = 16,
	predictBoost  = 1.0,
	metalPerShot = 250,
    energyPerShot = 250,
    burst = 2,
    burstrate = 0.4,
    cegTag = [[railGunCeg]],
    craterBoost = 0,
    craterMult = 0,
    damage = {
        default = 250,

    },
    explosionGenerator = [[custom:cRailSparks]],
 
    impactOnly = true,
	avoidFriendly = false,
    avoidNeutral = false,
	avoidGround  = true,
	collideNeutral = false,
	-- noFirebaseCollide  = false,
	collideGround = true,
	noSelfDamage  = true,
	--command
	canAttackGround  = false,
	
    impulseBoost = 0,
    impulseFactor = 0,
    interceptedByShieldType = 0,
    tolerance = 500,
    noExplode = true,

    range = 3048,
    reloadtime = 10,
    rgbColor = [[0.5 1 1]],
    separation = 0.5,
    size = 0.8,
    sizeDecay = -0.1,
    soundStart = "sounds/weapons/sniper/sniperFire.ogg",
    soundHit = "sounds/weapons/sniper/sniperFire.ogg",
    sprayangle = 800,
    stages = 32,
    fireStarter = 35,
    turret = true,

    weaponType = [[Cannon]],
    weaponVelocity = 2400,
}

return lowerkeys({ [weaponName] = weaponDef })