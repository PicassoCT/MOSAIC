--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "godrod" --this is the actually maschinegune of the inferno trooper
local weaponDef = {
    name = "Mjoelnir Impactor",
    weaponType = [[MissileLauncher]],
	--damage
	damage = {
	default = 3500
	},
	noSelfDamage = true,
	reloadtime = 10, -- seconds

	--orders behaviour
	--commandFire  = true,	
	canAttackGround = true,

	--aiming behaviour
	range = 3000,
	turnRate = 9990000,
	turret = true,
	tracks = false,
	--commandFire = true,
	avoidFeature = true,
	avoidGround = true,

	--flight behaviour
	startVelocity  = 100,
	
	flightTime = 25.5 ,	
	weaponVelocity = 2000,
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
    explosionGenerator = "custom:missile_explosion"
}
  
return lowerkeys({ [weaponName] = weaponDef })
