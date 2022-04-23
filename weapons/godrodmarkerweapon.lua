--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "godrodmarkerweapon"
local weaponDef = {
    name = "necessary cause springs aiming is a lovecraftian horror",
    weaponType = [[MissileLauncher]],
    --damage
    damage = {
        default = 1,
        HeavyArmor = 0,
    },
    avoidFriendly = false,
    startVelocity  = 9999,
    weaponVelocity = 9999,
    areaOfEffect = 1,
    --physics

    reloadtime = 30,
    range = 2500,


    sprayAngle = 1,
    tolerance = 50,
    lineOfSight = false,  
    turret = true,
    craterMult = 0,     
    PredictBoost             =0.6,
   
    canattackground= true,  


    --appearance
    rgbColor = [[0.0 0.0 0.0]],          
    size = 0.00001,
 
    noSelfDamage = true,
    areaOfEffect = 1,
    --physics

    tracks = false,
    craterMult = 50,     
    PredictBoost             =0.6,

    

    ----------------------------------------------------------------
}

return lowerkeys({ [weaponName] = weaponDef })