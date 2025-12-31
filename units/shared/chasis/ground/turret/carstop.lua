local carstop =  Turret:New{
	name = "Throw away car stop spikes",
	Description = "stops any vehicle driving over it permanent",
	
	objectName = "ground_carstop.dae",
	script = "carstopscript.lua",
	buildPic = "ground_carstop.png",
	iconType = "ground_carstop",
	--floater = true,
	--cost
	buildCostEnergy = 250,
	buildCostMetal= 150,
	buildTime = 0.5,
	--Health
	maxDamage = 50,
	idleAutoHeal = 0,
	--Movement
	mass = 100,
	 fireState=1,
	
	FootprintX = 1,
	FootprintZ = 1,
	maxSlope = 50,
	
	MaxWaterDepth = 0,
	MovementClass = "VEHICLE",

	
	nanocolor=[[0.20 0.411 0.611]],
	sightDistance = 250,
	activateWhenBuilt   	= true,
	cantBeTransported = false,
	Builder = false,
	CanAttack = true,
	CanGuard = false,
	CanMove = true,
	CanPatrol = false,
	CanStop = true,
	LeaveTracks = false, 
	levelGround =false,

	
	Category = [[GROUND]],

	  customParams = {
	  	baseclass = "turret",
	  	normaltex = "unittextures/component_atlas_normal.dds",
	  },

	 sfxtypes = {
		explosiongenerators = {
							"custom:bigbulletimpact",
							"custom:redlight"
							  },
				},
					
	
}


return lowerkeys(
{
	["ground_carstop"] = carstop:New()
})