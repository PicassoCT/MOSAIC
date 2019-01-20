--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "NOWEAPON"
local weaponDef = {
    name = "NoWeapon",
    weaponType = [[Melee]],
    --damage
    damage = {
        default = 0,
        HeavyArmor = 0,
    },

    --physics
    weaponVelocity = 450,
    reloadtime = 15,
    range = 18,
    sprayAngle = 300,
    tolerance = 8000,
    lineOfSight = true,
    turret = true,
    craterMult = 0,

    --  soundStart         = "",
    --  soundtrigger=1,

    --apperance
    rgbColor = [[0 0 0]],
    size = 0.1,
}

return lowerkeys({ [weaponName] = weaponDef })