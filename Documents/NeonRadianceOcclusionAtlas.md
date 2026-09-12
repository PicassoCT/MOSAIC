# Neon radiance building-script voxel atlas

Buildings opt in with `customParams.throwsShadow = true`. Once their procedural
build is stable, they notify the gadget:

```lua
GG.MarkBuildingShadowVolumeDirty(unitID)
```

The gadget calls `GetBuildingShadowVoxels()` in that unit's script environment.
The function returns a dense array of model-local voxel centers in elmos, then
the common voxel edge length:

```lua
function GetBuildingShadowVoxels()
    return {
        {x = -8, y = 8, z = 0},
        {x =  8, y = 8, z = 0},
    }, 16
end
```

The Asian, Arab and Western building scripts currently include
`scripts/lib_building_voxels.lua`. Its placeholder returns 64 cells forming a
solid 64-elmo cube: X/Z bounds -32 to 32, Y bounds 0 to 64, with 16-elmo cells.
Replace the provider in each building script with an array describing the
assembled building. Model-local positions already include any desired piece
placement; no piece matrix or DAE transform is applied by the consumer.

The gadget accepts at most 16000 cells and requires finite coordinates and a
positive finite edge length. Invalid results remove the previous occluder.
An empty array clears the geometry. Dirty notifications in one frame coalesce.
Notify again after changing the supplied geometry or the building's transform;
do not notify every frame.

The array remains in synced Lua. The gadget forwards only primitive arguments:

```text
buildingShadowVoxelBegin(unitID, unitDefID, voxelSize)
buildingShadowVoxelAdd(unitID, x, y, z)
...
buildingShadowVoxelEnd(unitID)
```

LuaUI assembles the array and transforms its centers to world space using the
unit's base position and orientation. Existing atlas rendering uses sixteen
512x512 slices over world Y=0 through Y=2048. Destruction removes the occluder.
There is no DAE loading, mesh parsing, or triangle voxelization.

Select a completed building and use `/radiancedebug voxels`, or specify
`/radiancedebug voxels UNITID`. The cyan overlay shows the script-supplied cells;
the label shows their count and size. `/radiancedebug voxels off` hides it.
`radiancedebug volumes` remains an alias.

The disabled Recoil shader framework is unrelated to this interface and remains
disabled.
