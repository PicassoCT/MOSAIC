--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "shrapnellmarker"
local weaponDef = {
    name = "aiming",
    weaponType = [[Melee]],
    --damage
    damage = {
        default = 1,
        HeavyArmor = 0,
    },
    avoidFriendly = false,
    --physics
    weaponVelocity = 1,
    reloadtime = 9000,
    range = 256,
    turret = true,
    --  soundStart         = "",
    --  soundtrigger=1,

    --apperance
    rgbColor = [[0 0 0]],
    size = 0.00001,
}

return lowerkeys({ [weaponName] = weaponDef })