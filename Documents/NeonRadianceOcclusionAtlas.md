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

## Prepared next step: authored structural boxes

`VoxelizeBuildingBoxes(boxes, voxelSize)` converts script-authored axis-aligned
boxes to the same array format. Each box has `minX`, `minY`, `minZ`, `maxX`,
`maxY`, `maxZ` in model-local elmos. The grid is anchored at the model origin.
Intersected cells are filled; overlaps are deduplicated. Empty space between
separate boxes remains empty. Non-grid-aligned edges can expand by less than
one cell on each side.

The helper preflights all boxes and limits total candidate cell visits to
100000, including overlaps. It separately limits output to 16000 cells and
input to 256 boxes. Invalid input or budget overflow returns `nil, error`;
partial geometry is never returned. It reads no engine geometry and does not
change the shader framework. The placeholder cube now exercises this helper
and still returns the same 64 cells.

Example provider for a small L-shaped footprint:

```lua
function GetBuildingShadowVoxels()
    local size = 16
    local voxels, err = VoxelizeBuildingBoxes({
        {minX=0, minY=0, minZ=0, maxX=64, maxY=64, maxZ=32},
        {minX=0, minY=0, minZ=0, maxX=32, maxY=64, maxZ=64},
    }, size)
    assert(voxels, err)
    return voxels, size
end
```

### Asian-house integration checkpoint

The assembly script uses `cubeDim.length = 770` and `cubeDim.heigth = 595.4`.
These are assembly coordinates, not yet verified as the final model-local
elmos required by this interface. Do not copy them into voxel bounds or infer
scale from the DAE.

Before replacing the Asian placeholder:

1. Verify one placed structural tile's origin, width and floor height against
   the rendered building and the engine collision-volume overlay (Alt+V).
2. Record a box only after successful structural placement in
   `buildDecorateGroundLvl` and `buildDecorateLvl`; record roof thickness
   separately in `addRoofDeocrate`. Exclude yard props, holograms and animations.
3. Reset the recorded boxes before procedural rebuilding; supply the array
   after assembly settles using the existing dirty notification.
4. Check two different floor plans, a rotated house and a reconstructed house
   with `/radiancedebug voxels UNITID`. Verify scale, roof height and empty
   courtyards before extending the provider to Arab and Western houses.

Run `lua tests/building_voxels.lua` from the repository root to check the helper
without the engine. This does not replace the placement checks above.
