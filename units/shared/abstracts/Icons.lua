local DeadDropIcon =
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
    upright  = true,
    name = "Dead Drop",
    description = "Contains the secrets of a betrayed operative. Drive over to collect",
    levelGround = false,
    CanAttack = false,
    CanGuard = false,
    CanMove = false,
    CanPatrol = false,
    CanStop = false,
    script = "DeadDropScript.lua",
    objectName = "DeadDrop.dae",
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

local HiJackSatteliteIcon =
    Abstract:New {
    corpse = "",
    maxDamage = 15000,
    mass = 500,
    buildCostEnergy = 5,
    buildCostMetal = 5,
    buildTime = 5*60,
    canMove = true,
    explodeAs = "none",
    Acceleration = 0,
    BrakeRate = 0,
    TurnRate = 0,
    MaxVelocity = 0,
    --
    upright  = true,
    name = "Satellite Override",
    description = "hijacks a satellite",
    levelGround = false,
    CanAttack = false,
    CanGuard = false,
    CanMove = false,
    CanPatrol = false,
    CanStop = false,
    script = "HiJackSatteliteIconscript.lua",
    objectName = "HijackSatteliteIcon.dae",
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
    upright  = true,
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
    upright  = true,
    name = "DoubleAgent",
    description = "switches as Double Agent to your side by decloaking",
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

local ElectronicCounterMeasureIcon =
    Abstract:New {
    corpse = "",
    maxDamage = 500,
    mass = 500,
    buildCostEnergy = 1000,
    buildCostMetal = 1500,
    canMove = true,
    explodeAs = "none",
    Acceleration = 0.1,
    BrakeRate = 1.0,
    TurnRate = 90000,
    MaxVelocity = 66.6,
    MovementClass = "VEHICLE",
    --
    upright  = true,
    name = "Electronic Counter Measure",
    description = "Destroys a software entity of the enemy",
    levelGround = false,
    CanAttack = true,
    CanGuard = false,
    CanMove = true,
    CanPatrol = true,
    CanStop = true,
    script = "ecmscript.lua",
    objectName = "ecm.dae",
    buildPic = "placeholder.png",
    iconType = "placeholder",
    canCloak = false,
    sightDistance = 50,
    onOffable = true,

    MaxSlope = 100,

    customparams = {
        helptext = "Software to undo enemy software",
        baseclass = "Abstract" ,-- TODO: hacks
        normaltex = "unittextures/component_atlas_normal.dds",
    },

    weapons = {
            [1]={name  = "marker",
                onlyTargetCategory = [[ABSTRACT]],
                },
            },  

    category = "NOTARGET ABSTRACT"
}

local RevealDoubleAgentsIcon =
    Abstract:New {
    corpse = "",
    maxDamage = 500,
    mass = 500,
    buildCostEnergy = 500,
    buildCostMetal = 1000,
    canMove = true,
    explodeAs = "none",
    Acceleration = 0,
    BrakeRate = 0,
    TurnRate = 0,
    MaxVelocity = 0,
    --
    upright  = true,
    name = "Reveal DoubleAgents",
    description = "forces double-agents to switch team",
    levelGround = false,
    CanAttack = false,
    CanGuard = false,
    CanMove = false,
    CanPatrol = false,
    CanStop = false,
    script = "revealdoubleagentscript.lua",
    objectName = "doubleagent.dae",
    buildPic = "doubleagent.png",
    iconType = "doubleagent",
    canCloak = true,
    cloakCost = 0.0001,
    cloakCostMoving = 0.0001,
    sightDistance = 50,
    minCloakDistance = 0,
    activatewhenbuilt = false,
    initCloaked = true,
    onOffable = true,
    decloakOnFire = false,

    customparams = {
        helptext = "",
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
    description = "- recruits a civilian for your side",
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

local StealVehicle =
    Abstract:New {
    maxDamage = 500,
    mass = 500,
    buildCostEnergy = 0,
    buildCostMetal = 250,
    explodeAs = "none",
    --orders
    buildTime = 1.0,
    script = "stealVehicleScript.lua",
    objectName = "stealVehicleIcon.dae",
    buildPic = "StealVehicleIcon.png",
    iconType = "stealvehicleicon",
    --
    name = "Steal Vehicle",
    description = "carjack a civilian vehicle",
    -- Hack Infrastructure
    --CommandUnits (+10 Units)
    -- WithinCellsInterlinked (Recruit)
    buildtime = 2,

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
    iconType = "icon_raid",
    ActivateWhenBuilt = 1,
    onoffable = true,
    activatewhenbuilt = true,
    customparams = {
        helptext = "Civilian Agent working for the opposite site",
        baseclass = "Human", -- TODO: hacks
    },
    category = "NOTARGET"
}

local RaidIconBasePlate =
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
    collisionvolumescales = "100 10 100",
    -- name = "Raid Location",
    -- description = "a raid of a location is in Progress",

    CanAttack = false,
    CanGuard = false,
    CanMove = true,
    CanPatrol = true,
    CanStop = true,
    script = "raidicon_baseplatescript.lua",
    objectName = "RaidIcon_BasePlate.dae",
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
    canCloak = false,
    decloakOnFire = true,
    initCloaked = false,
    script = "interrogationIconScript.lua",
    objectName = "InterrogationIcon.dae",
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
    buildCostEnergy = 2500,
    buildCostMetal = 2500,
    canMove = true,
    buildPic = "BribeIcon.png",
    iconType = "BribeIcon",
    explodeAs = "none",
    Acceleration = 0.1,
    BrakeRate = 1.0,
    TurnRate = 90000,
    MaxVelocity = 1.0,
    MovementClass = "VEHICLE",
    CanFly   = true,
    useSmoothMesh = true,
    upright  = true,
    upright  = true,
    --
    description = "Bribe police to investigate this location instead",
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
        helptext = "Bribe local authoritys into action ",
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
    upright  = true,
    MovementClass = "VEHICLE",
    CanFly   = true,
    useSmoothMesh = true,
    upright  = true,
    buildTime =    60, --seconds
    --
    description = "Social network agitator created protest",
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

local BlackOutIcon =
    Abstract:New {
    corpse = "",
    maxDamage = 500,
    mass = 500,
    buildCostEnergy = 5000,
    buildCostMetal = 5000,
    canMove = true,
    buildPic = "BlackOutIcon.png",
    iconType = "Placeholder",
    explodeAs = "none",
    Acceleration = 0.1,
    BrakeRate = 1.0,
    TurnRate = 90000,
    MaxVelocity = 1.0,
    upright  = true,
    MovementClass = "VEHICLE",
    CanFly   = true,
    useSmoothMesh = true,
    buildTime =    120, --seconds
    --
    description = "Prevents commands in area",
    levelGround = false,
    CanAttack = false,
    CanGuard = false,
    name = "Communication Blackout",
    CanMove = true,
    CanPatrol = true,
    CanStop = true,
    script = "blackoutscript.lua",
    objectName = "BlackOutIcon.dae",
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
    buildingMask = 8,

    --
    description = " earns crypto for you. Crime does pay.",
    levelGround = false,
    CanAttack = false,
    CanGuard = false,
    name = "Botnet Node",
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
        ["icon_hijacksatellite"] = HiJackSatteliteIcon:New(),
        ["icon_emc"] = ElectronicCounterMeasureIcon:New(),
        ["revealdoubleagent"] = RevealDoubleAgentsIcon:New(),
        ["doubleagent"] = DoubleAgent:New(),
        ["interrogationicon"] = InterrogationIcon:New(),
        ["stealvehicleicon"] = StealVehicle:New(),
        ["icon_raid"] = RaidIcon:New(),
        ["raidiconbaseplate"] = RaidIconBasePlate:New(),
        ["recruitcivilian"] = RecruitCivilian:New(),
        ["snipeicon"] = SnipeIcon:New(),
        ["icon_bribe"] = BribeIcon:New(),
        ["icon_socialengineering"] = SocialEngineering:New(),
        ["objectiveicon"] = ObjectiveIcon:New(),
        ["icon_cybercrime"] = CyberCrime:New(),
        ["destroyedobjectiveicon"] = DestroyedObjective:New(),
        ["deaddropicon"] = DeadDropIcon:New(),
        ["icon_blackout"] = BlackOutIcon:New()
    }
)
