--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "godrod" --this is the actually maschinegune of the inferno trooper
local weaponDef = {
    name = "Mjoelnir Project",
    weaponType = [[MissileLauncher]],
	--aiming behaviour
		turret = true,
		tracks = true,
		noSelfDamage = true,
		avoidFeature            = false,
		avoidGround = false,
		range = 3000,
		trajectoryHeight = 0 ,
		flightTime = 14.5 ,	
		fixedLauncher  			= true,
		canAttackGround = true,
		
		--projectile physics
		turnRate = 190000,
		weaponVelocity = 9000,
		startVelocity  = 1,
		weaponAcceleration = 900,
		impulseBoost            = 0,
		impulseFactor = 0.4,
	   areaOfEffect = 512,
	   
    damage = {
        default = 3500
    },
	
	reloadtime = 3, -- seconds
	smokeTrail = true,
	model = "GodRod.dae",
	explosionScar = true, 
    explosionGenerator = "custom:missile_explosion",
    cegTag = "gunprojectile",
    texture1 = "gunshot",
	fireStarter  = 100.0,
	cameraShake =1.0
	
    }
  
return lowerkeys({ [weaponName] = weaponDef })