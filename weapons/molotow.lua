local weaponName = "molotow" --this is the actually maschinegune of the inferno trooper
local weaponDef = {
	name = "molotow cocktail",
	weaponType = [[Cannon]],

--------------------------------------------------------------
    --Physic/flight path
	range = 150,
    reloadtime = 90,
    weaponVelocity = 320,
    startVelocity = 50,
    weaponAcceleration = 50,
    flightTime = 4,
    cameraShake = 12;
    FixedLauncher = true,
    accuracy = 600,
    tolerance = 150,
    tracks = false,
    Turnrate = 16000,
    collideFriendly = true,
    BurnBlow = false,
    highTrajectory = 1,

    --- -APPEARANCE
 	model = "molotow.s3o",

    explosionGenerator="fireball",
    CegTag="firesparks",

    --- -TARGETING
    turret = true,
    --CylinderTargetting=true,
    avoidFeature = false,
    avoidFriendly = false,
	soundtrigger = 1,
	fireStarter = 100,
    noSelfDamage = true,

 	--damage
	damage = {
		default = 50,
		heavyarmor = 75,
	},
	areaOfEffect = 50,
	craterMult = 1,
	impulseFactor = 3.0,

    --?FIXME***
    lineOfSight = true,

	soundStart = "sounds/weapons/molotow/throw.ogg",
    soundHit = "sounds/weapons/molotow/impact.ogg",

}

return lowerkeys({ [weaponName] = weaponDef })