
local weaponName = "machinegun" 
local weaponDef = {
    name = "M27-64",
    weaponType = [[Cannon]],
    --damage
    damage = {
        default = 10,
        HeavyArmor = 1,
    },
    areaOfEffect = 8,
    explosionGenerator = "custom:gunimpact",
    cegTag = "gunprojectile",
    texture1 = "gunshot",

    --physics
    weaponVelocity = 850,
    reloadtime = 15,
    range = 350,
    sprayAngle = 300,
    tolerance = 8000,
    lineOfSight = true,
    turret = true,
	-- noFirebaseCollide  = false,
	
    craterMult = 0,
    burst = 15,
    burstrate = 0.1,
    soundStart = "weapons/machinegun/salvo2.ogg",
    soundtrigger = 1,
    SweepFire = 1,
    interceptor=1,
    --apperance
    rgbColor = [[0.95 0.5  0.2]],
    size = 1.2,
    stages = 20,
    separation = 0.2,
}

return lowerkeys({ [weaponName] = weaponDef })