--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "stunpistol"
local weaponDef = {
    name = "Interrogation stun dart",
    weaponType = [[Cannon]],
    --damage
    damage = {
        default = 1,
        HeavyArmor = 1,
    },
    areaOfEffect = 0,
    explosionGenerator = "custom:interrogation_stun",
    -- A small dart, without a firearm tracer or explosive impact.
    texture1 = "gunshot",
    impactOnly =true,
    --physics
    weaponVelocity = 850,
    reloadtime = 5,
    range = 175,
	paralyzer = true,
    paralyzeTime = 5,
    sprayAngle = 100,
    tolerance = 8000,
    lineOfSight = true,
    turret = true,
    craterMult = 0,
    burst = 1,
    burstrate = 0.5,

    soundStart = "sounds/air/copter/electricbulletsImpact.ogg",
    soundStartVolume = 0.25,
    soundHit = "sounds/air/copter/electricbulletsImpact.ogg",
    soundHitVolume = 0.8,
    soundtrigger = true,
    SweepFire = false,
    --apperance
    rgbColor = [[0.45 0.8 1.0]],
    size = 0.2,
    stages = 2,
    separation = 0.2,
}
return lowerkeys({ [weaponName] = weaponDef })