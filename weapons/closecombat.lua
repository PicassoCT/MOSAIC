--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "closecombat"
local weaponDef = {
    name = "CloseCombat",
    weaponType = [[Rifle]], --Rifle
    --damage
    damage = {
        default = 2,
        HeavyArmor = 0,
    },

    --physics
    weaponVelocity = 9999,
    reloadtime = 90,
    range = 50,
    turret = true,

    --  soundStart         = "",
    --  soundtrigger=1,

    --apperance
    rgbColor = [[0 0 0 0]],
    size = 0.0001,
}

return lowerkeys({ [weaponName] = weaponDef })