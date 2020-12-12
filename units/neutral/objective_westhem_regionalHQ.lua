local objective_westhemhq = Building:New{
    corpse = "",
    maxDamage = 15000,
    mass = 500,
    buildCostEnergy = 5,
    buildCostMetal = 5,
    explodeAs = "none",
    name = "Western Hemisphere Alliance",
    description = "Regional HeadQuarters ",
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
        normaltex = "unittextures/component_atlas_normal.dds",
        helptext = "Civilian Building",
        baseclass = "Building", -- TODO: hacks
    },
    
    buildoptions =
    {
        "civilian_arab0"
    },
    usepiececollisionvolumes = false,
    collisionVolumeType = "box",
    collisionvolumescales = "130 900 130",
    category = [[GROUND BUILDING]],
    
}

return lowerkeys({
    --Temp
["objective_westhemhq"] = objective_westhemhq:New()})
