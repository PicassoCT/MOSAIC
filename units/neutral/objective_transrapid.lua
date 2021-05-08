local objective_transrapid = Building:New{
	corpse					= "",
	maxDamage        	= 15000,
	mass           	= 500,
	buildCostEnergy    	= 5,
	buildCostMetal    	= 5,
	explodeAs				= "none",
	name = "Transrapid Trainstation",
	description = "<Objective> Protagon protect or Antagon destroy <Objective> Protagon protect or Antagon destroy",
	buildPic = "house.png",
	iconType = "house",
	Builder					= false,
	levelground				= true,
	FootprintX = 4,
	FootprintZ = 4,
	script 					= "objectivetransrapidscript.lua",
	objectName       	= "objective_transrapid.dae",

	
	
	YardMap =     [[yooy
					oooo
					oooo
					yooy]]	, 
					                    

	customparams = {	
		normaltex = "unittextures/component_atlas_normal.dds",
		helptext			= "Civilian Building",
		baseclass			= "Building", -- TODO: hacks
    },
	
	buildoptions = 
	{
	"civilian_arab0"
	},
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "130 9000 130",
	category = [[GROUND BUILDING]],

}

return lowerkeys({
	--Temp
	["objective_transrapid"] = objective_transrapid:New()
	
})
