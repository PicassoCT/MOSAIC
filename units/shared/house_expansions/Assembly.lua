
local Assembly = Building:New{
	corpse				= "",
	maxDamage           = 500,
	mass                = 500,
	buildCostEnergy     = 5000,
	buildCostMetal      = 2500,
	explodeAs			= "none",

	workerTime= 1.0,
	buildTime = 60,
	Builder = true,
	nanocolor=[[0.20 0.411 0.611]], --
	CanReclaim=false,	

	YardMap ="yyyy yyyy yyyy yyyy ",
	MetalStorage = 2500,
	buildingMask = 8,
	footprintX = 4,
	footprintZ = 4,
	maxSlope = 50.0,
	levelGround = false,
	blocking =false,

	showNanoFrame= true,
	script 					= "assemblyscript.lua",
	objectName        	= "assembly.dae",

	name = "Assembly",
	description = " creates MOSAIC Standardized drones <Automated Factory>",
		buildPic = "assembly.png",
	canCloak =true,
	canMove = true,
	cloakCost=0.0001,
	ActivateWhenBuilt=1,
	cloakCostMoving =0.0001,
	minCloakDistance = -1,
	onoffable=true,
	initCloaked = true,
	decloakOnFire = false,
	cloakTimeout = 5,
	fireState = 1,
	selfDestructCountdown = 2*60,

	usepiececollisionvolumes = false,
  	collisionVolumeType = "box",
  	collisionvolumescales = "100 70 100",
  	collisionVolumeOffsets  = {0.0, 30.0,  0.0},

	customparams = {
		helptext		= "MOSAIC Assembly",
		baseclass		= "Building",
		normaltex = "unittextures/component_atlas_normal.dds",
    },
	
		buildoptions = 
	{
	--chassis
	--air
		 --copter  --jet -- bomber --long range rocket
		
			"air_copter_ssied",	"air_copter_mg","air_copter_antiarmor",  
			"air_plane_sniper", "air_plane_rocket", "air_scoutlett",
	--ground
		--turret --snake --walker(roach) --truck

			"ground_turret_ssied",	"ground_turret_mg",	"ground_turret_antiarmor",
			--walkers
			 "ground_turret_cm_airstrike",	"ground_turret_cm_antiarmor", "ground_turret_cm_transport", 
			 --turrets
			 "ground_turret_dronegrenade" , "ground_turret_rocket","ground_tumbleweedspyder",
			 "ground_walker_mg","ground_walker_grenade", 	"ground_tank_day",
			 --vehicles
			 "ground_truck_mg", "ground_truck_ssied", "ground_truck_antiarmor",
			 "ground_truck_rocket", "ground_truck_assembly", "truck_arab6", 
			--tank 
	
	--weapon
			
	 --ssied --rocket --gattling --sniperrifle --mortar --anit-projectile -- anti-launch 
	 
	 --scan -- jam 
	 
	 --transport -only works for bomber, copter and longrange rocket
	

	},
	
	category = [[GROUND BUILDING RAIDABLE]],
	}



return lowerkeys({
	--Temp
	["assembly"] = Assembly:New(),
	
})