-- Run from the repository root with Lua 5.1+; no engine required.
dofile("scripts/lib_building_voxels.lua")
local function box(a,b,c,d,e,f)
    return {minX=a,minY=b,minZ=c,maxX=d,maxY=e,maxZ=f}
end
local cube = box(-32,0,-32,32,64,32)
local cells, size = GetBuildingShadowVoxels()
assert(#cells == 64 and size == 16)
local seen = {}
for _,v in ipairs(cells) do
    assert(v.x >= -24 and v.x <= 24 and v.y >= 8 and v.y <= 56 and v.z >= -24 and v.z <= 24)
    local k = v.x .. ':' .. v.y .. ':' .. v.z
    assert(not seen[k]); seen[k] = true
end
assert(#VoxelizeBuildingBoxes({cube,cube},16) == 64)
assert(#VoxelizeBuildingBoxes({},16) == 0)
-- Two perpendicular wings retain the missing corner of an L-shaped floor.
cells = assert(VoxelizeBuildingBoxes({box(0,0,0,32,16,16),box(0,0,0,16,16,32)},16))
assert(#cells == 3)
for _,v in ipairs(cells) do assert(not(v.x==24 and v.z==24)) end
-- Conservative coverage, including coordinates on the negative side of zero.
cells = assert(VoxelizeBuildingBoxes({box(-1,0,-1,1,1,1)},16))
assert(#cells == 4)
local bad = {
    {cube,0}, {cube,0/0}, {box(0,0,0,0,1,1),16},
    {box(0,0,0,math.huge,1,1),16}, {cube,1e-300},
}
for _,input in ipairs(bad) do assert(VoxelizeBuildingBoxes({input[1]},input[2]) == nil) end
local _,err = VoxelizeBuildingBoxes({box(0,0,0,1000,1000,1000)},16)
assert(err == 'voxel work budget exceeded')
_,err = VoxelizeBuildingBoxes({box(0,0,0,416,416,416)},16)
assert(err == 'voxel cell limit exceeded')
-- Overlapping geometry must still consume the work budget.
local boxes = {}
for i=1,256 do boxes[i]=box(0,0,0,128,128,128) end
_,err = VoxelizeBuildingBoxes(boxes,16)
assert(err == 'voxel work budget exceeded')
print('PASS: cube compatibility, overlaps, empty geometry, L-shaped floor, negative bounds, invalid inputs, work and cell caps')
