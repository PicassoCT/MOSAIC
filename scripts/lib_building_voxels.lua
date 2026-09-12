-- Building scripts supply boxes already expressed in model-local elmos.
-- No meshes, piece transforms, or inferred scale are used here.
-- Returns a dense array of {x,y,z} voxel centers, or nil plus an error.
function VoxelizeBuildingBoxes(boxes, voxelSize)
    local MAX_BOXES, MAX_CELLS, MAX_CHECKS = 256, 16000, 100000
    local MAX_COORDINATE = 1000000
    local function finite(value)
        return type(value) == "number" and value == value and math.abs(value) < math.huge
    end
    if type(boxes) ~= "table" or #boxes > MAX_BOXES then
        return nil, "expected at most 256 boxes"
    end
    if not finite(voxelSize) or voxelSize <= 0 then
        return nil, "voxel size must be positive and finite"
    end

    -- Preflight every box before any rasterization. The work limit counts all
    -- candidate cells, including overlaps, not just newly occupied cells.
    local ranges, checks = {}, 0
    for i = 1, #boxes do
        local box = boxes[i]
        if type(box) ~= "table" then return nil, "invalid box " .. i end
        local range = {}
        for axis = 1, 3 do
            local key = ({"X", "Y", "Z"})[axis]
            local lo, hi = box["min" .. key], box["max" .. key]
            if not finite(lo) or not finite(hi) or math.abs(lo) > MAX_COORDINATE or
               math.abs(hi) > MAX_COORDINATE or lo >= hi then
                return nil, "invalid bounds for box " .. i
            end
            local first, last = math.floor(lo / voxelSize), math.ceil(hi / voxelSize) - 1
            if not finite(first) or not finite(last) or math.abs(first) > 1000000000 or
               math.abs(last) > 1000000000 then
                return nil, "voxel grid indices out of range"
            end
            range[axis] = {first, last}
        end
        local candidates = (range[1][2] - range[1][1] + 1) *
                           (range[2][2] - range[2][1] + 1) *
                           (range[3][2] - range[3][1] + 1)
        checks = checks + candidates
        if checks > MAX_CHECKS then return nil, "voxel work budget exceeded" end
        ranges[#ranges + 1] = range
    end

    local voxels, occupied = {}, {}
    for _, range in ipairs(ranges) do
        for x = range[1][1], range[1][2] do
            for y = range[2][1], range[2][2] do
                for z = range[3][1], range[3][2] do
                    local key = x .. ":" .. y .. ":" .. z
                    if not occupied[key] then
                        if #voxels >= MAX_CELLS then return nil, "voxel cell limit exceeded" end
                        occupied[key] = true
                        voxels[#voxels + 1] = {
                            x = (x + 0.5) * voxelSize,
                            y = (y + 0.5) * voxelSize,
                            z = (z + 0.5) * voxelSize,
                        }
                    end
                end
            end
        end
    end
    return voxels
end

-- Override this provider in each building script with its authored array or
-- VoxelizeBuildingBoxes(boxes, size). Bounds include min faces, exclude max
-- faces; intersected grid cells are filled conservatively and deduplicated.
function GetBuildingShadowVoxels()
    local voxelSize = 16
    local voxels, errorMessage = VoxelizeBuildingBoxes({
        {minX = -32, minY = 0, minZ = -32, maxX = 32, maxY = 64, maxZ = 32},
    }, voxelSize)
    assert(voxels, errorMessage)
    return voxels, voxelSize
end
