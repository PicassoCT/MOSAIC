
local weaponName = "submachingegun" 
local weaponDef = {
    name = "Automatic",
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

    --physics
    weaponVelocity = 850,
    reloadtime = 7,
    range = 350,
    sprayAngle = 300,
    tolerance = 8000,
    lineOfSight = true,
    turret = true,
	-- noFirebaseCollide  = false,
	avoidFriendly = false,
    craterMult = 0,
    burst = 30,
    burstrate = 0.2,
    soundStart = "weapons/machinegun/salvo.ogg",
    soundtrigger = 1,
    SweepFire = 1,
    --apperance
    rgbColor = [[0.95 0.5  0.2]],
    size = 1.2,
    stages = 20,
    separation = 0.2,
}

return lowerkeys({ [weaponName] = weaponDef })