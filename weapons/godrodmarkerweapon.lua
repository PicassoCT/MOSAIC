--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "godrodmarkerweapon"
local weaponDef = {
    name = "necessary cause springs aiming is a lovecraftian horror",
    weaponType = [[Melee]],
    --damage
    damage = {
        default = 1,
        HeavyArmor = 0,
    },
    avoidFriendly = false,



    areaOfEffect = 1,
    --physics

    reloadtime = 30,
    range = 1250,
    --commandFire = true,

    sprayAngle = 1,
    tolerance = 1,
    lineOfSight = false,  
    turret = true,
    craterMult = 0,     
    PredictBoost             =0.6,
   
    canattackground= true,  


    --appearance
    rgbColor = [[0.0 0.0 0.0]],          
    size = 0.00001,
 
    ----------------------------------------------------------------
}

return lowerkeys({ [weaponName] = weaponDef })