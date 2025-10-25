local AIR_F35 =
    AIRCRAFT:New {
    name = "F35 Fighterjet",
    Description = " ",
    objectName = "air_plane_F35.dae",
    script = "airplanefighterjetscript.lua",
    buildPic = "air_sniper.png",
    iconType = "air_sniper",
    --floater = true,
    --cost
    buildCostMetal = 15000,
    buildCostEnergy = 10000,
    buildTime = 4 * 60,
    --Health
    maxDamage = 1500,
    idleAutoHeal = 0,
    --Movement

    fireState = -1,
    BrakeRate = 1,
    FootprintX = 1,
    FootprintZ = 1,
    ActivateWhenBuilt = 0,
    maxBank = 0.4,
    myGravity = 0.5,
    mass = 1225,
    cruiseAlt = 512,
    steeringmode = [[1]],
    maneuverleashlength = 1380,
    turnRadius = 8,
    dontLand = true,
    Acceleration = 2.5,
    MaxVelocity = 16.0,
    MaxWaterDepth = 0,
    MovementClass = "AIRUNIT",
    TurnRate = 350,
    nanocolor = [[0.20 0.411 0.611]],
    sightDistance = 600,
    CanFly = true,
    activateWhenBuilt = true,
    MaxSlope = 75,
    --canHover=true,

    CanAttack = true,
    CanGuard = true,
    CanMove = true,
    CanPatrol = true,
    Canstop = false,
    onOffable = false,
    LeaveTracks = false,
    canSubmerge = false,
    useSmoothMesh = true,
    collide = false,
    canCrash = true,
    crashDrag = 0.035,
    fireState = 1,
    Category = [[AIR]],
    noChaseCategory = "ABSTRACT",
    customParams = {
        baseclass = "vtol",
        normaltex = "unittextures/component_atlas_normal.dds"
    },
    weapons = {
        [1] = {
            name = "s16rocket",
            onlyTargetCategory = [[AIR]],
            turret = false
        },
        [2] = {
            name = "s16rocket",
            onlyTargetCategory = [[GROUND BUILDING]],
            turret = false
        }
    }
}

return lowerkeys(
    {
        ["air_plane_fighterjet"] = AIR_F35:New()
    }
)
