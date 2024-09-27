local objective_westhemhq = Building:New{
    corpse = "",
    maxDamage = 15000,
    mass = 500,
    buildCostEnergy = 5,
    buildCostMetal = 5,
    explodeAs = "none",
    name = "UNATO Arcologie ",
    description = " ",
    buildPic = "house.png",
    iconType = "house",
    Builder = false,
    levelground = true,
    FootprintX = 8,
    FootprintZ = 8,
    script = "objectiveWestHemHQ.lua",
    objectName = "objective_westhemhq.dae",
    
    YardMap = [[oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo
                    oooooooo]], 
    
    customparams = {
        ormaltex = "unittextures/house_asian_normal.dds",
        helptext = "Civilian Building",
        baseclass = "Building", -- TODO: hacks
    },
    
    buildoptions =
    {
        "civilian_arab0"
    },
    usepiececollisionvolumes = false,
    collisionVolumeType = "box",
    collisionvolumescales = "130 200 130",
    category = [[GROUND BUILDING]],
    
}

return lowerkeys({
    --Temp
["objective_westhemhq"] = objective_westhemhq:New()})
