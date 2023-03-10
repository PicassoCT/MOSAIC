---http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "slowsniperrifle"
local weaponDef = {
	name = "barret-s64",

	weaponType = [[MissileLauncher]],

	
	model="sniperProj.s3o",
	soundStart = "sounds/weapons/sniper/sniperFire.ogg",
	soundHit= "sounds/weapons/sniper/sniperHit.wav",
	noSelfDamage = true,
	areaOfEffect = 1,
	--physics
	startVelocity  = 2400,
	weaponAcceleration = 100,
	tracks = false,
	weaponVelocity = 2450,
	reloadtime = 3*60,
	range = 950,
	sprayAngle = 1,
	tolerance = 50,
	lineOfSight = true,	 
	turret = true,
	craterMult = 50,	 
	PredictBoost			 =0.6,
	soundtrigger=1,
	
	--appearance
	rgbColor = [[0.5 0.5 0.5]],		 	 
	size = 12,

	avoidFriendly = true,
	

	----------------------------------------------------------------
	ImpulseBoost=2.8,
	impulseFactor = 10,
	areaOfEffect = 1,
	damage = {
		default = 580,
		HeavyArmor =480,
	},	 
	
	smokeTrail = false,
    CegTag = "shelltunnel",
}
return lowerkeys({[weaponName] = weaponDef})