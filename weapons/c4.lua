--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "c4"
local weaponDef = {
    name = "C4 - Explosives",
    weaponType = [[Melee]],
    --damage
    damage = {
        default = 1,
        HeavyArmor = 0,
    },

    --physics
    weaponVelocity = 450,
    reloadtime =  45,
    range = 18,
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