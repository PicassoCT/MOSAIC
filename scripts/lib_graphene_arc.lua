-- Shared by the live parachute and /smokeribbon <piece> electric.
-- The mesh ribbons retain their original colours and animation; these are
-- the white-core, cyan electrical discharges rising from their outer tips.
local M = {}

function M.Options(seed, rootOffset)
    return {
        mode = 'electric', rootOffset = rootOffset or {0, 0, 0},
        directionSpace = 'world', direction = {0, 1, 0},
        length = 190, width = 18, strands = 4,
        curl = 0.8, speed = 1.8, windInfluence = 0.08,
        colorStart = {0.8, 0.96, 1, 0.95},
        colorEnd = {0.22, 0.7, 1, 0},
        emission = {4.2, 1.6}, sourceGlow = {0.15, 0.72, 1, 0.4},
        distanceFactor = 30, drawInIcon = true,
        seed = seed,
    }
end

function M.OuterTip(unitID, piece)
    local info = Spring.GetUnitPieceInfo(unitID, piece)
    if not info or not info.min or not info.max then return {0, 0, 0} end
    -- Rotator meshes end at their +Y/+Z bounds. Their pivots coincide, so
    -- attaching to the pivots stacked every discharge in the same place.
    -- Piece bounds preserve the asset's scale and the animated piece matrix
    -- carries this local tip with its own rotating sheet.
    return {(info.min[1] + info.max[1]) * 0.5, info.max[2], info.max[3]}
end

return M
