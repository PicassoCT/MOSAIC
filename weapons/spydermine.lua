local weaponName = "spydermine"
local weaponDef = {
    name = "Spydermine",
    weaponType=[[Cannon]],
    rendertype = 4,
	canAttackGround  = true	,
	proximityPriority  = 2.0,
    reloadtime = 19,
    CameraShake = 6,
    accuracy = 10,
    explosionGenerator = "custom:tess",
    avoidFeature = false,
    avoidFriendly = false,
	collideFriendly  = false,

    ImpulseBoost = 1.2,
    ImpulseFactor = 3,
    damage = {
        default = 600   ,
    },
    noSelfDamage = true,
    areaOfEffect = 250,
    craterMult = 1,
    lineOfSight = true,
    soundHit = "weapons/ssied/explode.ogg",

    ballistic = true,
    turret = true,
    range = 70,
    weaponvelocity = 250,
}

return lowerkeys({ [weaponName] = weaponDef })