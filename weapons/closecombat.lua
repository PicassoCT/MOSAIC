--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "closecombat"
local weaponDef = {
    name = "CloseCombat",
    weaponType = [[Melee]],
    --damage
    damage = {
        default = 0,
        HeavyArmor = 0,
    },

    --physics
    weaponVelocity = 450,
    reloadtime = 1,
    range = 15,
    sprayAngle = 300,
    tolerance = 8000,
    turret = true,
    craterMult = 0,

    --  soundStart         = "",
    --  soundtrigger=1,

    --apperance
    rgbColor = [[0 0 0]],
    size = 0.1,
}

return lowerkeys({ [weaponName] = weaponDef })