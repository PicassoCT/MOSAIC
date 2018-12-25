local moveDefs 	=	 {
	{
		name			=	"TRUCK",
		footprintX		=	3,
		maxWaterDepth	=	10,
		maxSlope		=	20,
		crushStrength	=	25,
		heatmapping		=	false,
	},
	
	{
		name			=	"INFANTRY",
		footprintX		=	2,
		maxWaterDepth	=	30,
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