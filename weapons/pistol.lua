--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "pistol" -- stun pistol
local weaponDef = {
    name = "Glock S19 - Pistol",
    weaponType = [[Cannon]],
    --damage
    damage = {
        default = 100,
        HeavyArmor = 1,
    },
    areaOfEffect = 8,
    explosionGenerator = "custom:gunimpact",
    cegTag = "gunprojectile",
    texture1 = "gunshot",
    avoidFriendly = false,
    --physics
    weaponVelocity = 850,
    noSelfDamage = true,
    reloadtime = 3,
    range = 200,
    sprayAngle = 300,
    tolerance = 8000,
    lineOfSight = true,
    turret = true,
    craterMult = 0,
    burst = 3,
    burstrate = 0.5,    
    soundtrigger = 1,
    SweepFire = false,
    --apperance
    rgbColor = [[0.95 0.5  0.2]],
    size = 1.2,
    stages = 20,
    separation = 0.2,
}
return lowerkeys({ [weaponName] = weaponDef })