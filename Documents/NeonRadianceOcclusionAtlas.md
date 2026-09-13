# Compact building shadow columns

Buildings opt in with `customParams.throwsShadow = true`. After the procedural
build and its display animation finish, the script calls:

```lua
GG.MarkBuildingShadowVolumeDirty(unitID)
```

The gadget calls `GetBuildingShadowColumns()` in that unit's script environment.
The simplest provider returns a 2D height grid and two dimensions:

```lua
function GetBuildingShadowColumns()
    return {
        columns = {
            {3, 3, 2, 2},
            {3, 0, 0, 2},
            {3, 0, 0, 3},
            {3, 3, 3, 3},
        },
        cellSize = 20.88,
        levelHeight = 14.84,
    }
end
```

`columns[x][z]` is an integer number of floors. Zero is empty. Each occupied
column extends upward from model-local Y=0. `cellSize` is its X/Z width;
`levelHeight` is the floor height, both in model-local elmos. Without explicit
origins, the grid is centered on the unit's model origin. The array is dense and
rectangular, including zero cells for courtyards. An empty grid clears geometry.

Optional fields preserve more complicated buildings:

- `originX`, `originZ`: center of cell `[1][1]`, in model-local coordinates.
- `baseHeights[x][z]`: base Y of a column; omitted cells default to zero.
- `masks[x][z]`: occupancy mask overriding a column's contiguous floors. Bit zero
  is its bottom floor. For example, height 3 with mask 5 occupies floors 0 and 2,
  leaving floor 1 empty. The height must encompass all set bits. Omitted masks
  default to `2^levels - 1`.

## Procedural building hooks

The Arab, Asian and Western scripts include `scripts/lib_building_voxels.lua`.
At the start of each build they call:

```lua
initializeBuildingShadowVoxels(cubeDim.length, cubeDim.heigth)
```

The existing placement hooks stay unchanged:

```lua
addShadowVoxel(xRealLoc, zRealLoc, floorBaseY)
```

Despite its legacy name, this records one occupied floor in a compact column.
It does not generate subvoxels. X/Z identify the block center; Y identifies its
base. Blocks must share a horizontal grid and a floor spacing within each
column. Duplicate floor calls are idempotent; out-of-order floors, terrain base
heights and missing floors are preserved. Reinitializing clears previous data.
The getter produces the public grid with optional offsets/masks as needed.
Only successful structural floor/wall placement calls contribute geometry;
roof decorations and other placeables are not automatically solidified.

The standalone Asian script has an empty `GetBuildingShadowColumns()` provider,
a no-op geometry insertion hook and a no-op registration hook at completion.
No placeholder geometry or automatic registration is enabled for it. It needs
a separate authored representation later. Other unconfigured library users
also return an empty grid rather than the former placeholder cube.

## Transfer and rendering

The gadget validates a dense rectangular grid (at most 4096 cells, at most 30
floors per column), positive finite dimensions, finite coordinates and bounded
integer masks before sending anything. Invalid geometry removes the previous
occluder. Dirty notifications coalesce within a frame. Notify again after
changing geometry or the unit's transform, not every frame.

The sync boundary carries only primitive values:

```text
buildingShadowColumnsBegin(unitID, unitDefID, cellSize, levelHeight)
buildingShadowColumn(unitID, modelX, modelZ, baseY, occupancyMask)
...
buildingShadowColumnsEnd(unitID)
```

LuaUI retains four flat numbers per occupied column, plus one unit transform
per building. Consecutive occupied floors are rendered directly as prisms into
the existing sixteen 512x512 slices covering world Y=0 through Y=2048. The atlas
uses the unit's full position/orientation; projection is conservative for tilted
buildings. There is no persistent per-voxel geometry or per-prism draw closure.
Destroyed units and empty replacement grids remove stored geometry.

Select a completed building and use `/radiancedebug voxels`, or specify
`/radiancedebug voxels UNITID`. The legacy command now displays occupied column
runs as cyan boxes, including gaps and terrain offsets, and reports column
count, cell size and floor height. `/radiancedebug voxels off` hides it;
`radiancedebug volumes` remains an alias. Debug drawing does not expand cubes.

This changes the internal provider and transfer protocol: update scripts,
gadget and widget together and start a fresh game. There is no DAE loading or
runtime mesh voxelization. Baked roof/standalone geometry is future work.

## Regression check

From the repository root, run `lua5.4 tests/building_shadow_columns.lua`.
This exercises the real provider, gadget, unsynced forwarder and widget with
mocked engine/OpenGL calls. It covers masks, terrain offsets, input validation,
replacement/removal, primitive-only transfer, coalescing, rotated projection and
debug rendering. It does not replace an in-engine atlas/alignment check.
