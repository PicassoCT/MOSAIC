local weaponName = "noonelaser"
local weaponDef = {
    name = "NO^2N-Laser",
    weaponType = [[BeamLaser]],
    beamweapon = 1,
    -- beamlaser=1,
    -- WeaponAcceleration=0,
    accuracy = 16,
    laserflaresize = 3, --0.3
    beamTtl = 0.05, --0.01
    movingaccuracy = 2500,
    predictBoost = 1.5,
    areaOfEffect = 1,
    avoidFriendly = false,
    soundtrigger = false,
    collideFriendly = false,
    beamtime = 0.02, --0.01

    FireSubmersed = 0,
    --impulseFactor = 0.025,
    largeBeamLaser = true,
    lineOfSight = false,
	cylinderTargeting = true,
    targetMoveError = 0.5,
    noSelfDamage = true,
	 impactOnly = true,
    range = 2048,
    reloadtime = 0.02,
    renderType = 0,
    turret = true,
    alwaysVisible= true,
    soundStart = "sounds/weapons/laser/laser.ogg",

    coreThickness = 1.3,
    thickness = 9.5,
    rgbColor = [[0.1 0.8 0.8]],
    rgbColor2 = [[0.1 0.6 0.9]],
    -- HardStop = 1, --test It
    Intensity = 1.4, --test It
    scrollspeed = 0.3,

    -- explosionGenerator = "custom:smallblueburn",
    tolerance = 1000,
    damage = {
        default = 5,
        HeavyArmor = 10,
    },
}
return lowerkeys({ [weaponName] = weaponDef })