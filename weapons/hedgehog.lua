local weaponName = "hedgehog"
local weaponDef = {
    name = "Anti-Personal-Mine",  
    weaponType = [[MissileLauncher]],
    --damage
    damage = {
    default = 350
    },
    noSelfDamage = false,
    reloadtime = 9999, -- seconds

    --orders behaviour
    --commandFire  = true,  
    canAttackGround = true,

    --aiming behaviour
    range = 150,
    turnRate = 1,
    turret = true,
    tracks = false,

    avoidFeature = true,
    avoidGround = true,
    
    --flight behaviour
    startVelocity  = 500,
    trajectoryHeight = 0.01 ,
    flightTime = 4.5 ,
    weaponVelocity = 1050,
    weaponAcceleration = 100,

    --impact behaviour
    impulseBoost            =2,
    impulseFactor = 0.4,
    areaOfEffect = 128,
    fireStarter  = 90.0,

    --visuals
    smokeTrail = true,
    
    model = "hedgehog.dae",
    explosionScar = true, 
    cameraShake = 0.5,
    explosionGenerator = "custom:missile_explosion",
    soundStart = "sounds/weapons/gun/shotgun.wav",
    soundHit = "sounds/weapons/rocket/impact.wav",


}

return lowerkeys({ [weaponName] = weaponDef })