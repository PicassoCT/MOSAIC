local Observer =
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
    name = "Observer",
    description = "There to observe and then to die",
    levelGround = false,
    CanAttack = false,
    CanGuard = false,
    CanMove = true,
    CanPatrol = true,
    CanStop = true,
    script = "placeholderscript.lua",
    objectName = "placeholder.s3o",

    canCloak = true,
    cloakCost = 0.0001,
  
    initCloaked = true,
    decloakOnFire = true,
    cloakTimeout = 5,
    onoffable = true,
    activatewhenbuilt = true,
    customparams = {
        helptext =  "Observer spawned to show hidden Units",
        baseclass = "Human" -- TODO: hacks
    },
    category = "NOTARGET"
}

return lowerkeys(
    {
        --Temp
        ["observer"] = Observer:New()       
    }
)
