--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "stunpistol" --this is the actually maschinegune of the inferno trooper
local weaponDef = {
    name = "Stundart - Pistol",
    weaponType = [[Cannon]],
    --damage
    damage = {
        default = 1,
        HeavyArmor = 1,
    },
    areaOfEffect = 0,
    explosionGenerator = "custom:gunimpact",
    cegTag = "gunprojectile",
    texture1 = "gunshot",

    --physics
    weaponVelocity = 850,
    reloadtime = 5,
    range = 175,
	paralyzer = true,
    paralyzeTime = 5,
    sprayAngle = 100,
    tolerance = 8000,
    lineOfSight = true,
    turret = true,
    craterMult = 0,
    burst = 1,
    burstrate = 0.5,
    soundStart = "sounds/weapons/pistol/pistolshot2.wav",
    soundtrigger = 1,
    SweepFire = false,
    --apperance
    rgbColor = [[0.95 0.5  0.2]],
    size = 0.2,
    stages = 2,
    separation = 0.2,
}
return lowerkeys({ [weaponName] = weaponDef })