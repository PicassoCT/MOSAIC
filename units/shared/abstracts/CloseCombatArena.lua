local CloseCombatArena =
    Abstract:New {
    corpse = "",
    maxDamage = 500,
    mass = 500,
    buildCostEnergy = 5,
    buildCostMetal = 5,
    explodeAs = "none",

    --
    alwaysUpright = true,
    name = "CloseCombatArena",
    levelGround = false,
    transportSize = 16,
    transportCapacity = 2,
    isFirePlatform  = false, 

    script = "closeCombatArenascript.lua",
    objectName = "CloseCombatArena.dae",
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
