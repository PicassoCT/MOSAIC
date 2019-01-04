local moveDefs 	=	 {
	{
		name			=	"VEHICLE",
		footprintX		=	3,
		maxWaterDepth	=	10,
		maxSlope		=	20,
		crushStrength	=	25,
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
		name			=	"AIRUNIT",
		footprintX		=	3,
		maxWaterDepth	=	2,
		maxSlope		=	100,
		crushStrength	=	0,
		heatmapping		=	false,
	},
}

return moveDefs