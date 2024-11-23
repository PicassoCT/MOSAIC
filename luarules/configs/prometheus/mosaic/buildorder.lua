-- Author: Tobi Vollebregt
-- License: GNU General Public License v2

-- Misc config
FLAG_RADIUS = 230 --from S44 game_flagManager.lua
SQUAD_SIZE = 1

-- unit names must be lowercase!
--minbuild requirements for safehouses
gadget.minBuildRequirementProtagon = {
	["air_copter_scoutlett"] = 1,
	["air_copter_ssied"] = 1,
	["air_copter_antiarmor"] = 1,
	["operativeinvestigator"] = 1,
	["protagonsafehouse"] = 3,
	["propagandaserver"] = 1,
	["operativeasset"] = 1,
	["recruitcivilian"] = 1,
	["stealvehicleicon"] = 1,
	["cybercrimeicon"] = 1
}

gadget.minBuildRequirementAntagon = {
	["air_copter_scoutlett"] = 1,
	["air_copter_ssied"] = 1,
	["air_copter_antiarmor"] = 1,
	["operativepropagator"] = 1,
	["antagonsafehouse"] = 3,
	["propagandaserver"] = 1,
	["operativeasset"] = 1,
	["recruitcivilian"] = 1,
	["stealvehicleicon"] = 1,
	["cybercrimeicon"] = 1
}

-- Format: factory = { "unit to build 1", "unit to build 2", ... }
gadget.unitBuildOrderAntagon = UnitBag{
	-- Antagon
--[[	operativepropagator = UnitArray{"antagonsafehouse"},
	operativeinvestigator = UnitArray{"protagonsafehouse"},
	--]]
	antagonassembly = UnitArray{
			"ground_truck_mg", 
			"ground_truck_ssied",
			"ground_truck_antiarmor",
			"air_copter_ssied",	
			"air_copter_mg",
			"air_copter_antiarmor",  	
			"air_copter_antiarmor",  	
			"ground_truck_assembly", 
			"ground_tank_day",
			"ground_turret_cm_transport"
	},
	
	launcher = UnitArray{
		"launcherstep",
		"launcherstep",
		"launcherstep",
		"launcherstep",
		"launcherstep",
		"launcherstep",
		"launcherstep"
	},	
	nimrod = UnitArray{
		"satellitescan",
		"satelliteanti"		
	},

	antagonsafehouse = UnitArray{
		"operativepropagator", 
		"operativepropagator",
		"civilianagent",
		"civilianagent",
		"propagandaserver",		
		"nimrod",
		"launcher",
	},
	transportedassembly = UnitArray{
		"ground_turret_mg",
		"air_copter_mg",
		"air_copter_ssied"
	},
}

gadget.unitBuildOrderProtagon = UnitBag{
	-- Antagon
--[[	operativepropagator = UnitArray{"antagonsafehouse"},
	operativeinvestigator = UnitArray{"protagonsafehouse"},
	--]]
	protagonassembly = UnitArray{
			"ground_truck_mg", 
			"ground_truck_ssied",
			"ground_truck_antiarmor",
			"air_copter_ssied",	
			"air_copter_mg",
			"air_copter_antiarmor",  	
			"air_copter_antiarmor",  	
			"ground_truck_assembly", 
			"ground_tank_day",
			"ground_turret_cm_transport"
	},
	nimrod = UnitArray{
		"satellitescan",
		"satelliteanti"		
	},
	protagonsafehouse = UnitArray{
		"operativeinvestigator", 
		"operativeinvestigator",
		"civilianagent",
		"civilianagent",
		"propagandaserver",
		"protagonassembly",
		"antagonassembly",
		"nimrod"
	},
	transportedassembly = UnitArray{
		"ground_turret_mg",
		"air_copter_mg",
		"air_copter_ssied"
	},
}

-- Format: side = { "unit to build 1", "unit to build 2", ... }
gadget.baseBuildOrder = {
	["antagon"] = UnitArray{
		"antagonsafehouse",	
		"propagandaserver",	
		"antagonsafehouse",	
		"propagandaserver",	
		"launcher",
		"launcherstep",
		"hivemind"
	},
	["protagon"] = UnitArray{
		"protagonsafehouse",
		"propagandaserver",
		"protagonsafehouse"	,	
		"propagandaserver",		
		"protagonassembly"	
	},
}

-- This lists all the units (of all sides) that are considered "base builders"
gadget.baseBuilders = UnitSet{
	"operativepropagator",
	"operativeinvestigator"
}

-- This lists all the units that should be considered flags.
gadget.flags = UnitSet{
	"house_arab0",
	"house_western0",
	"raidicon",
	"recruitcivilian"
}

-- This lists all the units (of all sides) that may be used to cap flags.
gadget.flagCappers = UnitSet{
	"operativepropagator",
	"operativeinvestigator",
	"civilianagent",
	"operativeasset",
	"ground_truck_mg"
}

-- Number of units per side used to cap flags.
gadget.reservedFlagCappers = {
	protagon = 4,
	antagon = 4
}
