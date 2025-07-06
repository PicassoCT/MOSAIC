
local ArmyBase = Building:New{
		corpse				= "",
		maxDamage           = 4000,
		mass                = 500,
		buildCostEnergy     = 15000,
		buildCostMetal      = 15000,
		explodeAs			= "none",

		workerTime			= 1.0,
		buildTime 			= 30,
		Builder 			= true,
		nanocolor			= [[0.20 0.411 0.611]], --
		CanReclaim			= false,	

		YardMap 			="yyyy yyyy yyyy yyyy",
		MetalStorage 		= 2500,
		buildingMask 		= 8,
		
		maxSlope 			= 50.0,
		levelGround 		= false,
		blocking 			= false,
		showNanoSpray 		= false,
		showNanoFrame		= true,
		script 				= "armybasescript.lua",
		objectName        	= "armybase.dae",

		name 				= "Armybase",
		description 		= " recruits armed local forces",
		buildPic			= "assembly.png",
		canCloak 			= false,
		canMove 		 	= true,
		ActivateWhenBuilt	= 1,
		
		onoffable			= true,
		initCloaked 		= false,
		fireState 			= 1,
		selfDestructCountdown = 2*60,

		usepiececollisionvolumes = false,
	  	collisionVolumeType = "box",
	  	collisionvolumescales = "100 70 100",
	  	collisionVolumeOffsets  = {0.0, 30.0,  0.0},

		customparams = {
			helptext		= "Local Armybaswe",
			baseclass		= "Building",
			normaltex = "unittextures/component_atlas_normal.dds",
	    },
	
		buildoptions = 
		{
			"ground_tank_night",		
			"ground_truck_mg", 	
			"ground_truck_antiarmor", 
			"ground_truck_mortar", 
			"ground_truck_rocket",		
			"air_copter_blackhawk",
			"air_plane_rocket",
			"air_plane_sniper"
		},

	
		category = [[GROUND BUILDING RAIDABLE]]
	}




return lowerkeys({
	--Temp
	["armybase"] = ArmyBase:New()
})