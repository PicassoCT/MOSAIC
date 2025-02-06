
local ground_turret_cruisemissilepod =  Walker:New{
	name = "Cruise Missile Pod",
	-- This is a anti-tank drone body, deployed after flight
	--capable to one-time launch a projectile 
	-- It has 4 SubScout Air-Drones which seperate at deploy Time and relay target information
	description = "Fires a cruise missile at target",
	
		objectName = "ground_turret_cruisemissilepod.dae",
	script = "ground_turret_cruisemissilepod_script.lua",
	buildPic = "ground_turret_cm.png",
	iconType = "ground_turret_cm",
	--floater = true,
	--cost
	buildCostEnergy = 500,
	buildCostMetal = 1250,
	buildTime = 5,
	--Health
	maxDamage = 50,
	idleAutoHeal = 0,
	--Movement
	maxVelocity		= 0.125 , --14.3, --86kph/20
	--maxReverseVelocity= 2.15,
	acceleration = 0.15,
	brakeRate = 0.1,
	turninplace		= true,
	 fireState=1,
	upright  = true,
	FootprintX = 1,
	FootprintZ = 1,
	maxSlope = 50,
	mass = 3000,
	MaxWaterDepth = 60,

	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "5 25 5",
	
	nanocolor=[[0.20 0.411 0.611]],
	sightDistance = 50,
	activateWhenBuilt   	= true,
	cantBeTransported = false,

	canMove =true,
	CanAttack = true,
	CanGuard = true,

	Canstop  = true,
	onOffable = false,
	LeaveTracks = false, 
	canCloak = true,
	decloakOnFire = true,

	Category = [[ARMOR GROUND BUILDING]],

	  customParams = {
	  	baseclass = "tank",
	  	normaltex = "unittextures/component_atlas_normal.dds",
	  },

	 sfxtypes = {
		explosiongenerators = {
							"custom:cruisemissiletrail",
							"custom:icbmshine",
							"custom:impactor",
							  },
				},				
	weapons = {
		[1]={name  = "javelinrocket",
			onlyTargetCategory = [[BUILDING GROUND VEHICLE ]],
			},
			
		},	
}

CruiseMissilePods ={}

ground_turret_cruisemissilepod.weapons  = {
											[1] = { name =  "cm_airstrike"	,																							
													onlyTargetCategory = [[BUILDING GROUND VEHICLE]],
											}
										}
CruiseMissilePods["ground_turret_cm_airstrike"] = ground_turret_cruisemissilepod:New()
CruiseMissilePods["ground_turret_cm_airstrike"].name = "MOSAIC HiMars ATTACMs"
CruiseMissilePods["ground_turret_cm_airstrike"].description = " fires a cruise missile at location"



ground_turret_cruisemissilepod.weapons  = {
											[1] = { name =  "cm_airtransport"	,																							
													onlyTargetCategory = [[BUILDING GROUND VEHICLE]],
											}
										}
CruiseMissilePods["ground_turret_cm_airtransport"] = ground_turret_cruisemissilepod:New()
CruiseMissilePods["ground_turret_cm_airtransport"].name = "Sniper Drone Fast Deploy Cruise Missile"
CruiseMissilePods["ground_turret_cm_airtransport"].description = " fires a sniper air drone atop a cruise missile"


ground_turret_cruisemissilepod.weapons  = {
											[1] = { name =  "cm_transport"	,											
													onlyTargetCategory = [[BUILDING GROUND VEHICLE]],
											}
										}
CruiseMissilePods["ground_turret_cm_transport"] = ground_turret_cruisemissilepod:New()
CruiseMissilePods["ground_turret_cm_transport"].name = "Tansport Cruise Missile"
CruiseMissilePods["ground_turret_cm_transport"].description = " drops a transported unit to target"
CruiseMissilePods["ground_turret_cm_transport"].transportSize = 16
CruiseMissilePods["ground_turret_cm_transport"].transportCapacity = 1
CruiseMissilePods["ground_turret_cm_transport"].isFirePlatform = false


ground_turret_cruisemissilepod.weapons  = {
											[1] = { name =  "cm_antiarmor"	,													
													onlyTargetCategory = [[BUILDING GROUND VEHICLE ARMOR]],
											}
										}
CruiseMissilePods["ground_turret_cm_antiarmor"] = ground_turret_cruisemissilepod:New()
CruiseMissilePods["ground_turret_cm_antiarmor"].name = "Anti-Armor Cruise Missile"
CruiseMissilePods["ground_turret_cm_antiarmor"].description = " fire anti armour salvoes pre impact"



return lowerkeys(
{
	["ground_turret_cm_airstrike"] = CruiseMissilePods["ground_turret_cm_airstrike"],
	["ground_turret_cm_transport"] = CruiseMissilePods["ground_turret_cm_transport"],
	["ground_turret_cm_antiarmor"] = CruiseMissilePods["ground_turret_cm_antiarmor"],
	["ground_turret_cm_airtransport"] = CruiseMissilePods["ground_turret_cm_airtransport"],
	
})