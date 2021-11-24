--- http://springrts.com/wiki/Weapon_Variables#Cannon_.28Plasma.29_Visuals
local weaponName = "cruise_missiles" --cruise missile base type
local weaponDef = {
    name = "Cruise Missile",
	weaponType = [[MissileLauncher]],
	description = "Long Range Long Reload Missile",

    damage = {
        default = 1500
    },
	
	range = 16635,
	impulseBoost  = 0,
	impulseFactor = 0.4,
	reloadtime = 5*60,
    areaOfEffect = 256,
    interceptSolo= false,
    targetable = 1,

	noSelfDamage = true,
	trajectoryHeight = 2.0 ,
	
	avoidFeature = false,
	avoidGround = true,
	commandFire = true,
	canAttackGround = true,
		
	smokeTrail = true,
	startVelocity  = 5,
	weaponAcceleration = 15,
	-- BurnBlow = 0,
	Turnrate = 1066*30, --degrees per second
	weaponVelocity = 1200,
	tracks = true,
	AlwaysVisible = true,
	flightTime = 2500 ,

    explosionGenerator = "custom:bigbulletimpact",
 	cegTag = "impactor",

	turret = true,
	explosionScar = true, 
	soundStart = "weapons/cruisemissile/launch.ogg",
	soundHit = "weapons/cruisemissile/bombblast.ogg",
    explosionGenerator = "custom:missile_explosion",
	fireStarter  = 50.0,
	cameraShake =1.0
    }	
	
local CruiseMissiles ={}
local Missile = weaponDef
CruiseMissiles["cm_airstrike"] = Missile

local Missile = weaponDef
Missile.model = "cm_antiarmor_proj.s3o"
Missile.name = "cruisemissile antiarmour"
CruiseMissiles["cm_antiarmor"] = Missile

local Missile = weaponDef
Missile.model = "cm_turret_ssied_proj.s3o"
Missile.name = "cruisemissile transport"
Missile.name = "transports all transportable units"
CruiseMissiles["cm_transport"] = Missile

return lowerkeys( CruiseMissiles )