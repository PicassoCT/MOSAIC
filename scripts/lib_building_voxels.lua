-- Compact building shadow geometry. No expanded voxel arrays are retained.
-- Public placement hook stays addShadowVoxel(x, z, baseY), in model-local elmos.
local cells = {}
local cellSize, levelHeight
local originX, originZ
local minX, maxX, minZ, maxZ
local MAX_LEVELS = 30

local function finite(n)
    return type(n) == "number" and n == n and math.abs(n) < math.huge
end

function initializeBuildingShadowVoxels(length, height)
    assert(finite(length) and length > 0 and finite(height) and height > 0)
    cellSize, levelHeight = length, height
    cells = {}
    originX, originZ, minX, maxX, minZ, maxZ = nil, nil, nil, nil, nil, nil
end

local function gridIndex(value)
    local index = math.floor(value + 0.5)
    assert(math.abs(value - index) < 0.00001, "Shadow block is not aligned to the floor grid")
    return index
end

function addShadowVoxel(x, z, y)
    assert(cellSize and finite(x) and finite(z) and finite(y))
    if not originX then originX, originZ = x, z end
    local ix, iz = gridIndex((x - originX) / cellSize), gridIndex((z - originZ) / cellSize)
    local row = cells[ix]
    if not row then row = {}; cells[ix] = row end
    local cell = row[iz]
    if not cell then
        cell = {base = y, mask = 0, levels = 0}
        row[iz] = cell
    end
    local level = gridIndex((y - cell.base) / levelHeight)
    if level < 0 then
        assert(cell.levels - level <= MAX_LEVELS, "Too many shadow levels")
        cell.mask = cell.mask * 2 ^ (-level)
        cell.levels = cell.levels - level
        cell.base, level = y, 0
    end
    assert(level < MAX_LEVELS, "Too many shadow levels")
    local bit = 2 ^ level
    if math.floor(cell.mask / bit) % 2 == 0 then cell.mask = cell.mask + bit end
    cell.levels = math.max(cell.levels, level + 1)
    minX, maxX = math.min(minX or ix, ix), math.max(maxX or ix, ix)
    minZ, maxZ = math.min(minZ or iz, iz), math.max(maxZ or iz, iz)
end

-- Normal case: 2D height array plus two dimensions. Optional sparse tables
-- preserve terrain offsets and missing intermediate floors without voxelization.
function GetBuildingShadowColumns()
    local result = {columns = {}, cellSize = cellSize or 16, levelHeight = levelHeight or 16}
    if not minX then return result end
    result.originX = originX + minX * cellSize
    result.originZ = originZ + minZ * cellSize
    for ix = minX, maxX do
        local outX = ix - minX + 1
        local row = {}
        result.columns[outX] = row
        for iz = minZ, maxZ do
            local outZ = iz - minZ + 1
            local cell = cells[ix] and cells[ix][iz]
            row[outZ] = cell and cell.levels or 0
            if cell and cell.base ~= 0 then
                result.baseHeights = result.baseHeights or {}
                result.baseHeights[outX] = result.baseHeights[outX] or {}
                result.baseHeights[outX][outZ] = cell.base
            end
            if cell and cell.mask ~= 2 ^ cell.levels - 1 then
                result.masks = result.masks or {}
                result.masks[outX] = result.masks[outX] or {}
                result.masks[outX][outZ] = cell.mask
            end
        end
    end
    return result
end
