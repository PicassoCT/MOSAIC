local unitName = "radiancedebuglamp"

local unitDef = {
    name = "Radiance Debug Lamp",
    Description = "Hopping full-spectrum radiance shadow test fixture",
    objectName = "radiance_debug_lamp.dae",
    script = "radianceDebugLampScript.lua",
    buildPic = "placeholder.png",

    buildCostMetal = 1,
    buildCostEnergy = 1,
    buildTime = 1,
    maxDamage = 500,
    idleAutoHeal = 0,

    footprintX = 1,
    footprintZ = 1,
    maxSlope = 90,
    maxWaterDepth = 0,
    sightDistance = 120,

    blocking = false,
    pushResistant = true,
    reclaimable = false,
    upright = true,
    levelGround = false,
    canMove = false,
    canAttack = false,
    canGuard = false,
    canPatrol = false,
    canStop = true,
    leaveTracks = false,
    useSmoothMesh = false,

    customParams = {
        radiance_debug = "1",
    },

    Category = [[GROUND]],
}

return lowerkeys({ [unitName] = unitDef })
