--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "tankcannon"
local weaponDef = {
    name = "cannon",
    weaponType = [[Cannon]],
    --damage
    damage = {
        default = 1500,
        HeavyArmor = 1000,
    },
    areaOfEffect = 50,
    --physics
    weaponVelocity = 2900,
    reloadtime = 5,
    range = 650,
    sprayAngle = 300,
    tolerance = 8000,
    lineOfSight = true,
    turret = true,
    craterMult = 1,
    explosionGenerator = "custom:tankbigbulletimpact",
    soundHit = "sounds/tank/impact.ogg",
    soundStart = "sounds/tank/Fire.ogg",
	targetable=1,
    --apperance
    rgbColor = [[0.86 0.49 0.49]],
    size = 4,
}

return lowerkeys({ [weaponName] = weaponDef })