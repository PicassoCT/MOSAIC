-- Occupational variant of the ordinary civilian. The shared script preserves
-- daily life, prayer, panic, protest, arming and operative disguise behavior.
local Worker = Civilian:New{
    name = "Municipal worker",
    description = "Civilian maintenance worker <colateral>",
    objectName = "civilian_worker_western.dae",
    corpse = "bodybag",
    mass = 80,
    usepiececollisionvolumes = false,
    collisionVolumeType = "box",
    collisionvolumescales = "10 25 10",
    pushResistant = false,
    buildPic = "civilian_worker_western.png",
    iconType = "civilian",
    customParams = {
        baseclass = "Civilian",
        normaltex = "unittextures/civ_occupations_normal.png",
        civilian_role = "maintenance",
        civilian_culture = "western",
        civilian_gender = "male",
    },
    category = [[GROUND ARRESTABLE CLOSECOMBATABLE]],
}

return lowerkeys({civilian_worker_western = Worker})
