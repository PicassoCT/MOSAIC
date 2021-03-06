local satteliteGodrod = Satellite:New{
	name = "Orbital Strike Satellite ",
	Description = " Cinetic orbital bomardment plattform ",
	buildTime= 45,
	maxDamage          		= 500,
	mass              		= 500,
	buildCostEnergy    		= 1500,
	buildCostMetal      	= 5000,
	explodeAs				= "none",
	maxVelocity				= 7.15, --14.3, --86kph/20
	acceleration   		 	= 1.7,
	brakeRate      		 	= 0.1,
	turninplace				= true,
	footprintX 				= 1,
	footprintZ 				= 1,
	script 					= "satellitegodscript.lua",
	objectName        		= "SatGodRod.dae",
		customParams        = {
		normaltex = "unittextures/component_atlas_normal.dds",
	},
	

	alwaysupright = true,
	upright= true,
	canAttack = true,
	canLand = false,
    --canManualFire = true,

	customparams			= {
		helptext		= "Nuklear Option",
		baseclass		= "Satellite", -- TODO: hacks
    },
	category = [[ORBIT]],
	buildPic = "orbitalstrike_sat.png",
	
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "5 25 5",
	sightDistance		= 	125, 

	fireState = 1,
	weapons = {
		[1]={
			name  = "godrodmarkerweapon",   
			--mainDir = "0 1 0",
			--maxAngleDif = 90,
			onlyTargetCategory = [[GROUND BUILDING]]
			},
					
		},	
		
}

return lowerkeys({
	--Temp
	["satellitegodrod"] = satteliteGodrod:New(),
	
})