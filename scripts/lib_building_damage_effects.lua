-- Static facade geometry and FlamePainter style. The structural controller
-- owns visibility, the two shared fire/smoke slots and their fixed lifetimes.
local M = {}
local abs, sqrt = math.abs, math.sqrt
local spGetUnitPieceInfo = Spring.GetUnitPieceInfo
local spGetUnitPieceMatrix = Spring.GetUnitPieceMatrix
local spGetUnitPiecePosDir = Spring.GetUnitPiecePosDir
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitVectors = Spring.GetUnitVectors

local function finite(value)
    return type(value) == 'number' and value == value and abs(value) < math.huge
end

local function positive(value, fallback)
    return finite(value) and value > 0 and value or fallback
end

local function dot(a, b)
    return a[1]*b[1] + a[2]*b[2] + a[3]*b[3]
end

local function cross(a, b)
    return {a[2]*b[3]-a[3]*b[2], a[3]*b[1]-a[1]*b[3], a[1]*b[2]-a[2]*b[1]}
end

local function normalized(vector)
    local length = sqrt(dot(vector, vector))
    if length < 1e-9 then return nil end
    return {vector[1]/length, vector[2]/length, vector[3]/length}, length
end

local function facadeAnchor(unitID, piece, floorHeight, cellSize)
    if not (spGetUnitPieceInfo and spGetUnitPieceMatrix and spGetUnitVectors
        and spGetUnitPosition and spGetUnitPiecePosDir) then return end
    local info = spGetUnitPieceInfo(unitID, piece)
    local matrix = {spGetUnitPieceMatrix(unitID, piece)}
    local front, up, right = spGetUnitVectors(unitID)
    local ux, uy, uz, mx, my, mz = spGetUnitPosition(unitID, true)
    local ex, ey, ez = spGetUnitPiecePosDir(unitID, piece)
    if not (info and info.min and info.max and front and up and right
        and finite(ux) and finite(uy) and finite(uz)
        and finite(ex) and finite(ey) and finite(ez)) then return end
    for axis = 1, 3 do
        if not (finite(info.min[axis]) and finite(info.max[axis])
            and info.min[axis] <= info.max[axis]
            and finite(front[axis]) and finite(up[axis]) and finite(right[axis])) then return end
    end
    for index = 1, 16 do if not finite(matrix[index]) then return end end

    -- Match smoke_ribbon_renderer.pieceTransform, including its model-X
    -- handedness. The model matrix already contains the import scale.
    local function unitVector(x, y, z)
        return {-right[1]*x+up[1]*y+front[1]*z,
            -right[2]*x+up[2]*y+front[2]*z,
            -right[3]*x+up[3]*y+front[3]*z}
    end
    local basis = {unitVector(matrix[1], matrix[2], matrix[3]),
        unitVector(matrix[5], matrix[6], matrix[7]),
        unitVector(matrix[9], matrix[10], matrix[11])}
    local inverseRows = {cross(basis[2], basis[3]), cross(basis[3], basis[1]), cross(basis[1], basis[2])}
    local determinant = dot(basis[1], inverseRows[1])
    if abs(determinant) < 1e-12 then return end
    local normals, lengths = {}, {}
    for axis = 1, 3 do
        local row = inverseRows[axis]
        normals[axis] = normalized({row[1]/determinant, row[2]/determinant, row[3]/determinant})
        lengths[axis] = sqrt(dot(basis[axis], basis[axis]))
    end
    local pivot = unitVector(matrix[13], matrix[14], matrix[15])
    pivot[1], pivot[2], pivot[3] = pivot[1]+ux, pivot[2]+uy, pivot[3]+uz
    local center = {(info.min[1]+info.max[1])*.5,
        (info.min[2]+info.max[2])*.5, (info.min[3]+info.max[3])*.5}
    local worldCenter = {pivot[1], pivot[2], pivot[3]}
    for axis = 1, 3 do
        for coord = 1, 3 do worldCenter[coord] = worldCenter[coord]+basis[axis][coord]*center[axis] end
    end
    local outward = normalized({worldCenter[1]-(mx or ux), 0, worldCenter[3]-(mz or uz)})
    outward = outward or {1, 0, 0}
    -- Importers may use raw mesh Z as up. Pick the transformed top axis, then
    -- the horizontal face pointing away from the building's centre.
    local topAxis = 1
    for axis = 2, 3 do
        if abs(normals[axis][2]) > abs(normals[topAxis][2]) then topAxis = axis end
    end
    local faceAxis, faceScore
    for axis = 1, 3 do
        if axis ~= topAxis then
            local score = dot(normals[axis], outward)
            if not faceAxis or abs(score) > abs(faceScore) then faceAxis, faceScore = axis, score end
        end
    end
    local faceSign = faceScore < 0 and -1 or 1
    local topSign = normals[topAxis][2] < 0 and -1 or 1
    center[faceAxis] = (faceSign > 0 and info.max[faceAxis] or info.min[faceAxis])
        + faceSign*cellSize*.12/lengths[faceAxis]
    center[topAxis] = (topSign > 0 and info.max[topAxis] or info.min[topAxis])
        + topSign*floorHeight*.06/lengths[topAxis]
    local target = {pivot[1]-ex, pivot[2]-ey, pivot[3]-ez}
    for axis = 1, 3 do
        for coord = 1, 3 do target[coord] = target[coord]+basis[axis][coord]*center[axis] end
    end
    -- Recoil's GetUnitPiecePosDir uses the mesh's first vertex as its emitter
    -- position, not necessarily its pivot. rootOffset is an OFFSET from that
    -- emitter. Invert the basis once so the attachment stays on this facade
    -- through later settling/leaning, without adding the raw vertex twice.
    local rootOffset = {}
    for axis = 1, 3 do rootOffset[axis] = dot(target, inverseRows[axis])/determinant end
    local normal = normals[faceAxis]
    local direction = normalized({normal[1]*faceSign*.45, 1, normal[3]*faceSign*.45})
    return rootOffset, direction
end

function M.FlameOptions(unitID, piece, geometry)
    geometry = geometry or {}
    local scale = positive(geometry.modelScale, 1)
    local floorHeight = positive(geometry.floorHeight, 16)*scale
    local cellSize = positive(geometry.cellSize, 16)*scale
    local rootOffset, direction = facadeAnchor(unitID, piece, floorHeight, cellSize)
    return {
        directionSpace='world', direction=direction or {0,1,0}, rootOffset=rootOffset or {0,0,0},
        -- Two floor heights of flame, about half a facade cell wide. Scale is
        -- applied here once; the attachment matrix scales only rootOffset.
        length=floorHeight*2.2, width=cellSize*.55, strands=2, curl=.45, speed=1.8,
        windAffected=false, motionAffected=false,
        colorStart={1,.55,.18,.85}, colorEnd={.75,.08,.015,0},
        emission={2.5,.6}, sourceGlow={1,.42,.09,.3},
        distanceFactor=120,
    }
end

return M
