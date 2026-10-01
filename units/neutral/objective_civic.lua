-- Shared Asian-atlas prototypes. All gameplay uses the existing objective gadget.
local definitions = {}
for _, spec in ipairs(VFS.Include("luarules/configs/civic_objectives.lua")) do
    definitions[spec.name] = Building:New{
        name = spec.title,
        description = spec.description,
        objectName = spec.name .. ".dae",
        script = "objective_civic_script.lua",
        buildPic = spec.name .. ".png",
        iconType = "house",
        category = "GROUND BUILDING",
        maxDamage = 15000,
        mass = 500,
        buildCostEnergy = 5,
        buildCostMetal = 5,
        metalStorage = 0,
        builder = false,
        canMove = false,
        canAttack = false,
        levelGround = true,
        maxWaterDepth = 0,
        footprintX = 8,
        footprintZ = 8,
        yardMap = string.rep("o", 64),
        corpse = "",
        explodeAs = "none",
        selfDestructAs = "none",
        usePieceCollisionVolumes = false,
        collisionVolumeType = "box",
        collisionVolumeScales = "124 " .. spec.height .. " 124",
        collisionVolumeOffsets = "0 " .. (spec.height / 2) .. " 0",
        customparams = {
            normaltex = "unittextures/house_asian_normal.dds",
            helptext = spec.description .. "; defend or destroy as marked by the objective system",
            baseclass = "Building",
            civic_objective = true,
        },
    }
end
return lowerkeys(definitions)
