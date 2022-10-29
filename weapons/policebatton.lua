--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "policebatton"
local weaponDef = {
    name = "CloseCombat",
    weaponType = [[MELEE]], --Rifle
    --damage
    damage = {
        default = 10,
        HeavyArmor = 0,
    },

    --physics
    weaponVelocity = 9999,
    reloadtime = 90,
    range = 50,
    burst = 3,
    burstrate = 2.5,
    turret = true,

    --apperance
    rgbColor = [[0 0 0 0]],
    size = 0.0001,
}

return lowerkeys({ [weaponName] = weaponDef })