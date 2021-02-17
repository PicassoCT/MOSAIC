local unitName = "impactor"

local unitDef = {
	name = "Explosion",
	Description = "We will meet again, dont know where dont know when, but we all go together when we go.<Projectile>",
	objectName = "cComENuke.s3o",
	script = "impactorscript.lua",
	buildPic = "placeholder.png",
	--floater = true,
	--cost
	buildCostMetal = 0,
	buildCostEnergy = 0,
	buildTime =1,
	--Health
	maxDamage = 1200,
	idleAutoHeal = 0,
	--Movement
	
	FootprintX = 1,
	FootprintZ = 1,
	MaxSlope = 5,
	--MaxVelocity = 0.5,
	MaxWaterDepth =0,
	--MovementClass = "Default2x2",--
	selfDestructAs ="defaultweapon",
	explodeAs = "defaultweapon",
	
	sightDistance = 300,
	
	
	Category = [[NOTARGET]],
	
	
	
	
	customParams = {},
	sfxtypes = {
		explosiongenerators = {
			"custom:nukefireshine",--1024
			"custom:fireshockwave",--1025 
			"custom:nukeexplosion",--1026
			
			
			
			"custom:orangesmoke",--1027
			"custom:nukesuckfire",--1028
			
			"custom:ashflakes",----1029
			"custom:darkcloudnuke",--1030	 --testME	
			"custom:greycloud",--1031		 --testME
			"custom:dirt",--1032
			"custom:nukefireshinesmall",--1033 --testME
			
			"custom:firecloudnuke",--1034
			"custom:permacloudnuke",--1035
			"custom:nukeshroom",--1036
		},
		
	},
	
}

return lowerkeys({ [unitName] = unitDef })