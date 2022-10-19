local weaponName = "teargasgrenade"
local weaponDef = {
    weaponType = [[Cannon]],
    name = "Grenade",
    highTrajectory = 0,
    --
    weapontimer = 25,

    --Physic/flight path
    range = 320,
    reloadtime = 60*2,
    weaponVelocity = 300,
    startVelocity = 250,
    weaponAcceleration = 200,
    flightTime = 17.5,
    BurnBlow = 0,
    FixedLauncher = false,
    dance = 0,
    wobble = 0,
    trajectoryheight = 25.8,
    accuracy = 4000,
    canAttackGround = true,
    waterWeapon = true,
    predictBoost = 0.5,
    proximityPriority = -0.75,
    tolerance = 2000,
    tracks = false,
    Turnrate = 16000,
    collideFriendly = false,
    collideNeutral = true,


    --- -APPEARANCE
    model = "tearGasCannister.s3o",
    smokeTrail = true,
    CegTag = "greystripe",
    groundbounce = true,
    WaterBounce = true,
    BounceRebound = 0.251,
    bounceslip = 0.256,
    NumBounce = 3,

    --- -TARGETING
    turret = true,
    --CylinderTargetting=true,
    avoidFeature = false,
    avoidFriendly = true,

    explosionGenerator=	"custom:teargasexplode",
    --commandfire=true,

    --- -DAMAGE
    damage = {
        default = 1,
    },
    areaOfEffect = 1,
    craterMult = 0,

    --?FIXME***
    lineOfSight = false,


}

return lowerkeys({ [weaponName] = weaponDef })