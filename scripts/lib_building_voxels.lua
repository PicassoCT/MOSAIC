local voxels
local shadowSubdivisions
local voxelSize
local blockLength
local blockHeight

-- Configure once per building script, before its placement hooks run.
-- Calling again clears previously accumulated cells.
function initializeBuildingShadowVoxels(length, height, subdivisions)
    subdivisions = subdivisions or 4
    assert(type(length) == "number" and length > 0 and length < math.huge)
    assert(type(height) == "number" and height > 0 and height < math.huge)
    assert(type(subdivisions) == "number" and subdivisions >= 1 and
           subdivisions < math.huge and subdivisions == math.floor(subdivisions))
    local size = length / subdivisions
    assert(height >= size, "Block height must be at least one voxel")
    blockLength, blockHeight = length, height
    shadowSubdivisions, voxelSize = subdivisions, size
    voxels = {}
end

-- Same placement contract as the build calls: X/Z are the block center,
-- Y is its base, all in model-local elmos. Fill the rectangular floor block
-- with common-sized cubes; never add the unit's world position here.
function addShadowVoxel(x, z, y)
    assert(voxels, "Initialize building shadow voxels before adding blocks")
    local layers = math.ceil(blockHeight / voxelSize)
    -- Fit both vertical bounds exactly. A small overlap between layers avoids
    -- gaps without extending the occluder below the floor or above its ceiling.
    local yStep = layers > 1 and (blockHeight - voxelSize) / (layers - 1) or 0
    local firstOffset = -blockLength / 2 + voxelSize / 2
    for ix = 0, shadowSubdivisions - 1 do
        for iz = 0, shadowSubdivisions - 1 do
            for iy = 0, layers - 1 do
                voxels[#voxels + 1] = {
                    x = x + firstOffset + ix * voxelSize,
                    y = y + voxelSize / 2 + iy * yStep,
                    z = z + firstOffset + iz * voxelSize,
                }
            end
        end
    end
end

function GetBuildingShadowVoxels()
    if voxels then return voxels, voxelSize end
    -- Preserve the original placeholder for buildings not yet configured.
    local placeholder = {}
    for x = -24, 24, 16 do
        for y = 8, 56, 16 do
            for z = -24, 24, 16 do
                placeholder[#placeholder + 1] = {x = x, y = y, z = z}
            end
        end
    end
    return placeholder, 16
end

