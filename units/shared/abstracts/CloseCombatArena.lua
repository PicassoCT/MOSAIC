local CloseCombatArena =
    Abstract:New {
    corpse = "",
    maxDamage = 6666,
    mass = 500,
    buildCostEnergy = 5,
    buildCostMetal = 5,
    explodeAs = "none",

    --
    upright  = true,
    name = "Fight - target to break up",
    levelGround = false,
    Acceleration = 0.05,
    BrakeRate = 0.3,
    TurnRate = 300,
    MaxVelocity = 0.3575,
    transportSize = 9000,
    transportCapacity = 16,
    transportMass = 9000,
    usepiececollisionvolumes = false,
    collisionVolumeType = "box",
    collisionvolumescales = "50 50 50",

    isFirePlatform  = false, 
    canMove = true,
    holdSteady = true,
    cantBeTransported = true,
    releaseHeld = true,
    movementClass       = "QUADRUPED",
    script = "closeCombatArenascript.lua",
    objectName = "closeCombatArena.s3o",
    sightDistance = 50,
    minCloakDistance = 0,
  
    customparams = {
        helptext = "Civilian Agent working for the opposite site",
        baseclass = "Human" ,-- TODO: hacks
        normaltex = "unittextures/testtex2.dds",
    },
    category = "GROUND"
}

return lowerkeys(
    {
        --Temp
        ["closecombatarena"] = CloseCombatArena:New()
    }
)
