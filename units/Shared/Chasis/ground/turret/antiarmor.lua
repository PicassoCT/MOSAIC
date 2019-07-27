
local ground_turret_antiarmor =  Turret:New{
	name = "Deployed Anti Tank",
	-- This is a anti-tank drone body, deployed after flight
	--capable to one-time launch a projectile 
	-- It has 4 SubScout Air-Drones which seperate at deploy Time and relay target information
	Description = "Deployed Anti Armor Projectile ",
	
	objectName = "ground_turret_sied.dae",
	script = "groundturretantitankscript.lua",
	buildPic = "placeholder.png",
	--floater = true,
	--cost
	buildCostMetal = 50,
	buildCostEnergy = 0,
	buildTime = 5,
	--Health
	maxDamage = 50,
	idleAutoHeal = 0,
	--Movement
	
	 fireState=1,
	
	FootprintX = 1,
	FootprintZ = 1,
	maxSlope = 50,
	
	MaxWaterDepth = 0,
	MovementClass = "Default2x2",

	
	nanocolor=[[0 0.9 0.9]],
	sightDistance = 250,
	activateWhenBuilt   	= true,
	cantBeTransported = false,

	--canHover=true,
	CanAttack = true,
	CanGuard = true,
	CanMove = false,
	CanPatrol = false,
	Canstop  = true,
	onOffable = false,
	LeaveTracks = false, 
	canCloak =true,
	
	
	Category = [[ARMOR GROUND BUILDING]],

	  customParams = {
	  baseclass = "turret"
	  },
	 sfxtypes = {
		explosiongenerators = {
							"custom:bigbulletimpact"
							  },
				},
				
	weapons = {
		[1]={name  = "javelinrocket",
			onlyTargetCategory = [[BUILDING GROUND VEHICLE]],
			},
			
		},	

			


}


return lowerkeys({
	["ground_turret_antiarmor"] = ground_turret_antiarmor:New()
	
})
