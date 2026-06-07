
local unitName = "innerCityDeco_inter5"
local unitDef = {
	name = "",

	Description = "Skytree Advertising",

	objectName = "innerCityDeco_inter5.dae",

	script = "feature_skytree_script.lua",

	buildPic = "placeholder.png",

	levelGround =false,

	--cost

	buildCostMetal = 15,

	buildCostEnergy = 1,

	buildTime = 1,

	--Health

	maxDamage = 6660,

	idleAutoHeal = 15,

	autoheal=10,

	--Movement

	mass=18020,

	upRight=true,

	blocking=true,

	pushResistant=true,

	FootprintX = 1,

	FootprintZ = 1,





	sightDistance = 80,



	reclaimable=false,

	Builder = false,

	CanAttack = true,

	CanGuard = false,

	CanMove = true,

	CanPatrol = false,

	CanStop = true,

	LeaveTracks = false,

	useSmoothMesh = false,



	usepiececollisionvolumes = false,

	collisionVolumeType = "cylinder",

	collisionvolumescales = "10 25 10",

	 

	  customParams = {},

	 sfxtypes = {

		explosiongenerators = {	    

							  },

		

				},



	 

	 

	Category = [[GROUND BUILDING]],









}



return lowerkeys({ [unitName] = unitDef })
