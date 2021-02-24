--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "smartminedrone" --this is the actually maschinegune of the inferno trooper
local weaponDef = {
  name = "Mine Drone",
    weaponType = [[MissileLauncher]],
    Accuracy = 1000,

    --Physic/flight path
    range = 1200,
    reloadtime = 3,
    weaponVelocity = 250,
    startVelocity = 50,
    weaponAcceleration = 50,
    flightTime = 18.5,
    BurnBlow = 0,
    FixedLauncher = false,
    dance = 30,
    wobble = 1,
    turnrate = 12200,
    tolerance = 16000,
    tracks = true,
    Turnrate = 32000,
    avoidGround = false,
    avoidFriendly = false,
    --- -APPEARANCE
    model = "DroneMineLaunchProj.s3o",
    smokeTrail = false,
    --explosionGenerator="custom:redsmoke",
    --CegTag = "ccitdronetail",

    --- -TARGETING
    turret = true,
    CylinderTargeting = 0.0,
    avoidFeature = true,
    avoidFriendly = true,
    collideFriendly = false,
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
