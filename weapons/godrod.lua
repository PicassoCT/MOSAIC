--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "godrod" --this is the actually maschinegune of the inferno trooper
local weaponDef = {
    name = "Mjoelnir Impactor",
    weaponType = [[MissileLauncher]],
    cylinderTargeting = 1.0,

	--damage
	damage = {
	default = 3500
	},
	noSelfDamage = true,
	reloadtime = 30, -- seconds

	--orders behaviour	
	canAttackGround = true,

	--aiming behaviour
	range = 3000,
	turnRate = 999000000,
	turret = true,
	tracks = true,

	avoidFeature = true,
	avoidGround = true,

	--flight behaviour
	startVelocity  = 50,
	
	flightTime = 25.5 ,	
	weaponVelocity = 4000,
	weaponAcceleration = 100,

	--impact behaviour
	impulseBoost            = 0,
	impulseFactor = 0.4,
   	areaOfEffect = 512,  
	fireStarter  = 100.0,

	--visuals
	alwaysVisible = true,
	smokeTrail = false,
	model = "GodRod.s3o",
	explosionScar = true, 
 	cegTag = "impactor",
	cameraShake =1.0,
    explosionGenerator = "custom:missile_explosion",
    soundStart = "weapons/godrod/impactor.ogg"
}
  
return lowerkeys({ [weaponName] = weaponDef })
