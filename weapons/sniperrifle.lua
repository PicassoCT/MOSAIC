---http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "sniperrifle"
local weaponDef = {
	name = "barret-s64",
	description = "high calibre, long range rifle",
	weaponType = [[Cannon]],

	
	model="cSniperBullet.s3o",
	smokeTrail=true,
	 soundFire = "weapons/sniper/sniperFire.wav",
	
	areaOfEffect = 1,
	--physics
	weaponVelocity = 1450,
	reloadtime = 8,
	range = 964,
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
	
	
	
	---------------------------------------------------------------
	
	----------------------------------------------------------------
	ImpulseBoost=2.8,
	impulseFactor = 10,
	damage = {
		default = 580,
		HeavyArmor =480,
	},	 
	
}
return lowerkeys({[weaponName] = weaponDef})