local satteliteGodrod = Satellite:New{
	name = "Project Thor",
	Description = "  Orbital Bombardment Satellite ",
	buildTime= 45,
	maxDamage          		= 500,
	mass              		= 5000,
	buildCostEnergy    		= 7500,
	buildCostMetal      	= 4000,
	explodeAs				= "none",
	maxVelocity				= 7.15, --14.3, --86kph/20
	acceleration   		 	= 1.7,
	brakeRate      		 	= 0.1,
	turninplace				= true,
	footprintX 				= 1,
	footprintZ 				= 1,
	script 					= "satellitegodscript.lua",
	objectName        		= "SatGodRod.dae",

	alwaysupright = true,
	upright= true,
	canAttack = true,
	canLand = false,


	customParams			= {
		helptext		= "Nuklear Option",
		baseclass		= "Satellite", 
		normaltex = "unittextures/component_atlas_normal.dds",
    },
	category = [[ORBIT]],
	buildPic = "orbitalstrike_sat.png",
	
	usepiececollisionvolumes = true,

	sightDistance		= 250 , 

	fireState = 1,
	weapons = {
		[1]={
			name  = "godrodmarkerweapon",   
			mainDir = {0.0, 1.0, 0.0},
			onlyTargetCategory = [[GROUND BUILDING]]
			},					
		},	
		
}

return lowerkeys({
	--Temp
	["satellitegodrod"] = satteliteGodrod:New(),
	
})