
local weaponName = "machinegun" 
local weaponDef = {
    name = "M27-64",
    weaponType = [[Cannon]],
    --damage
    damage = {
        default = 5,
        HeavyArmor = 5,
    },
    areaOfEffect = 8,
    explosionGenerator = "custom:gunimpact",
    cegTag = "gunprojectile",
    texture1 = "gunshot",
    avoidFriendly = false,
    --physics
    weaponVelocity = 850,
    reloadtime = 3,
    range = 450,
    sprayAngle = 300,
    tolerance = 8000,
    lineOfSight = true,
    turret = true, 
    canAttackGround = true,
    collideFireBase = false,
	
    craterMult = 0,
    burst = 15,
    burstrate = 0.1,
    soundtrigger = 1,
    SweepFire = 1,
    --apperance
    rgbColor = [[0.95 0.5  0.2]],
    size = 1.2,
    stages = 20,
    separation = 0.2

}

return lowerkeys({ [weaponName] = weaponDef })