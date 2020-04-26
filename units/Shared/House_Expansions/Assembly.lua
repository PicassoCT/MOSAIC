
local Assembly = Building:New{
	corpse				= "",
	maxDamage           = 500,
	mass                = 500,
	buildCostEnergy     = 5,
	buildCostMetal      = 5,
	explodeAs			= "none",


	buildTime =    60,
	Builder = true,
	nanocolor=[[0.20 0.411 0.611]], --
	CanReclaim=false,	
	workerTime = 0.065,
	YardMap ="yyyy yyyy yyyy yyyy ",
	MaxSlope 					= 50,
	MetalStorage = 2500,
	buildingMask = 8,
	footprintX = 4,
	footprintZ = 4,
	showNanoFrame= true,
	script 					= "assemblyscript.lua",
	objectName        	= "assembly.dae",
		customParams        = {
		normaltex = "unittextures/component_atlas_normal.dds",
	},
	name = "Assembly",
	description = " creates MOSAIC Standardized drones <Automated Factory>",
		buildPic = "assembly.png",
	canCloak =true,
	canMove = true,
	cloakCost=0.0001,
	ActivateWhenBuilt=1,
	cloakCostMoving =0.0001,
	minCloakDistance = 0,
	onoffable=true,
	initCloaked = true,
	decloakOnFire = true,
	cloakTimeout = 5,

	
	customparams = {
		helptext		= "MOSAIC Assembly",
		baseclass		= "Building",
    },
	
		buildoptions = 
	{
	--chassis
	--air
		 --copter  --jet -- bomber --long range rocket
		
			"air_copter_ssied",	"air_copter_mg","air_copter_antiarmor",  
			"air_plane_sniper",
	--ground
		--turret --snake --walker(roach) --truck

			"ground_turret_ssied",	"ground_turret_mg",	"ground_turret_antiarmor",
			--walkers
			 "ground_turret_cm_airdrop",	"ground_turret_cm_antiarmor", "ground_turret_cm_ssied", 
			 --turrets
			 "ground_turret_cm_walker",	 "ground_walker_mg", "ground_tumbleweedspyder",
			 --vehicles
			 "ground_truck_mg", "ground_truck_ssied", "ground_truck_antiarmor",
			 "ground_truck_assembly",	"truck_arab6", 
			--tank 
			"ground_tank_night"
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