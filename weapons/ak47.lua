--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "ak47" --ak47 weapon
local weaponDef = {
    name = "Antonov Kalshnikow Model 47",
    weaponType = [[Cannon]],
    --damage
    damage = {
        default = 10,
        HeavyArmor = 1,
    },
    areaOfEffect = 8,
    explosionGenerator = "custom:gunimpact",
    cegTag = "gunprojectile",
    texture1 = "gunshot",

    --physics
    weaponVelocity = 850,
    reloadtime = 3,
    range = 250,
    sprayAngle = 300,
    tolerance = 8000,
    lineOfSight = true,
    turret = true,
    craterMult = 0,
    burst = 20,
    burstrate = 0.15,
     SweepFire = false,
    --apperance
    rgbColor = [[0.95 0.5  0.2]],
    size = 1.2,
    stages = 20,
    separation = 0.2,
}
return lowerkeys({ [weaponName] = weaponDef })