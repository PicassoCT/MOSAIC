-- Building-script interface: return a dense array of model-local voxel centers
-- ({x=..., y=..., z=...}, in elmos), followed by their common edge length.
-- Replace this placeholder in each building script with its authored voxel array.
function GetBuildingShadowVoxels()
    local voxels = {}
    local voxelSize = 16
    -- Solid 64-elmo cube, centered on X/Z, resting at model-local Y=0.
    for x = -24, 24, voxelSize do
        for y = 8, 56, voxelSize do
            for z = -24, 24, voxelSize do
                voxels[#voxels + 1] = {x = x, y = y, z = z}
            end
        end
    end
    return voxels, voxelSize
end
