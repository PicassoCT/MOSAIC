local weaponName = "antiairkamikaze"
local weaponDef = {
    name = "Standardized Smart Improvised Explosive Device",
      --weaponType=[[Cannon]],
    rendertype = 4,
	proximityPriority  = 2.0,
    reloadtime = 19,
    CameraShake = 6,
    accuracy = 10,
    explosionGenerator = "custom:smallbulletimpact",
    avoidFeature = false,
    avoidFriendly = true,
    avoidNeutral = true,
	collideFriendly  = false,

    ImpulseBoost = 1.2,
    ImpulseFactor = 3,
    damage = {
        default = 100,
    },
    areaOfEffect = 10,
    craterMult = 0,
    lineOfSight = true,
    soundHit = "weapons/ssied/explode.ogg",
    --
    ballistic = true,
    turret = true,
    range = 50,
    weaponvelocity = 9999,
}

return lowerkeys({ [weaponName] = weaponDef })