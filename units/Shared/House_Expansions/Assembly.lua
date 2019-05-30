
local Assembly = Building:New{
	corpse				= "",
	maxDamage           = 500,
	mass                = 500,
	buildCostEnergy     = 5,
	buildCostMetal      = 5,
	explodeAs			= "none",



	Builder = true,
	nanocolor=[[0 0 0]], --
	CanReclaim=false,	
	workerTime = 0.065,
	YardMap ="yyyy yyyy yyyy yyyy ",
	MaxSlope 					= 50,
	MetalStorage = 2500,
	buildingMask = 8,
	footprintX = 4,
	footprintZ = 4,
	
	script 					= "assemblyscript.lua",
	objectName        	= "assembly.s3o",
	name = "Assembly",
	description = " creates MOSAIC Standardized drones <Automated Factory>",

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
	--ground
		--turret --snake --walker(roach) --truck
			"ground_turret_ssied",	
			"ground_turret_mg",	
			"ground_turret_antitank",
			"ground_truck_assembly", 
			"truck", "ground_truck_mg", "ground_truck_ssied", "ground_truck_antiarmor"
			--
			--tank (expensive, slow, easy destroyable by drones)
	--weapon
			
	 --ssied --rocket --gattling --sniperrifle --mortar --anit-projectile -- anti-launch 
	 
	 --scan -- jam 
	 
	 --transport -only works for bomber, copter and longrange rocket
	

	},
	
	category = [[GROUND BUILDING ARRESTABLE]],
	}



return lowerkeys({
	--Temp
	["assembly"] = Assembly:New(),
	
})