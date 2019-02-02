--- http:--springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "raidarrest"
local weaponDef = {
    name = "Arrest Players & Raid Safehouses",
    weaponType = [[LightningCannon]],
    areaOfEffect = 8,
    craterBoost = 0,
    craterMult = 0,
    damage = {
        default = 1,
        HeavyArmor = 1,
    },
	beamTTL = 20,
    duration = 20,
    fireStarter = 0,
    impactOnly = true,
	 impulseBoost = 3,
    impulseFactor = 6,
    intensity = 12,
    interceptedByShieldType = 1,
    lineOfSight = true,
    paralyzer = true,
    paralyzeTime = 1,
    range = 75,
    reloadtime = 25,
    rgbColor = [[0.0 0.5 0.8]],
    soundHit = "weapons/raid/flashbang.wav",
    -- explosionGenerator = "custom:psiimpact",
    FireStarter = 75,
    targetMoveError = 0.3,

    texture1 = [[FreemanZone]],
    thickness = 10,
    turret = true,
    weaponVelocity = 400,
}

return lowerkeys({ [weaponName] = weaponDef })