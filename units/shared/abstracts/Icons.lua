local DestroyedObjective =
    Abstract:New {
    corpse = "",
    maxDamage = 15000,
    mass = 500,
    buildCostEnergy = 5,
    buildCostMetal = 5,
    canMove = true,
    explodeAs = "none",
    Acceleration = 0,
    BrakeRate = 0,
    TurnRate = 0,
    MaxVelocity = 0,
    --
    alwaysUpright = true,
    name = "Destroyed Objective",
    description = "",
    levelGround = false,
    CanAttack = false,
    CanGuard = false,
    CanMove = false,
    CanPatrol = false,
    CanStop = false,
    script = "DestroyedObjectiveScript.lua",
    objectName = "destroyedObjectiveIcon.dae",
    buildPic = "placeholder.png",
    iconType = "placeholder",

    onOffable = false,


    customparams = {
        helptext = "",
        baseclass = "Human" ,-- TODO: hacks
        normaltex = "unittextures/component_atlas_normal.dds",
    },
    category = "NOTARGET"
}

local DoubleAgent =
    Abstract:New {
    corpse = "",
    maxDamage = 500,
    mass = 500,
    buildCostEnergy = 5,
    buildCostMetal = 5,
    canMove = true,
    explodeAs = "none",
    Acceleration = 0,
    BrakeRate = 0,
    TurnRate = 0,
    MaxVelocity = 0,
    --
    alwaysUpright = true,
    name = "DoubleAgent",
    description = "Activate to turn sides",
    levelGround = false,
    CanAttack = false,
    CanGuard = false,
    CanMove = false,
    CanPatrol = false,
    CanStop = false,
    script = "doubleagentscript.lua",
    objectName = "doubleagent.dae",
    buildPic = "doubleagent.png",
    iconType = "doubleagent",
    canCloak = true,
    cloakCost = 0.0001,
    cloakCostMoving = 0.0001,
    sightDistance = 50,
    minCloakDistance = 0,
    initCloaked = true,
    onOffable = false,
    decloakOnFire = false,

    customparams = {
        helptext = "Civilian Agent working for the opposite site",
        baseclass = "Human" ,-- TODO: hacks
        normaltex = "unittextures/component_atlas_normal.dds",
    },
    category = "NOTARGET"
}

local RecruitCivilian =
    Abstract:New {
    maxDamage = 500,
    mass = 500,
    buildCostEnergy = 0,
    buildCostMetal = 250,
    explodeAs = "none",
    --orders
    buildTime = 3.0,
    script = "recruitcivilianscript.lua",
    objectName = "RecruitIcon.dae",
    buildPic = "recruitcivilian.png",
    iconType = "recruitcivilian",
    --
    name = "Recruit civilian",
    description = "- recruits a civilian for your team",
    -- Hack Infrastructure
    --CommandUnits (+10 Units)
    -- WithinCellsInterlinked (Recruit)
    buildtime = 15,
    canCloak = true,
    cloakCost = 0.000001,
    cloakCostMoving = 0.0001,
    minCloakDistance = 5,
    onoffable = true,
    MaxSlope = 100,
    levelGround = false,
    customparams = {
        helptext = "Propaganda Operative",
        baseclass = "Human" -- TODO: hacks
    },
    category = [[NOTARGET]]
}

local StealMotorbike =
    Abstract:New {
    maxDamage = 500,
    mass = 500,
    buildCostEnergy = 0,
    buildCostMetal = 250,
    explodeAs = "none",
    --orders
    buildTime = 3.0,
    script = "stealMotorbikeScript.lua",
    objectName = "civilian_motorbike.dae",
    buildPic = "MotorBike.png",
    iconType = "recruitcivilian",
    buildingMask = 8,
    --
    name = "Motorbike",
    description = "steal from any house",
    -- Hack Infrastructure
    --CommandUnits (+10 Units)
    -- WithinCellsInterlinked (Recruit)
    buildtime = 5,

    minCloakDistance = 5,
    onoffable = true,
    MaxSlope = 100,
    levelGround = false,
    customparams = {
        helptext = "Motorbike",
        baseclass = "Human" -- TODO: hacks
    },
    category = [[NOTARGET]]
}

local RaidIcon =
    Abstract:New {
    corpse = "",
    maxDamage = 500,
    mass = 500,
    buildCostEnergy = 0,
    buildCostMetal = 150,
    canMove = true,
    levelGround = false,
    explodeAs = "none",
    Acceleration = 0,
    BrakeRate = 0,
    TurnRate = 0,
    MaxVelocity = 0,
    customparams = {
        normaltex = "unittextures/component_atlas_normal.dds"
    },
    usepiececollisionvolumes = false,
    collisionVolumeType = "box",
    collisionvolumescales = "110 50 110",
    -- name = "Raid Location",
    -- description = "a raid of a location is in Progress",

    CanAttack = false,
    CanGuard = false,
    CanMove = true,
    CanPatrol = true,
    CanStop = true,
    script = "raidiconscript.lua",
    objectName = "RaidIcon.dae",
    buildPic = "raidicon.png",
    iconType = "raidicon",
    ActivateWhenBuilt = 1,
    onoffable = true,
    activatewhenbuilt = true,
    customparams = {
        helptext = "Civilian Agent working for the opposite site",
        baseclass = "Human", -- TODO: hacks
    },
    category = "NOTARGET"
}

local InterrogationIcon =
    Abstract:New {
    corpse = "",
    maxDamage = 500,
    mass = 500,
    buildCostEnergy = 5,
    buildCostMetal = 5,
    canMove = true,
    buildPic = "interrogationicon.png",
    iconType = "interrogationicon",
    explodeAs = "none",
    Acceleration = 0,
    BrakeRate = 0,
    TurnRate = 0,
    MaxVelocity = 0,
    --
    description = "Interrogation progress",
    levelGround = false,
    CanAttack = false,
    CanGuard = false,
    name = "Interrogation",
    description = "a interrogation of a person is in progress",
    CanMove = true,
    CanPatrol = true,
    CanStop = true,
    script = "interrogationIconScript.lua",
    objectName = "InterrogationIcon.dae",
    onoffable = true,
    onoffable = true,
    activatewhenbuilt = true,
    customparams = {
        helptext = "Interrogation in Progress",
        baseclass = "Human" -- TODO: hacks

    },

  
       
    category = "NOTARGET"
}

local SnipeIcon =
    Abstract:New {
    corpse = "",
    maxDamage = 500,
    mass = 500,
    buildCostEnergy = 5,
    buildCostMetal = 5,
    canMove = true,
    buildPic = "",
    iconType = "",
    explodeAs = "none",
    Acceleration = 0,
    BrakeRate = 0,
    TurnRate = 0,
    MaxVelocity = 0,
    --
    description = "A raid unit/drone ",
    levelGround = false,
    CanAttack = true,
    CanGuard = false,
    name = "Raidunit",
    CanMove = true,
    CanPatrol = true,
    CanStop = true,
    script = "snipeIconscript.lua",
    objectName = "snipeIcon.dae",
    canCloak =true,
    -- cloakCost=0.0001,
    -- ActivateWhenBuilt=1,
    -- cloakCostMoving =0.0001,
    -- minCloakDistance = 0,
    -- onoffable=true,
    -- initCloaked = true,
    -- decloakOnFire = false,
    -- cloakTimeout = 5,

    onoffable = true,
    activatewhenbuilt = true,
    weapons = {
        [1] = {
            name = "marker",
            onlyTargetCategory = [[ABSTRACT]]
        }
    },
    customparams = {
        helptext = "Sniper/Raid Icon",
        baseclass = "Abstract" -- TODO: hacks
    },
    category = "NOTARGET ABSTRACT"
}

local ObjectiveIcon =
    Abstract:New {
    corpse = "",
    maxDamage = 500,
    mass = 500,
    buildCostEnergy = 5,
    buildCostMetal = 5,
    canMove = true,
    buildPic = "",
    iconType = "interrogationicon",
    explodeAs = "none",
    Acceleration = 0,
    BrakeRate = 0,
    TurnRate = 0,
    MaxVelocity = 0,
    --
    description = "A raid unit/drone ",
    levelGround = false,
    CanAttack = false,
    CanGuard = false,
    name = "Raidunit",
    CanMove = true,
    CanPatrol = true,
    CanStop = true,
    script = "objectiveIconScript.lua",
    objectName = "objectiveIcon.dae",
    onoffable = true,
    activatewhenbuilt = true,
    customparams = {
        helptext = "Sniper/Raid Icon",
        baseclass = "Abstract" -- TODO: hacks
    },
    category = "NOTARGET ABSTRACT"
}

local BribeIcon =
    Abstract:New {
    corpse = "",
    maxDamage = 500,
    mass = 500,
    buildCostEnergy = 5000,
    buildCostMetal = 5000,
    canMove = true,
    buildPic = "BribeIcon.png",
    iconType = "BribeIcon",
    explodeAs = "none",
    Acceleration = 0.1,
    BrakeRate = 1.0,
    TurnRate = 90000,
    MaxVelocity = 1.0,
    MovementClass = "Default2x2",
    CanFly   = true,
    useSmoothMesh = true,
    alwaysUpright = true,
    alwaysupright = true,
    --
    description = "Bribe police to go to this location ",
    levelGround = false,
    CanAttack = false,
    CanGuard = false,
    name = "Policebribe",
    CanMove = true,
    CanPatrol = true,
    CanStop = true,
    script = "bribeIconscript.lua",
    objectName = "bribeIcon.dae",
    onoffable = true,
    activatewhenbuilt = true,
    MaxSlope = 100,

    customparams = {
        helptext = "Sniper/Raid Icon",
        baseclass = "Abstract" -- TODO: hacks
    },
    category = "NOTARGET ABSTRACT"
}

local SocialEngineering =
    Abstract:New {
    corpse = "",
    maxDamage = 500,
    mass = 500,
    buildCostEnergy = 5000,
    buildCostMetal = 5000,
    canMove = true,
    buildPic = "SocialEngineeringIcon.png",
    iconType = "BribeIcon",
    explodeAs = "none",
    Acceleration = 0.1,
    BrakeRate = 1.0,
    TurnRate = 90000,
    MaxVelocity = 1.0,
    alwaysupright = true,
    MovementClass = "Default2x2",
    CanFly   = true,
    useSmoothMesh = true,
    alwaysUpright = true,
    buildTime =    60, --seconds
    --
    description = "Engineer a social movement/ protest",
    levelGround = false,
    CanAttack = false,
    CanGuard = false,
    name = "Social Engineering",
    CanMove = true,
    CanPatrol = true,
    CanStop = true,
    script = "socialEngineeringScript.lua",
    objectName = "socialEngineeringIcon.dae",
    onoffable = true,
    activatewhenbuilt = true,
    MaxSlope = 100,

    customparams = {
        helptext = "Icon",
        baseclass = "Abstract" -- TODO: hacks
    },
    category = "NOTARGET ABSTRACT"
}



local CyberCrime =
    Abstract:New {
    corpse = "",
    maxDamage = 500,
    mass = 500,
    buildCostEnergy = 0,
    buildCostMetal =   50,
    canMove = true,
    buildPic = "CyberCrimeIcon.png",
    iconType = "BribeIcon",
    explodeAs = "none",
    Acceleration = 0,
    BrakeRate = 0,
    TurnRate = 0,
    MaxVelocity = 0,
    buildingMask = 8,
    --
    description = " earn crypto for the cause via illicit means. Crime does pay.",
    levelGround = false,
    CanAttack = false,
    CanGuard = false,
    name = "Cybercrime",
    CanMove = true,
    CanPatrol = true,
    CanStop = true,
    script = "CyberCrimeIconScript.lua",
    objectName = "cybercrimeicon.dae",
    onoffable = true,
    activatewhenbuilt = true,
    MaxSlope = 100,
    buildTime =    30, --seconds

    customparams = {
        helptext = "Sniper/Raid Icon",
        baseclass = "Abstract" -- TODO: hacks
    },
    category = "NOTARGET ABSTRACT"
}
return lowerkeys(
    {
        --Temp
        ["doubleagent"] = DoubleAgent:New(),
        ["interrogationicon"] = InterrogationIcon:New(),
        ["stealmotorbike"] = StealMotorbike:New(),
        ["raidicon"] = RaidIcon:New(),
        ["recruitcivilian"] = RecruitCivilian:New(),
        ["snipeicon"] = SnipeIcon:New(),
        ["bribeicon"] = BribeIcon:New(),
        ["socialengineeringicon"] = SocialEngineering:New(),
        ["objectiveicon"] = ObjectiveIcon:New(),
        ["cybercrimeicon"] = CyberCrime:New(),
        ["destroyedobjectiveicon"] = DestroyedObjective:New()
    }
)
