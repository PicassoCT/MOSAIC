
local weaponName = "heavymachinegun" 
local weaponDef = {
    name = "M27-64",
    weaponType = [[Cannon]],
    --damage
    damage = {
        default = 10,
        HeavyArmor = 5,
    },
    areaOfEffect = 8,
    explosionGenerator =  "custom:Ricochet",
    cegTag = "gunprojectile",
    --texture1 = "gunshot",
    avoidFriendly = false,
    --physics
    weaponVelocity = 850,
    reloadtime = 3,
    range = 450,
    sprayAngle = 300,
    tolerance = 8000,
    lineOfSight = true,
    SweepFire = true,
    turret = true, 
    canAttackGround = true,
   
	
    craterMult = 0,
    burst = 15,
    burstrate = 0.1,
    soundtrigger = 1,
    --apperance
    rgbColor = [[0.95 0.5  0.2]],
    size = 2.2,
    stages = 10,
    separation = 0.2,
    soundStart = "sounds/weapons/machinegun/salvo2.ogg",
 
}

return lowerkeys({ [weaponName] = weaponDef })