--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "smartminedrone" -- tracking, slow turning explosive drones
local weaponDef = {
    name = "Mine Drone",
    weaponType = [[MissileLauncher]],
    Accuracy = 1000,

    --Physic/flight path
    range = 800,
    reloadtime = 10,
    weaponVelocity = 200,
    startVelocity = 50,
    weaponAcceleration = 15,
    trajectoryHeight = 1,
    flightTime = 15,
    burst = 5,
    burstrate               = 0.1,
    BurnBlow = true, -- expire after flightTime even though terrain collisions are disabled
    FixedLauncher = false,
    dance = 100,
    wobble                  = 3500,
    tolerance               = 512,
    Turnrate = 5000,
    edgeEffectiveness       = 0.5,
    tracks = true,

    --- -APPEARANCE
    model = "DroneMineLaunchProj.s3o",
    smokeTrail = false,
    explosionGenerator="custom:missile_explosion",
    --CegTag = "ccitdronetail",

    --- -TARGETING
    turret = true,
    avoidFeature = true,
    avoidGround = true,
    avoidFriendly = true,
    collideFriendly = false,
    collideEnemy  = true,
    collideNeutral  = true,
    collideGround = false,
    customParams = {
        -- S3O vertices fit within 5.17 elmos of the projectile origin.
        drone_ground_clearance = 6,
        -- One native step: 200/30 speed + 15/900 acceleration + 2*100/30 dance.
        drone_terrain_step = 14,
    },

    heightMod = 0.5,

    --commandfire=true,

    --- -DAMAGE
    damage = {
        default = 50,
        heavyarmor = 25,
    },
    areaOfEffect = 100,
    craterMult = 0,

    noSelfDamage = true,

    --sound
    --soundHit="null",
    soundStart = "sounds/plane/drone2.ogg",
    soundHit = "sounds/weapons/drone/Explosion.wav",

	fireStarter  = 50.0,
	cameraShake =1.0
	
    }
  
return lowerkeys({ [weaponName] = weaponDef })
