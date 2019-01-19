local RecruitCivilian = Abstract:New{
	
	maxDamage         	  = 500,
	mass                = 500,
	buildCostEnergy    	  = 5,
	buildCostMetal     	  = 5,

	explodeAs				  = "none",

	
	--orders
	
	script 				= "recruitcivilianscript.lua",
	objectName        	= "recruitcivilian.s3o",

	-- Hack Infrastructure
	--CommandUnits (+10 Units)
	-- WithinCellsInterlinked (Recruit)
	
	canCloak =true,
	cloakCost=0.000001,
	cloakCostMoving =0.0001,
	minCloakDistance = 5,
	onoffable=true,


	customparams = {
		helptext		= "Propaganda Operative",
		baseclass		= "Human", -- TODO: hacks
    },
}


return lowerkeys({
	--Temp
	["recruitcivilian"] = RecruitCivilian:New(),
	
})

