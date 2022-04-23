--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "godrod" --godrod projectile
local weaponDef = {
    name = "Mjoelnir Impactor",
    weaponType = [[MissileLauncher]],
    cylinderTargeting = 1.0,

	--damage
	damage = {
	default = 4200,
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
	avoidGround = false,

	--flight behaviour
	startVelocity  = 0,
	
	flightTime = 25.5 ,	
	weaponVelocity = 4000,
	weaponAcceleration = 10,

	--impact behaviour
	impulseBoost            = 0,
	impulseFactor = 0.4,
   	areaOfEffect = 768,  
	fireStarter  = 100.0,

	--visuals
	alwaysVisible = true,
	smokeTrail = false,
	model = "GodRod.s3o",
	explosionScar = true, 
 	cegTag = "impactor",
 	noFriendlyCollide = true,
	cameraShake =1.0,
    explosionGenerator = "custom:missile_explosion",
    --soundStart = "weapons/godrod/impactor.ogg"
}
  
return lowerkeys({ [weaponName] = weaponDef })
