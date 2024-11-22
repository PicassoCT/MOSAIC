--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "cgunshipmg" --this is the actually maschinegune of the inferno trooper
local weaponDef = {
    name = "cgunshipmg",
    weaponType = [[Cannon]],
    --damage
    damage = {
        default = 25,
        HeavyArmor = 10,
    },
    areaOfEffect = 8,
    explosionGenerator = "custom:GunShipMGImpact",
    cegTag = "AR2Projectile",
    texture1 = "empty",

    --physics
    weaponVelocity = 1250,
    reloadtime = 15.35,
    range = 650,
    sprayAngle = 400,
    tolerance = 2000,
    lineOfSight = true,
    turret = false,
    craterMult = 0,
    burst = 128,
    burstrate = 0.2,
    soundStart = "sounds/cHunterChopper/firelooper.wav",
    soundHit = "sounds/cGunShip/electricbulletsImpact.ogg",
    soundtrigger = 1,
    SweepFire = 1,
    --apperance
    rgbColor = [[0.5 0.95 0.85]],
    size = 1.2,
    stages = 20,
    separation = 0.6,
}

return lowerkeys({ [weaponName] = weaponDef })