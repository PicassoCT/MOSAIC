local stickybomb =  Turret:New{
	name = "Explosive Charge",
	Description = "sticks to vehicles/buildings/units closest explodes after 5 seconds",
	
	objectName = "ground_stickybomb.dae",
	script = "ground_stickybombscript.lua",
	buildPic = "StickyBomb.png",
	iconType = "ground_turret_iied",
	--floater = true,
	--cost
	buildCostEnergy = 300,
	buildCostMetal= 300,
	buildTime = 0.5,
	--Health
	maxDamage = 50,
	idleAutoHeal = 0,
	--Movement
	
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
	["ground_stickybomb"] = stickybomb:New()
})