-- Place an authored ruin cap on settled structural geometry. All bounds are
-- measured in unit-model space, so unit heading and import scale cancel out.
local M = {}
local identity = {1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1}

local function bounds(unit, piece)
    local info = Spring.GetUnitPieceInfo(unit, piece)
    local matrix = {Spring.GetUnitPieceMatrix(unit, piece)}
    if not (info and info.min and info.max and #matrix == 16) then return end
    local low, high = {}, {}
    for axis = 1, 3 do
        local center, extent = matrix[12+axis], 0
        for coord = 1, 3 do
            local basis = matrix[(coord-1)*4+axis]
            center = center + basis*(info.min[coord]+info.max[coord])*0.5
            extent = extent + math.abs(basis)*(info.max[coord]-info.min[coord])*0.5
        end
        low[axis], high[axis] = center-extent, center+extent
    end
    return low, high
end

local function inverseVector(m, x, y, z)
    local a,b,c, d,e,f, g,h,i = m[1],m[5],m[9], m[2],m[6],m[10], m[3],m[7],m[11]
    local det = a*(e*i-f*h)-b*(d*i-f*g)+c*(d*h-e*g)
    if math.abs(det) < 1e-12 then return end
    return ((e*i-f*h)*x+(c*h-b*i)*y+(b*f-c*e)*z)/det,
        ((f*g-d*i)*x+(a*i-c*g)*y+(c*d-a*f)*z)/det,
        ((d*h-e*g)*x+(b*g-a*h)*y+(a*e-b*d)*z)/det
end

function M.Place(unit, piece, column, visible, nativeMove, nativeTurn)
    if not Spring.GetUnitPieceMatrix then return false end
    local topLow, topHigh
    for _, block in ipairs(column) do
        if visible[block.piece] then
            local low, high = bounds(unit, block.piece)
            if high and (not topHigh or high[2] > topHigh[2]) then
                topLow, topHigh = low, high
            end
        end
    end
    if not topHigh then return false end
    local info = Spring.GetUnitPieceInfo(unit, piece)
    if not info then return false end
    local parent = Spring.GetUnitPieceMap(unit)[info.parent]
    local parentMatrix = parent and {Spring.GetUnitPieceMatrix(unit, parent)} or identity
    if #parentMatrix ~= 16 then return false end
    -- Turn operates in the piece's authored axes, which need not match its
    -- parent's axes (western ruin caps import with a 90-degree X rotation).
    -- Reset first so a previous placement's yaw cannot affect this measurement.
    for axis = 1, 3 do
        nativeMove(piece, axis, 0, 0)
        nativeTurn(piece, axis, 0, 0)
    end
    local pieceMatrix = {Spring.GetUnitPieceMatrix(unit, piece)}
    if #pieceMatrix ~= 16 then return false end
    local upAxis, score = 2, -1
    for axis = 1, 3 do
        local index = (axis-1)*4
        local length = math.sqrt(pieceMatrix[index+1]^2+pieceMatrix[index+2]^2+pieceMatrix[index+3]^2)
        local candidate = length > 0 and math.abs(pieceMatrix[index+2])/length or 0
        if candidate > score then upAxis, score = axis, candidate end
    end
    -- Private repeatable randomness avoids perturbing construction/gameplay RNG.
    local seed = (unit*65537+piece*8191) % 2147483647
    local yaw = ((seed*48271) % 2147483647)/2147483647 * 2*math.pi
    nativeTurn(piece, upAxis, yaw, 0)
    -- Measure after rotation: off-centre mesh origins must not orbit the column.
    local low, high = bounds(unit, piece)
    if not high then return false end
    local x,y,z = inverseVector(parentMatrix,
        (topLow[1]+topHigh[1]-low[1]-high[1])*0.5,
        topHigh[2]-low[2],
        (topLow[3]+topHigh[3]-low[3]-high[3])*0.5)
    if not x then return false end
    nativeMove(piece, 1, x, 0)
    nativeMove(piece, 2, y, 0)
    nativeMove(piece, 3, z, 0)
    return true
end

return M
