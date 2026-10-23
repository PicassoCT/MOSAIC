-- Physical roof bounds for the single initial-city skyline calculation.
local M = {}
local abs, max = math.abs, math.max
local function finite(value)
    return type(value) == "number" and value == value and abs(value) < math.huge
end

function M.SelectedRoof(spring, unitID, pieces)
    if type(pieces) ~= "table" then return end
    local _, unitY = spring.GetUnitPosition(unitID)
    local front, up, right = spring.GetUnitVectors(unitID)
    if not finite(unitY) or not front or not up or not right
        or not finite(front[2]) or not finite(up[2]) or not finite(right[2]) then return end
    local roof, seen = nil, {}
    for _, pieceID in pairs(pieces) do
        if not finite(pieceID) or pieceID < 0 or pieceID ~= math.floor(pieceID) then return end
        if not seen[pieceID] then
            seen[pieceID] = true
            local info = spring.GetUnitPieceInfo(unitID, pieceID)
            if not info or not info.min or not info.max then return end
            if not info.isEmpty then
                local matrix = {spring.GetUnitPieceMatrix(unitID, pieceID)}
                for axis = 1, 3 do
                    if not finite(info.min[axis]) or not finite(info.max[axis])
                        or info.min[axis] > info.max[axis] then return end
                end
                for i = 1, 16 do if not finite(matrix[i]) then return end end
                -- Import scale and ancestor transforms are already in this
                -- matrix. Apply the unit basis exactly once afterward.
                local a = -right[2]*matrix[1] + up[2]*matrix[2] + front[2]*matrix[3]
                local b = -right[2]*matrix[5] + up[2]*matrix[6] + front[2]*matrix[7]
                local c = -right[2]*matrix[9] + up[2]*matrix[10] + front[2]*matrix[11]
                local top = unitY - right[2]*matrix[13] + up[2]*matrix[14] + front[2]*matrix[15]
                    + a*(a < 0 and info.min[1] or info.max[1])
                    + b*(b < 0 and info.min[2] or info.max[2])
                    + c*(c < 0 and info.min[3] or info.max[3])
                if not finite(top) then return end
                roof = max(roof or top, top)
            end
        end
    end
    return roof
end

-- Only whole static buildings may use model envelopes. A procedural model
-- contains unselected variants and must never contribute its library bounds.
function M.ModelRoof(spring, unitID)
    local _, unitY, _, _, midY = spring.GetUnitPosition(unitID, true)
    if not finite(unitY) then return end
    local height, radius = spring.GetUnitHeight(unitID), spring.GetUnitRadius(unitID)
    local roof = finite(height) and unitY + max(0, height) or unitY
    if finite(radius) then roof = max(roof, (finite(midY) and midY or unitY) + max(0, radius)) end
    return roof
end

-- Unexpected malformed selected geometry gets a one-time physical collision
-- envelope rather than the potentially enormous hidden-variant model.
function M.CollisionRoof(spring, unitID)
    local _, unitY, _, _, midY = spring.GetUnitPosition(unitID, true)
    local sx, sy, sz, ox, oy, oz = spring.GetUnitCollisionVolumeData(unitID)
    local front, up, right = spring.GetUnitVectors(unitID)
    if not finite(unitY) or not finite(midY) or not front or not up or not right then return end
    if not (finite(sx) and finite(sy) and finite(sz) and finite(ox) and finite(oy) and finite(oz)
        and finite(front[2]) and finite(up[2]) and finite(right[2])) then return end
    return max(unitY,midY) - right[2]*ox + up[2]*oy + front[2]*oz
        + (abs(right[2]*sx)+abs(up[2]*sy)+abs(front[2]*sz))*.5
end

return M
