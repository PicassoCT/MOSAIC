local weaponName = "mortar"
local weaponDef = {
    weaponType = [[Cannon]],
    name = "Grenade",
    highTrajectory = 1,
    --
    weapontimer = 25,
    --
    --Physic/flight path
    range = 320,
    reloadtime = 5,
    weaponVelocity = 300,
    startVelocity = 250,
    weaponAcceleration = 200,
    flightTime = 17.5,
    BurnBlow = 0,
    FixedLauncher = false,
    dance = 0,
    wobble = 0,
    trajectoryheight = 25.8,
    accuracy = 1200,
    canAttackGround = true,
    waterWeapon = true,
    predictBoost = 0.5,
    proximityPriority = -0.75,
    tolerance = 2000,
    tracks = false,
    Turnrate = 16000,
    collideFriendly = true,

    --- -APPEARANCE

    model = "rpg7rocket.s3o",
    smokeTrail = true,
    CegTag = "redstripe",

    --- -TARGETING
    turret = true,
    --CylinderTargetting=true,
    avoidFeature = false,
    avoidFriendly = true,

    explosionGenerator=	"custom:330rlexplode",
    --commandfire=true,

    --- -DAMAGE
    damage = {
        default = 1,
    },
    areaOfEffect = 3,
    craterMult = 0,

    --?FIXME***
    lineOfSight = false,


}

return lowerkeys({ [weaponName] = weaponDef })