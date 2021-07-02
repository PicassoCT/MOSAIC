--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "smartminedrone" --this is the actually maschinegune of the inferno trooper
local weaponDef = {
    name = "Mine Drone",
    weaponType = [[MissileLauncher]],
    Accuracy = 1000,

    --Physic/flight path
    range = 800,
    reloadtime = 15,
    weaponVelocity = 350,
    startVelocity = 50,
    weaponAcceleration = 15,
    flightTime = 10,
    burst = 3,
    BurnBlow = 1,
    FixedLauncher = false,
    dance = 30,
    wobble                  = 3500,
    tolerance               = 512,
    Turnrate = 32000,

    tracks = true,
    avoidGround = false,
    avoidFriendly = false,
    --- -APPEARANCE
    model = "DroneMineLaunchProj.s3o",
    smokeTrail = false,
    explosionGenerator="custom:missile_explosion",
    --CegTag = "ccitdronetail",

    --- -TARGETING
    turret = true,
    CylinderTargeting = 0.0,
    avoidFeature = true,
    avoidFriendly = true,
    collideFriendly = true,
    collideEnemy  = true,
    collideNeutral  = true,
    collideGround = true,

    heightMod = 0.5,

    --commandfire=true,

    --- -DAMAGE
    damage = {
        default = 450,
        heavyarmor = 350,
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
