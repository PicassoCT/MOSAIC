local unitName = "air_copter_blackhawk"

local blackHawk = VTOL:New{
    name = "Blackhawk",
    Description = "attack helicopter that can transport personal",
    objectName = "air_copter_blackhawk.dae",
    script = "air_black_hawk_script.lua",
    --buildPic = "chunterchopper.png",
    --cost
    buildCostMetal = 260,
    buildCostEnergy = 130,
    buildTime = 26,
    --Health
    maxDamage = 1950,
    idleAutoHeal = 0,
    --Movement
    Acceleration = 1.9,
    BrakeRate = 1,
    FootprintX = 3,
    FootprintZ = 3,

    steeringmode = [[1]],
    maneuverleashlength = 1380,
    turnRadius = 16,
    dontLand = false,
    MaxVelocity = 4.5,
    MaxWaterDepth = 0,
    MovementClass = "Default2x2",
    TurnRate = 250,
    nanocolor = [[0 0.9 0.9]],
    sightDistance = 500,
    airstrafe = true,
    factoryHeadingTakeoff = true,
    Builder = false,
    --canHover=true,
    CanAttack = true,
    CanGuard = true,
    CanMove = true,
    CanPatrol = true,
    Canstop = true,
     --alt
    LeaveTracks = false,
    cruiseAlt = 165,
    CanFly = true,
    ActivateWhenBuilt = 1,
    --maxBank=0.4,
    myGravity = 0.5,
    mass = 1900,
    canSubmerge = false,
    useSmoothMesh = false,
    collide = true,
    --crashDrag =0.1,
    --airHoverFactor=0.1,
    airStrafe = true,
    hoverAttack = true,
    verticalSpeed = 2.0,
    factoryHeadingTakeoff = false,
    strafeToAttack = true,
    customParams = {
        baseclass = "AIRCRAFT",
        normaltex = "unittextures/air_copter_blackhawk_normal.dds"
    },
    Category = [[AIR]],
    --explodeAs="citadelldrone",
    --selfDestructAs="cartdarkmat",
    ShowNanoSpray = false,
    CanBeAssisted = false,
    CanReclaim = false,
    customParams = {},
    sfxtypes = {
        explosiongenerators = {
            "custom:chopperdirt",
             --1024
            "custom:choppermuzzle",
            "custom:flyinggrass",
            "custom:blackerthensmoke",
             --1027
            "custom:330rlexplode"
         --1028
        }
    },
    weapons = {
        [1] = {
            name = "cgunshipmg",
            onlyTargetCategory = [[ LAND]],
            MainDir = [[0 0 1]],
            MaxAngleDif = 90
        }
    }
}

return lowerkeys({[unitName] = blackHawk:New()})
