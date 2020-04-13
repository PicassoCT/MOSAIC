local AIR_SNIPER = AIRCRAFT:New{

	name = "sniper drone ",
	Description = "Electrostatic Graphene Parachut",
	objectName = "air_plane_sniper.dae",
		customParams        = {
		normaltex = "unittextures/component_atlas_normal.dds",
	},
	script = "airplanesniperscript.lua",
	buildPic = "placeholder.png",
	--floater = true,
	--cost
	buildCostMetal = 50,
	buildCostEnergy = 0,
	buildTime = 2 * 60,
	--Health
	maxDamage = 50,
	idleAutoHeal = 0,
	--Movement
	
	 fireState=1,
	BrakeRate = 1,
	FootprintX = 1,
	FootprintZ = 1,
	ActivateWhenBuilt=0,
	maxBank=0.4,
	myGravity =0.5,
	mass = 1225,
	
	steeringmode        = [[1]],
	maneuverleashlength = 1380,
	turnRadius		  	= 8,
	dontLand		 	= false,
	Acceleration = 0.5,
	MaxVelocity = 2.5,
	MaxWaterDepth = 0,
	MovementClass = "Default2x2",
	TurnRate = 350,
	nanocolor=[[0.20 0.411 0.611]],
	sightDistance = 250,
	CanFly   = true,
	activateWhenBuilt   	= true,
	MaxSlope 					= 75,

	--canHover=true,
	CanAttack = true,
	CanGuard = true,
	CanMove = true,
	CanPatrol = true,
	Canstop  = true,
	onOffable = false,
	LeaveTracks = false, 

	canSubmerge         = false,
	useSmoothMesh 		=true,
	collide             = true,
	crashDrag =0.035,


	Category = [[AIR]],

	  customParams = {
	  baseclass = "vtol"
	  },

	weapons={	
			[1]={name  = "sniperrifle",
				onlyTargetCategory = [[GROUND ]],
			},
			[2]={name  = "sniperrifle",
				onlyTargetCategory = [[GROUND ]],
			}
		},
		
			


}

return lowerkeys({
	--Temp
	["air_plane_sniper"] = AIR_SNIPER:New(),
	
})
