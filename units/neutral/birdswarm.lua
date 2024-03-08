
local birdswarm = AIRCRAFT:New{
	name = "Birds",
	Description = "",
	objectName = "birdswarm.dae",
	script = "pidgeonswarmscript.lua",
	--script = "pieceMaker.lua",

	--floater = true,
	--cost
	buildCostMetal = 2260,
	buildCostEnergy = 4130,
	buildTime = 190,
	--Health
	maxDamage = 880,
	idleAutoHeal = 1,
	--Movement
	Acceleration = 0.5,

	BrakeRate = 1,
	FootprintX = 3,
	FootprintZ = 3,
	steeringmode = [[1]],
	maneuverleashlength = 1380,
	turnRadius		 	= 8,
	dontLand		 	= false,
	MaxVelocity = 2.5,
	MaxWaterDepth = 30,
	MovementClass = "AIRUNIT",
	TurnRate = 150,
	nanocolor=[[0 0.9 0.9]],
	sightDistance = 500,
	CanFly = true,
	
	--canHover=true,

	CanMove = true,
	CanPatrol = true,
	Canstop = true,
	
	LeaveTracks = false, 
	cruiseAlt=265,
	
	maxBank=0.4,
	myGravity =0.5,
	mass = 1225,
	canSubmerge = false,
	useSmoothMesh 		= false,
	collide = true,
	crashDrag =0.035,
	
	Category = [[AIR]],
	
	customParams = {},
	sfxtypes = {
		explosiongenerators = {

			
			
		},
		
	},	

	
}

return lowerkeys({
	--Temp
	["birdswarm"] = birdswarm:New(),	
})
