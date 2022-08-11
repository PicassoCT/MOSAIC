--- http:--springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "raidarrest"
local weaponDef = {
    name = "Raid Safehouses",
	weaponType = [[MissileLauncher]],
	model = "RaidDroneProjectile.dae",

    Accuracy = 100,

    --Physic/flight path
    range                     = 175,
      burst                   = 5,
      burstrate               = 0.1,
    reloadtime                = 120,
    flightTime                = 6,
    startVelocity             = 10,
    weaponAcceleration        = 10,

    BurnBlow = 0,
    projectiles             = 1,
    FixedLauncher = false,
    trajectoryHeight        = 2,
    Turnrate                = 2000,

    turret                  = true,
    weaponVelocity          = 420,
    dance                   = 35,
    wobble                  = 1500,
    tolerance               = 512,
    trajectoryHeight        = 1.0,
    tracks = true,

    commandFire = true,
    canAttackGround = false,

    --collision
    collideFriendly = false,
     
    --- -APPEARANCE
    smokeTrail = false,
  
    --- -TARGETING
    turret = true,
    cylinderTargeting = 55.0,
    avoidFeature = false,
    avoidFriendly = false,
    noSelfDamage            = true,
    --- -DAMAGE
    damage = {
        default = 1
    },
    areaOfEffect = 1,
    craterMult = 0,

    lineOfSight = true,

    soundStart = "plane/drone2.ogg", 
    
}

return lowerkeys({ [weaponName] = weaponDef })