local weaponName = "ssied"
local weaponDef = {
    name = "Standardized Smart Improvised Explosive Device",
      --weaponType=[[Cannon]],
    rendertype = 4,

    reloadtime = 19,
    CameraShake = 6,
    accuracy = 10,
    explosionGenerator = "custom:bigbulletimpact",
    avoidFeature = false,
    avoidFriendly = false,
    ImpulseBoost = 1.2,
    ImpulseFactor = 3,
    damage = {
        default = 1600,
    },
    areaOfEffect = 250,
    craterMult = 1,
    lineOfSight = true,
    soundHit = "weapons/ssied/explode.ogg",
    --
    ballistic = true,
    turret = true,
    range = 70,
    weaponvelocity = 250,
}

return lowerkeys({ [weaponName] = weaponDef })