local objective_combatoutpost = Building:New{
    corpse = "",
    maxDamage = 15000,
    mass = 500,
    buildCostEnergy = 5,
    buildCostMetal = 5,
    explodeAs = "none",
    name = "Combat Outpost",
    description = "winning hearts and minds ",
    buildPic = "house.png",
    iconType = "house",
    Builder = false,
    levelground = true,
    FootprintX = 8,
    FootprintZ = 8,
    script = "objectivecombatoutpostscript.lua",
    objectName = "objective_combatOutpost.dae",
    
    YardMap = [[oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo]], 
    
    customparams = {
        normaltex = "unittextures/CheckPoint_normal.dds",
        helptext = "Civilian Building",
        baseclass = "Building", -- TODO: hacks
    },

    weapons = {
        [1]={name  = "ak47",
            onlyTargetCategory = [[GROUND BUILDING]],
            turret = true
            },  
        [2]={name  = "ak47",
            onlyTargetCategory = [[GROUND BUILDING]],
            turret = true
            },  
        [3]={name  = "ak47",
            onlyTargetCategory = [[GROUND BUILDING]],
            turret = true
            },  
        [4]={name  = "ak47",
            onlyTargetCategory = [[GROUND BUILDING]],
            turret = true
            },  
        },

    buildoptions =
    {
        "civilian_arab0"
    },
    usepiececollisionvolumes = false,
    collisionVolumeType = "box",
    collisionvolumescales = "130 130 130",
    category = [[GROUND BUILDING]],
    
}

return lowerkeys({
    --Temp
["objective_combatoutpost"] = objective_combatoutpost:New()})
