
local weaponName = "submachingegun" 
local weaponDef = {
    name = "Boaz Submachingegun",
    weaponType = [[Cannon]],
    --damage
    damage = {
        default = 5,
        HeavyArmor = 1,
    },
    areaOfEffect = 8,
    explosionGenerator = "custom:gunimpact",
    cegTag = "gunprojectile",
    texture1 = "gunshot",
    avoidFriendly= true,

    --physics
    weaponVelocity = 850,
    reloadtime = 7,
    range = 350,
    sprayAngle = 300,
    tolerance = 8000,
    lineOfSight = true,
    turret = true,
	-- noFirebaseCollide  = false,

    craterMult = 0,
    burst = 14,
    burstrate = 0.15,
    soundStart = "weapons/machinegun/salvo.ogg",
    soundtrigger = 1,
    SweepFire = 1,
    --apperance
    rgbColor = [[0.95 0.5  0.2]],
    size = 5.5,
    stages = 2,
    separation = 1
}

return lowerkeys({ [weaponName] = weaponDef })