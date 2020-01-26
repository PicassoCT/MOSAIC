local weaponName = "molotow" --this is the actually maschinegune of the inferno trooper
local weaponDef = {
	name = "molotow cocktail",
	weaponType = [[Cannon]],
	--damage
	damage = {
		default = 50,
		heavyarmor = 75,
	},
	areaOfEffect = 25,
	craterMult = 1,
	
	model = "molotow.dae",
	--physics
	
	weaponVelocity = 50,
	reloadtime = 50.42,
	range = 200,
	sprayAngle = 6000,
	accuracy = 0.2,
	tolerance = 5000,
	lineOfSight = false,
	turret = true,
	groundbounce = false,
	WaterBounce = false,
	
	flighttime = 20,
	collideFriendly = true,

	soundtrigger = 1,
	--apperance
	
	size = 1,
	highTrajectory = 1,
	craterBoost = 3,
	cylinderTargeting = 17.0,
	edgeEffectiveness = 0.2,
	fireStarter = 100,
	impulseFactor = 3.1,
	
	myGravity = 1,
	targetBorder = 0,
}

return lowerkeys({ [weaponName] = weaponDef })