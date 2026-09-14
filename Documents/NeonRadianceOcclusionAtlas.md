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

The emission source samples the registered neon pieces' model diffuse RGB.
Both the previews and the scene pass below consume this coloured field. The day/night-scaled panel may be
black in daylight while the unit-intensity panel remains useful for debugging.

Refresh is bounded to 5 Hz. Cascade work depends on fixed texture/probe counts,
not a separate ray pass for every emitter. Four cascade buffers plus three 512x512
resolve buffers (including the independent scene-band cache) use about 8 MiB of additional RGBA16F texel storage, excluding
driver overhead. No previous-frame radiance feedback is retained, so removing
an emitter clears its illumination at the next refresh. The three old direct
diagnostic passes run only when their view is selected. Shader/FBO setup failure
cleans up propagation resources and falls back to the existing diagnostics.

`WG.NeonRadiance` exposes `texture` (day/night scaled), `unitTexture`,
`ready`, `heightMin`, `heightMax`, `mapSizeX` and `mapSizeZ` for other
consumers. UV is world X/Z divided by map X/Z size. Only sample while `ready` is
true; the widget owns and deletes these textures and removes its WG entry on
shutdown. Scene lighting uses unit-intensity radiance and applies day/night once
in its own composition shader.

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


### Emitter inspection and thin-surface capture

Select a registered neon building, then use:

- `/radiancedebug zoom`: center all four panels on its first registered emitter
  in a 1024-elmo square, and select the height band containing the piece origin.
  With no selection, use the current emitter (or the first registered emitter).
- `/radiancedebug zoom 512`: choose a smaller world-space window (minimum 128).
- `/radiancedebug emitter UNITID PIECEID`: inspect a particular registered piece;
  omit PIECEID to use that unit's first emitter.
- `/radiancedebug exposure 8`: change preview exposure (0.125–64, default 4).
- `/radiancedebug zoom off`: restore the whole-map view.
- `/radiancedebug height 128`: manually override the captured height band.

All four panels use the same UV crop. A green cross marks the emitter piece
origin, which may differ from the center of its geometry. Crops clamp at map
edges without changing their world-space size. Radiance previews use
`1-exp(-radiance*exposure)`; occupancy remains a raw binary view. Exposure and
zoom do not change the propagation textures exposed through WG.NeonRadiance.

The emission geometry shader clips triangles to the selected height band,
then widens projected surfaces thinner than two atlas texels into a narrow
ribbon. Broad triangles retain their original footprint. This makes vertical
billboard faces visible to top-down capture without amplifying source intensity.
It is a conservative approximation: thin faces can extend by about one atlas
texel on either side. It needs no extra textures or scene capture passes, but
adds geometry-shader work to the existing capture. Validate performance in-game.

Capture uses registered whole-piece geometry and its base colour texture.
Animated hologram interference, view-dependent effects and transparency pulses
are not reproduced in the emission atlas.
Self-illuminated house pieces could use this capture path once registered as
sources; selective glowing windows on a shared wall mesh need an emission mask.
That registration/masking extension is not implemented by this change.


### Coloured scene lighting

The scene pass is enabled by default with strength 2 and world height 0–128.
It adds propagated RGB illumination to visible surfaces in that band. The scene
band is independent of debug emitter selection, zoom, exposure and preview band.
This remains a single horizontal height band, not full 3D or multi-bounce GI.
Surfaces outside the selected scene band receive no contribution.

In daytime, test the effect with `/radiancelight test on`, then turn that override
off again. A persistent on-screen label marks full-intensity testing, including
when the diagnostic panels are hidden.

| Command | Effect |
| --- | --- |
| `/radiancelight on` / `/radiancelight off` | Enable/disable scene lighting for comparison |
| `/radiancelight test on` / `/radiancelight test off` | Override scene night intensity to 1 / restore the game clock |
| `/radiancelight strength 2` | Artistic scene gain, clamped to 0–8; unrelated to preview exposure |
| `/radiancelight height 128` | Select scene band 128–256; default is height 0 |
| `/radiancedebug off` / `/radiancedebug on` | Hide/show diagnostic panels without disabling lighting |

Coloured emission uses the same `%unitDefID:0` model texture as the hologram
renderer. Broad surfaces interpolate texture UVs; widened edge-on faces use
several samples over the clipped face to average the collapsed vertical colour
variation. Black texels do not emit. Texture alpha is deliberately ignored,
matching the existing hologram renderer's use of RGB rather than diffuse alpha.
Missing model texture bindings retain the previous white-source fallback.

Composition prefers the engine's map/model depth, normal and diffuse buffers.
It chooses the closer opaque receiver, reconstructs its world position using the
engine inverse matrices, checks map/height bounds, and samples radiance outside
wall columns along their outward normal. Occupied samples remain dark. It adds
`(1-exp(-radiance*strength))*nightIntensity*albedo` with ONE/ONE blending.
Preview exposure is never used. No scene colour is read from the render target,
and sky, below-water geometry and receivers outside the scene band are skipped.

If deferred buffers/settings are unavailable, a depth-only screen copy provides
positions and derivative normals with a neutral 0.5 reflectance approximation.
This avoids redrawing terrain/models and does not change engine configuration.
Transparent surfaces absent from depth/G-buffers have no independent lighting
receiver. This is approximate diffuse illumination, without BRDF directionality
or material-correct colour-space conversion; tune its appearance in Recoil.

The preferred path allocates no screen-size textures. The depth fallback owns
one DEPTH_COMPONENT24 texture, conservatively budgeted at four bytes per pixel:
about 8 MiB at 1920×1080, capped at 16 MiB. Unsupported/failed allocations disable
only composition and leave previews usable; failed sizes are not retried every
frame. Resize and shutdown release owned resources.

When scene and preview bands match, they share the existing cascade solve.
Inspecting another preview band performs one additional capture and solve at
5 Hz into a fixed 512×512 RGBA16F scene cache (2 MiB, included in the 8 MiB above).
The scene shader draws once per frame and skips work at zero night intensity.
Return the preview to the scene band for representative performance comparisons.

The GPU suite checks coloured broad/edge-on sources, RGB propagation, receiver
selection, sky/height/occupancy rejection, both clip-depth conventions and depth
fallback. Lua checks cover scene toggles, independent bands, buffer reuse,
viewport offsets, allocation limits, resize/failure recovery and GL cleanup.
Recoil/NVIDIA visual validation is still required for this composition stage.

### Camera-local detail and wall-aware reconstruction

Scene lighting now enables a camera-local field and spatial smoothing by default.
The existing DrawWorld composition path is retained from the working version;
the later experimental screen-effects diagnostics are not included.

The centre camera ray selects a ground focus. Near views use a 1024-elmo square
with a 1024² emission capture, 512² occupancy capture, 128² base probes and a
512² resolved field: 1-elmo emission texels, 2-elmo occupancy/lighting cells and
8-elmo probe spacing. Medium views cover 2048 elmos at the same texture sizes.
Distant views or a camera ray that misses the ground use only the whole-map field.

The domain moves in whole probe steps (also whole emission/occupancy texels),
and zoom thresholds have hysteresis to reduce switching. Map-edge clamping keeps
the domain inside the map. Domain metadata is published only after its capture
and solve finish, so the compositor never combines old pixels with a new origin.

Rays use fine emission/occupancy inside the patch and the current scene-band
whole-map captures outside it. They retain the whole-map world-space cascade
intervals, so lights outside the patch can still contribute. Marching remains
bounded by the existing 256-step limit: distant small features remain approximate.
Scene and preview height bands stay independent; the local solve runs while the
whole-map emission texture still contains the scene band, before a different
preview band overwrites that texture.

Composition samples the fine field in the centre and fades to the whole-map
field over the outer 18% of the patch. Each field uses its own occupancy-cell
size for wall-normal offsets. Wall-aware bilinear filtering rejects occupied
sample centres and connectors crossing occupancy before renormalizing weights;
simply enabling hardware linear filtering would leak light through walls.

| Command | Effect |
| --- | --- |
| `/radiancelight detail off` / `detail on` | Compare the whole-map field with automatic camera-local detail |
| `/radiancelight smooth off` / `smooth on` | Compare nearest sampling with wall-aware reconstruction |

The diagnostic status displays the active local span and cell size. Existing
preview panels still show the whole-map solve (cropping them does not switch
their source texture); the finer field is used by actual scene lighting.

Local detail allocates lazily on the first near-camera solve and reuses fixed
textures: four 256² RGBA16F cascades, one 512² RGBA16F resolve, a 1024² RGBA8
emission capture and a 512² RGBA8 occupancy capture. This adds about 9 MiB of
texel storage, excluding driver/shader overhead. Allocation failure disables
local detail and retains whole-map lighting. Zooming out reuses the allocation
later rather than churning GPU objects; shutdown releases it.

The extra capture and solve run at the existing 5 Hz refresh, adding two capture
passes and five cascade/resolve passes while local detail is active. This is
bounded work, but it still costs GPU time; use detail off for comparison.

Regression cases were added for external-patch sources and blockers, smoothing
across walls, centre/border blending, domain snapping, zoom hysteresis, map edges,
scene-band routing, texture reuse and cleanup. The changed Lua files were syntax
parsed during implementation. The execution environment was unavailable, so the
new Lua lifecycle and GPU tests have NOT been run here. Run both before merging:

```sh
lua5.4 tests/neon_radiance_lifecycle.lua
python3 tests/neon_radiance_gpu.py
```

The GPU command uses the previously tested NVIDIA/GLFW compatibility-context
setup. Headless Mesa requires the documented --context egl variant.
