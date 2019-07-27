local moveDefs 	=	 {
		
	
		{
			name			=	"bhover3",
			footprintX		=	3,
			maxWaterDepth	=	10,
			maxSlope		=	20,
			crushStrength	=	25,
			heatmapping		=	false,
		},
		{
		name			=	"VEHICLE",
		footprintX		=	3,
		maxWaterDepth	=	10,
		maxSlope		=	20,
		crushStrength	=	25,
		heatmapping		=	false,
	},	
	{
		name			=	"TANK",
		footprintZ		=	4,
		footprintX		=	4,
		maxWaterDepth	=	0,
		maxSlope		=	35,
		crushStrength	=	150,
		heatmapping		=	false,
	},
	
	{
		name			=	"BIPEDAL",
		footprintX		=	1,
		footprintZ 		=	1,
		maxWaterDepth	=	5,
		maxSlope		=	45,
		crushStrength	=	25,
		heatmapping		=	false,
	},
		{
		name			=	"QUADRUPED",
		footprintX		=	2,
		footprintZ 		=	2,
		maxWaterDepth	=	5,
		maxSlope		=	80,
		crushStrength	=	25,
		heatmapping		=	false,
	},
	{
		name			=	"AIRUNIT",
		footprintX		=	2,
		maxWaterDepth	=	2,
		maxSlope		=	100,
		crushStrength	=	0,
		heatmapping		=	false,
	},
}

return moveDefs