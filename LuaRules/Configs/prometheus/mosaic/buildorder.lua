-- Author: Tobi Vollebregt
-- License: GNU General Public License v2

-- Misc config
FLAG_RADIUS = 230 --from S44 game_flagManager.lua
SQUAD_SIZE = 24

-- unit names must be lowercase!

-- Format: factory = { "unit to build 1", "unit to build 2", ... }
gadget.minBuildRequirementProtagon = {
	["propagandaserver"] = 2,
	["operativeinvestigator"] = 1,
	["protagonsafehouse"] = 2,
	["operativeasset"] = 1,
	["recruitcivilian"] = 1

}


gadget.minBuildRequirementAntagon = {
	["propagandaserver"] = 2,
	["operativepropagator"] = 1,
	["antagonsafehouse"] = 2,
	["operativeasset"] = 1,
	["recruitcivilian"] = 1
}

gadget.unitBuildOrder = UnitBag{
	-- Antagon
	operativepropagator =UnitArray{"antagonsafehouse"},
	antagonsafehouse = UnitArray{
		"operativepropagator", 
		"propagandaserver",
		"operativepropagator",
		"propagandaserver",
		"antagonsafehouse",
		"propagandaserver",
		"assembly",
		"nimrod",
		"noone",
		"propagandaserver",
		"launcher",
		"launcherstep",
		"launcherstep",
		"launcherstep",
		"civilianagent",
	},
	assembly = UnitArray{
			"ground_truck_mg", 
			"ground_truck_ssied",
			"ground_truck_antiarmor",
			"air_copter_ssied",	
			"air_copter_mg",
			"air_copter_antiarmor",  	
			"ground_truck_assembly", 
			"ground_tank_night"
	},
	operativeinvestigator =UnitArray{
	"protagonsafehouse"
	},
	protagonsafehouse = UnitArray{
		"operativeinvestigator", 
		"propagandaserver",
		"operativeinvestigator",
		"propagandaserver",
		"assembly",
		"nimrod",
		"noone",
		"propagandaserver",	
		"civilianagent"
	},
	transportedassembly = UnitArray{
		"ground_turret_ssied",	
		"ground_turret_mg",
	},
}

-- Format: side = { "unit to build 1", "unit to build 2", ... }
gadget.baseBuildOrder = {
	antagon = UnitArray{
		"antagonsafehouse",	
		"propagandaserver",	
		"antagonsafehouse",	
		"propagandaserver",	
		"assembly",	
	},
	protagon = UnitArray{
		"protagonsafehouse",
		"propagandaserver",
		"protagonsafehouse"	,	
		"propagandaserver",		
		"assembly"		
	},
	
}

-- This lists all the units (of all sides) that are considered "base builders"
gadget.baseBuilders = UnitSet{
	"operativepropagator",
	"transportedassembly",
	"operativeinvestigator"

}

-- This lists all the units that should be considered flags.
gadget.flags = UnitSet{
	"house",
}

-- This lists all the units (of all sides) that may be used to cap flags.
gadget.flagCappers = UnitSet{
	"operativeinvestigator",
	"civilianagent",
	"operativeasset"
}

-- Number of units per side used to cap flags.
gadget.reservedFlagCappers = {
	protagon = 24,
	antagon = 24
}
