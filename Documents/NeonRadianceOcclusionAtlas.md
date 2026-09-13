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
initializeBuildingShadowVoxels(cubeDim.length, cubeDim.heigth, scriptToModelScale)
```

The existing placement hooks stay unchanged:

```lua
addShadowVoxel(xRealLoc, zRealLoc, floorBaseY)
```

The optional third initializer argument converts script movement units into
model-local elmos at the getter. It defaults to 1. The current Asian and Western
DAEs declare `asset/unit meter="0.025400"`, so their scripts pass 0.0254;
the Arab DAE declares 1.0 and keeps the default. The conversion applies once to
cell size, floor height, grid origins and terrain bases, never to occupancy
counts or masks. The gadget, atlas and debug overlay all consume the converted
geometry. There is no runtime DAE parsing. Update this constant if the DAE unit
metadata changes. Expected six-cell footprint widths are 117.348 elmos (Asian),
127.28448 (Western) and 125.28 (Arab), rather than 4620/5011.2 for the first two.

Despite its legacy name, this records one occupied floor in a compact column.
It does not generate subvoxels. X/Z identify the block center; Y identifies its
base, in the same script movement units used by the building's placement calls. Blocks must share a horizontal grid and a floor spacing within each
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


## Occlusion-aware radiance propagation

The widget now runs four 2D radiance cascades coarse-to-fine, using emission from
all registered neon pieces and the selected occupancy height band. The old
unreferenced `topDownNeonLightRadianceCascadeShader.frag` remains unused; the live
implementation is in `shaders/radiancecascade/propagate.frag` and `resolve.frag`,
managed by `include/radiance_propagation.lua`.

Default preview panels:

1. Neon geometry emission at unit intensity, filtered to the selected height band.
2. Building occupancy in that band.
3. Propagated radiance at unit intensity.
4. The same result with day/night neon intensity applied once.

Controls:

- `/radiancedebug propagation`: show the propagation panels (default).
- `/radiancedebug direct`: return to the original single-emitter diagnostics.
- `/radiancedebug height 128`: select the occupancy band containing world Y=128.
  Bands remain 128 elmos tall; the default is Y=0 through Y=128.
- Existing voxel/volume overlay and direct-emitter clearance commands remain.

Each cascade has a 256x256 RGBA16F texture. Probe resolution halves per axis
while angular resolution quadruples (4, 16, 64, 256 directions). Non-overlapping
distance intervals grow by four; their total range is 85 times the base interval
(two emission texels on the shorter map axis). For an 8192x8192 map this is
1360 elmos. Near and far intervals merge as `Lnear + Tnear * Lfar`, with
transmittance multiplied. Occupied samples terminate propagation. Emitting
samples take priority over occupancy at the same surface.

Parent interpolation tests visibility to parent interval entry points, and
resolve interpolation tests visibility to its neighboring probes. This avoids
the solid-wall leakage seen with plain bilinear merging. It is still a finite
resolution approximation: thin geometry and angular detail require in-engine
evaluation. This is single-band, direct radiance transport, not 3D multi-bounce GI.

The emission source is the existing untextured neon-piece geometry capture, so
the preview is currently monochrome. Actual hologram material colors and scene
lighting composition are subsequent steps. The day/night-scaled panel may be
black in daylight while the unit-intensity panel remains useful for debugging.

Refresh is bounded to 5 Hz. Cascade work depends on fixed texture/probe counts,
not a separate ray pass for every emitter. Four cascade buffers plus two 512x512
resolve buffers use about 6 MiB of additional RGBA16F texel storage, excluding
driver overhead. No previous-frame radiance feedback is retained, so removing
an emitter clears its illumination at the next refresh. The three old direct
diagnostic passes run only when their view is selected. Shader/FBO setup failure
cleans up propagation resources and falls back to the existing diagnostics.

`WG.NeonRadiance` exposes `texture` (day/night scaled), `unitTexture`,
`ready`, `heightMin`, `heightMax`, `mapSizeX` and `mapSizeZ` for a future scene
consumer. UV is world X/Z divided by map X/Z size. Only sample while `ready` is
true; the widget owns and deletes these textures and removes its WG entry on
shutdown. No scene overlay is applied in this stage.

Additional checks, from repository root:

```sh
lua5.4 tests/neon_radiance_lifecycle.lua
python3 -m pip install numpy moderngl glfw
python3 tests/neon_radiance_gpu.py
# Headless Mesa CI only:
MESA_GL_VERSION_OVERRIDE=3.3COMPAT python3 tests/neon_radiance_gpu.py --context egl
```

The GPU test defaults to a hidden GLFW window with an explicit OpenGL 3.3
compatibility profile, including on NVIDIA. Run it from a graphical desktop.
The optional EGL mode is for headless Mesa CI; the Mesa profile override does
not configure NVIDIA's driver. The test verifies the profile before drawing,
reports the driver and per-cascade output, and checks GL errors at every draw.
It compiles the actual GLSL in a compatibility context and exercises propagation, wall rejection, visibility
merging, intensity, source removal and emission-band clipping. The lifecycle
test checks coarse-to-fine ordering, absence of render-target feedback, texture
bindings and cleanup at each shader/texture allocation failure. These checks
do not substitute for Recoil driver/performance and visual testing.

