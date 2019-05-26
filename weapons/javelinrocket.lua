--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "javelinrocket" --this is the actually maschinegune of the inferno trooper
local weaponDef = {
    name = "Indirect Self Aiming Rocket with Shaped Charge",
    weaponType = [[MISSILE]],
    --damage
    damage = {
        default = 1500,
        HeavyArmor = 1,
    },
    areaOfEffect = 8,
	trajectoryHeight = 450 ,
	smokeTrail = true,
	startVelocity  = 0.1,
	weaponAcceleration = 0.0125,
	weaponVelocity = 140,
	tracks = true,
	turnRate = 12,
	flightTime = 14.5 ,
	fixedLauncher = true,
	model = "air_copter_antiarmor.dae",
	explosionScar = true, 
    explosionGenerator = "custom:gunimpact",
    cegTag = "gunprojectile",
    texture1 = "gunshot",

    --physics
   
}
return lowerkeys({ [weaponName] = weaponDef })