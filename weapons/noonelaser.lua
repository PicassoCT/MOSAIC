local weaponName = "noonelaser"
local weaponDef = {
    name = "NO^2N-Laser",
    weaponType = [[Beamlaser]],
    beamweapon = 1,

    accuracy = 16,
    laserflaresize = 3, --0.3
    beamTtl = 0.05, --0.01
    movingaccuracy = 2500,
    predictBoost = 1.5,
    areaOfEffect = 1,

    soundtrigger = false,
    collideFriendly = false,
    beamtime = 0.02, --0.01

    FireSubmersed = 0,
    largeBeamLaser = true,
    lineOfSight = false,

    targetMoveError = 0.5,
    noSelfDamage = false,
	impactOnly = true,
	commandFire  = true,
	collideFirebase = false,
	avoidFriendly = false, 

    range = 8192,
	cylinderTargeting = 1.0,	
	
    reloadtime = 0.02,
    renderType = 0,
    turret = true,


    coreThickness = 1.3,
    thickness = 9.5,
    rgbColor = [[0.1 0.8 0.8]],
    rgbColor2 = [[0.1 0.6 0.9]],
    -- HardStop = 1, --test It
    Intensity = 1.4, --test It
    scrollspeed = 0.3,

    tolerance = 1000,
    damage = {
        default = 10,
        HeavyArmor = 20,
    },
}
return lowerkeys({ [weaponName] = weaponDef })