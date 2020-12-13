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
    name = "DoubleAgent",
    description = "Activate to turn sides",
    levelGround = false,
    CanAttack = false,
    CanGuard = false,
    CanMove = true,
    CanPatrol = true,
    CanStop = true,
    script = "doubleagentscript.lua",
    objectName = "doubleagent.s3o",
    buildPic = "doubleagent.png",
    iconType = "doubleagent",
    canCloak = true,
    cloakCost = 0.0001,
    ActivateWhenBuilt = 1,
    cloakCostMoving = 0.0001,
    minCloakDistance = 0,
    onoffable = true,
    initCloaked = true,
    decloakOnFire = true,
    cloakTimeout = 5,
    onoffable = true,
    activatewhenbuilt = true,
    customparams = {
        helptext = "Civilian Agent working for the opposite site",
        baseclass = "Human" -- TODO: hacks
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
        baseclass = "Human" -- TODO: hacks
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
    canCloak = true,
    cloakCost = 0.0001,
    ActivateWhenBuilt = 1,
    cloakCostMoving = 0.0001,
    minCloakDistance = 0,
    onoffable = true,
    initCloaked = true,
    decloakOnFire = true,
    cloakTimeout = 5,
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

return lowerkeys(
    {
        --Temp
        ["doubleagent"] = DoubleAgent:New(),
        ["interrogationicon"] = InterrogationIcon:New(),
        ["raidicon"] = RaidIcon:New(),
        ["recruitcivilian"] = RecruitCivilian:New(),
        ["snipeicon"] = SnipeIcon:New(),
        ["objectiveicon"] = ObjectiveIcon:New()
    }
)
