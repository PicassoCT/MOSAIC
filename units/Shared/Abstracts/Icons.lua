local DoubleAgent = Abstract:New{
    corpse					  = "",
    maxDamage         	  = 500,
    mass                = 500,
    buildCostEnergy    	  = 5,
    buildCostMetal     	  = 5,
    canMove					  = true,

    explodeAs				  = "none",
    Acceleration = 0,
    BrakeRate = 0,
    TurnRate = 0,
    MaxVelocity = 0,
    --
    description = "Activate to turn sides",

    CanAttack = false,
    CanGuard = false,

    CanMove = true,
    CanPatrol = true,
    CanStop = true,
    script 					= "doubleagentscript.lua",
    objectName        	= "doubleagent.s3o",

    canCloak =true,
    cloakCost=0.0001,
    ActivateWhenBuilt=1,
    cloakCostMoving =0.0001,
    minCloakDistance = 0,
    onoffable=true,
    initCloaked = true,
    decloakOnFire = true,
    cloakTimeout = 5,

    onoffable=true,
    activatewhenbuilt = true,


    customparams = {
        helptext		= "Civilian Agent working for the opposite site",
        baseclass		= "Human", -- TODO: hacks
    },
    category = "NOTARGET",


}



local RecruitCivilian = Abstract:New{

        maxDamage         	  = 500,
        mass                = 500,
        buildCostEnergy    	  = 5,
        buildCostMetal     	  = 5,

        explodeAs				  = "none",


        --orders

        script 				= "recruitcivilianscript.lua",
        objectName        	= "RecruitIcon.dae",
		buildPic = "recruitcivilian.png",
        -- Hack Infrastructure
        --CommandUnits (+10 Units)
        -- WithinCellsInterlinked (Recruit)

        canCloak =true,
        cloakCost=0.000001,
        cloakCostMoving =0.0001,
        minCloakDistance = 5,
        onoffable=true,
        MaxSlope 					= 100,
		

        customparams = {
            helptext		= "Propaganda Operative",
            baseclass		= "Human", -- TODO: hacks
        },

        category = [[NOTARGET]],
}

local RaidIcon = Abstract:New{
    corpse					  = "",
    maxDamage         	  = 500,
    mass                = 500,
    buildCostEnergy    	  = 5,
    buildCostMetal     	  = 5,
    canMove					  = true,

    explodeAs				  = "none",
    Acceleration = 0,
    BrakeRate = 0,
    TurnRate = 0,
    MaxVelocity = 0,
    --
    description = "Display raid progress",

    CanAttack = false,
    CanGuard = false,

    CanMove = true,
    CanPatrol = true,
    CanStop = true,
    script 					= "raidiconscript.lua",
    objectName        	= "RaidIcon.dae",
	buildPic = "raidicon.png",
    canCloak =true,
    cloakCost=0.0001,
    ActivateWhenBuilt=1,
    cloakCostMoving =0.0001,
    minCloakDistance = 0,
    onoffable=true,
    initCloaked = true,
    decloakOnFire = true,
    cloakTimeout = 5,

    onoffable=true,
    activatewhenbuilt = true,

    customparams = {
        helptext		= "Civilian Agent working for the opposite site",
        baseclass		= "Human", -- TODO: hacks
    },
    category = "NOTARGET",
}

local InterrogationIcon = Abstract:New{
    corpse					  = "",
    maxDamage         	  = 500,
    mass                = 500,
    buildCostEnergy    	  = 5,
    buildCostMetal     	  = 5,
    canMove					  = true,
buildPic = "interrogationicon.png",
    explodeAs				  = "none",
    Acceleration = 0,
    BrakeRate = 0,
    TurnRate = 0,
    MaxVelocity = 0,
    --
    description = "Interrogation progress",

    CanAttack = false,
    CanGuard = false,

    CanMove = true,
    CanPatrol = true,
    CanStop = true,
    script 					= "interrogationIconScript.lua",
    objectName        	= "InterrogationIcon.dae",

    canCloak =true,
    cloakCost=0.0001,
    ActivateWhenBuilt=1,
    cloakCostMoving =0.0001,
    minCloakDistance = 0,
    onoffable=true,
    initCloaked = true,
    decloakOnFire = true,
    cloakTimeout = 5,

    onoffable=true,
    activatewhenbuilt = true,



    customparams = {
        helptext		= "Interrogation in Progress",
        baseclass		= "Human", -- TODO: hacks
    },
    category = "NOTARGET",
}


return lowerkeys({
    --Temp
    ["doubleagent"] = DoubleAgent:New(),
    ["interrogationicon"] = InterrogationIcon:New(),
    ["raidicon"] = RaidIcon:New(),
    ["recruitcivilian"] = RecruitCivilian:New(),
})
