--- http:--springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "raidarrest"
local weaponDef = {
    name = "Arrest Players & Raid Safehouses",
	weaponType = [[MissileLauncher]],
	model = "RaidDroneProjectile.dae",

    Accuracy = 2000,

    --Physic/flight path
    range = 256,
      burst                   = 20,
      burstrate               = 0.1,
    reloadtime = 120,
    flightTime              = 8,
    startVelocity = 15,
    weaponAcceleration = 10,

    BurnBlow = 0,
    projectiles             = 2,
    FixedLauncher = false,
    trajectoryHeight        = 1,
    turnRate                = 2500,
    dance      = 20,
    turret                  = true,
    weaponVelocity          = 250,
    wobble                  = 7000,
    tolerance               = 512,
    tracks = false,
    Turnrate = 8000,

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
    areaOfEffect = 35,
    craterMult = 0,

    lineOfSight = true,

    soundFire = "plane/drone2.ogg",
    soundHit = "weapons/raid/flashbang.ogg",
    
}

return lowerkeys({ [weaponName] = weaponDef })