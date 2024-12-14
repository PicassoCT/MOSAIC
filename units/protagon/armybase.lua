
local ArmyBase = Building:New{
		corpse				= "",
		maxDamage           = 500,
		mass                = 500,
		buildCostEnergy     = 5000,
		buildCostMetal      = 2500,
		explodeAs			= "none",

		workerTime			= 1.0,
		buildTime 			= 60,
		Builder 			= true,
		nanocolor			= [[0.20 0.411 0.611]], --
		CanReclaim			= false,	

		YardMap 			="yyyy yyyy yyyy yyyy ",
		MetalStorage 		= 2500,
		buildingMask 		= 8,
		
		maxSlope 			= 50.0,
		levelGround 		= false,
		blocking 			= false,

		showNanoFrame		= true,
		script 				= "armybasescript.lua",
		objectName        	= "armybase.dae",

		name 				= "Armybase",
		description 		= " local allied armed forces",
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
			"ground_tank_day",		
			"ground_truck_mg", 	
			"ground_truck_antiarmor", 
			"ground_truck_mortar", 
			"ground_truck_rocket",		
			"air_copter_blackhawk"
		},

	
		category = [[GROUND BUILDING RAIDABLE]]
	}




return lowerkeys({
	--Temp
	["armybase"] = ArmyBase:New()
})