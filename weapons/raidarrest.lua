--- http:--springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "raidarrest"
local weaponDef = {
    name = "Arrest Players & Raid Safehouses",
	 weaponType = [[MissileLauncher]],
	model = "RaidDroneProjectile.dae",

    Accuracy = 2000,

    --Physic/flight path
    range = 256,
	burst  = 9,
	burstRate = 1.0,
    reloadtime = 10,
    weaponVelocity = 500,
    startVelocity = 15,
    weaponAcceleration = 250,
    flightTime = 6.5,
    BurnBlow = 0,
    FixedLauncher = false,
    dance = 15,
    wobble = 30,
    tolerance = 16000,
    tracks = true,
    Turnrate = 8000,
    collideFriendly = true,

    --- -APPEARANCE
    smokeTrail = false,
  
    --- -TARGETING
    turret = true,
    cylinderTargeting = 55.0,
    avoidFeature = true,
    avoidFriendly = true,


    commandfire=true,

    --- -DAMAGE
    damage = {
        default = 1
    },
    areaOfEffect = 25,
    craterMult = 0,

    lineOfSight = true,

    soundHit = "weapons/raid/flashbang.ogg",
    
}

return lowerkeys({ [weaponName] = weaponDef })