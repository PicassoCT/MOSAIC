--- http:--springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "raidarrest"
local weaponDef = {
    name = "Arrest Players & Raid Safehouses",
	 weaponType = [[MissileLauncher]],
	model = "RaidDroneProjectile.dae",
	weaponVelocity = 150,
	startVelocity  = 10,

	--aiming behaviour
	turret = true,
	tracks = true,
	noSelfDamage = true,
	avoidFeature            = false,
	avoidGround = true,
    areaOfEffect = 8,
    craterBoost = 0,
    craterMult = 0,
    damage = {
        default = 1,
        HeavyArmor = 1,
    },
	burst = 15,
	burstrate = 1,
    impactOnly = true,
	 impulseBoost = 3,
    impulseFactor = 6,
    intensity = 12,
    interceptedByShieldType = 1,
    lineOfSight = true,
    paralyzer = true,
    paralyzeTime = 1,
    range = 80,
    reloadtime = 25,
    rgbColor = [[0.0 0.5 0.8]],
    soundHit = "weapons/raid/flashbang.ogg",
    -- explosionGenerator = "custom:psiimpact",
    targetMoveError = 0.3,
    weaponVelocity = 400,
}

return lowerkeys({ [weaponName] = weaponDef })