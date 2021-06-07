local antagonDefs = {

	["antagonsafehouse_defenders"] =
	{
		members = {
			"operativeproapgator",
			"civilianagent",
			"civilianagent",
			"operativeasset",
			"air_copter_ssied"
		},
		name = "HQ Combat Squad",
		description = "2 x Enfield Rifle, 3 x Sten SMG, 1 x Bren LMG: Small Combat Squad",
		buildCostMetal = 800,
		buildPic = "placeholder.png",
	},

	 ["antagon_upgrades"] =
	{
		members = {
		"propagandaserver",
		"assembly",
		"nimrod",
		"launcher",
		},
		name = "Enfield Rifle Platoon",
		description = "10 x Enfield Rifle, 2 x Sten SMG: Long-Range Combat Platoon",
		buildCostMetal = 1926,
		buildPic = "placeholder.png",
	},

	["assembly_assaultunits"] =
	{
		members = {
		"ground_truck_mg", 
			"ground_truck_ssied",
			"ground_truck_antiarmor",
			"air_copter_ssied",	
			"air_copter_mg",
			"air_copter_antiarmor",  	
			"air_copter_antiarmor",  	
			"ground_truck_assembly", 
			"ground_tank_day",
			"ground_turret_cm_walker"
		},
		name = "Assault Platoon",
		description = "10 x STEN SMG, 1 x Commando: Close-Quarters Assault Infantry",
		buildCostMetal = 1862,
		buildPic = "placeholder.png",
	},

	["nimrod"] =
	{
		members = {
			"satellitescan",
			"satelliteanti",
			"satellitegodrod"	
		},
		name = "Machinegun Squad",
		description = "1 x Vickers, 2 x Bren Machineguns, 1 x Scout: Infantry Fire Support Squad",
		buildCostMetal = 1280,
		buildPic = "placeholder.png",
	},

	["transportedassembly"] =
	{
		members = {
		"ground_turret_mg",
		"air_copter_mg",
		"air_copter_ssied"
	},
		name = "Mobile Assembly",
		description = "1 x Enfield Sniper, 1 x Scout: Long-Range Fire Support",
		buildCostMetal = 1140,
		buildPic = "placeholder.png",
	},

	["launcher"] = {
		members = {
		"launcherstep",
		"launcherstep",
		"launcherstep",
		"launcherstep",
		"launcherstep",
		"launcherstep",
		"launcherstep"
		},
		name = "3-inch Mortar Team",
		description = "3 x Mortar, 1 x Scout: Heavy Infantry Fire Support",
		buildCostMetal = 2140,
		buildPic = "placeholder.png",
	}
}

return antagonDefs
