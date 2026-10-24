-- The delivery pack is permanent torso geometry, so existing bag, phone and
-- protest states cannot hide it. Travel still uses ordinary civilian pathfinding.
local Courier = Civilian:New{
    name = "Foot courier",
    description = "Civilian delivery courier <colateral>",
    objectName = "civilian_courier_asian.dae",
    corpse = "bodybag",
    mass = 80,
    usepiececollisionvolumes = false,
    collisionVolumeType = "box",
    collisionvolumescales = "10 25 10",
    pushResistant = false,
    buildPic = "civilian_courier_asian.png",
    iconType = "civilian",
    customParams = {
        baseclass = "Civilian",
        normaltex = "unittextures/civ_occupations_normal.png",
        civilian_role = "courier",
        civilian_culture = "asian",
        civilian_gender = "female",
    },
    category = [[GROUND ARRESTABLE CLOSECOMBATABLE]],
}

return lowerkeys({civilian_courier_asian = Courier})
