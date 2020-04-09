local unitName = "transportedassembly"
local unitDef = {
	
	name = "Mobile Assembly",
	Description = "",
	
	objectName = "emptyObjectIsEmpty.s3o",
	script = "transportedassemblyscript.lua",
	
				buildPic = "truck_assembly.png",
	--cost
	buildCostMetal = 200,
	buildCostEnergy = 50,
	buildTime = 60,
	CanReclaim=false,
	buildDistance = 200,
	onoffable=true,
	acitvateonstart=false,
	--Health
	maxDamage = 1200,
	idleAutoHeal = 3,
	--Movement
	MovementClass = "Default2x2",
	FootprintX = 1,
	FootprintZ = 1,
	MaxSlope = 5,
	--MaxVelocity = 0.5,
	MaxWaterDepth =0,
	TurnRate = 200,
	isMetalExtractor = false,
	sightDistance = 300,
	
	reclaimable=false,
	Builder = true,
	CanAttack = true,
	CanGuard= true,
	CanMove = true,
	CanPatrol = true,
	CanStop = true,
	LeaveTracks = false,
	
	YardMap ="o",

	-- Building	
	
	ShowNanoSpray = true,
	CanBeAssisted = true,	
	workerTime = 0.54,
	buildoptions = 
	{
	--air
		 --copter  --jet -- bomber --long range rocket
		
			"air_copter_ssied",	"air_copter_mg", "air_copter_antiarmor",

	--ground
		--turret --snake --walker(roach) --truck
			"ground_turret_ssied",	"ground_turret_mg", "ground_truck_assembly",
			"ground_walker_mg"
	},
	
	
	usebuildinggrounddecal = false,
	
	
	Category = [[NOTARGET]],
	
	EnergyStorage = 0,
	EnergyUse = 75,
	MetalStorage = 0,
	EnergyMake = 0, 
	MakesMetal = 16, 
	MetalMake = 0,	
	acceleration = 0,
	
nanocolor=[[0.20 0.411 0.611]],
	
	levelGround = false,
	mass = 9990,
	
	maxSlope = 255,
	
	
	noAutoFire = false,
	
	smoothAnim = true,

	customParams = {},
	sfxtypes = {
		explosiongenerators = {
				
		},
		
	},
	
	
	
	
	
}

return lowerkeys({ [unitName] = unitDef })