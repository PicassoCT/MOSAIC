# Direct exterior window light prototype

Branch: `prototype/standalone-direct-windows`, based on master `f2e9fa8b`.
The previous implementation remains on `prototype/standalone-taper-emission`,
fast-forwarded to that same master revision before this fork. No taper renderer,
taper shader, taper command or window-line cascade injection remains on the
direct branch. No shader framework or DAE voxelization system is introduced.

## In-game check

`house_asian1` and `house_asian3` activate automatically once their building
animation finishes, following the normal neon day/night intensity. For daytime
testing, use `/windowlight test on`; `/windowlight test off` restores that cycle.
The first view needs a cache warm-up; geometry capture is limited to one building
per 0.2-second update, and each ground-light bake is split across 16 chunks. Shared
blocker packing and baking start after the pending captures finish, since each
capture changes the blocker set and would discard any intermediate bake.

Select a completed standalone and run:

```text
/windowlight debug on
```

The selected building's actual luminous wall pixels are overlaid green when
classified exterior, red when rejected by the courtyard mask. The upper-right
panel shows its direct ground-light field, or cache/bake progress while waiting.
The overlay classifies the actual mesh; green does not guarantee a sample was
visible in one of the four side captures. The overlay does not deform geometry.
Debug views are hidden by default.

Compare `/windowlight off` with `/windowlight auto`. For an isolated building use
`/windowlight on` with that house selected. The usual `/radiancedebug` panels
continue to show the cascade; window light intentionally does not appear there.

| Command | Effect |
| --- | --- |
| `/windowlight auto` | Both standalone definitions, automatic discovery |
| `/windowlight on [UNITID]` | One selected/specified eligible building |
| `/windowlight off` | Disable direct window illumination |
| `/windowlight debug on/off` | Window classification overlay and field preview |
| `/windowlight status` | Log selected unit, luminous pixels, bounds, bake progress, field peak and cumulative work counters |
| `/windowlight test on/off` | Full daytime testing / normal neon day-night curve |
| `/windowlight strength 1` | Final direct-field gain, clamped to 0–8 |
| `/windowlight range 640` | Maximum horizontal reach in elmos, 64–1024 |
| `/windowlight cutoff 0.002` | Smooth fade threshold for accumulated building light |
| `/windowlight rebuild` | Explicitly invalidate cached captures and fields |

## Rendering path

1. Render the actual visible model into four **untapered side views**. Texture 2
   red gates emission and alpha gates coverage. Opaque unlit geometry writes
   depth. A dominant-normal rule assigns each wall to only one view. Each lit
   sample retains original world position, horizontal normal and represented
   surface area. Before any capture, transform the selected facade pieces' mesh
   bounds through their actual piece and unit matrices. The script publishes the
   piece list after construction; hidden variants and distant street furniture
   cannot dilute the facade into a fraction of a pixel. Restart the game after
   updating so unit scripts publish this metadata.
2. Rasterize wall barriers in four horizontal height bands. Ignore horizontal
   roofs/floors so a courtyard floor cannot turn its yard into a solid mask.
   Conservatively thicken edge-on walls, then flood-fill empty pixels from the
   mask boundary using four-neighbour connectivity. This rejects enclosed yards
   and enclosed interior spaces while retaining street-connected recesses.
3. Accept a window only when a small step in front of its original normal reaches
   that band's exterior region. The model itself is unchanged. Readback occurs
   only during capture; the implementation probes the engine's `ReadPixels`
   table layout to prevent rotated/transposed classification.
4. Project each accepted area sample into a bounded terrain field. Weight by
   window facing, terrain normal, true vertical separation and squared distance,
   with a bounded near-field approximation. Fade reach smoothly. A much smaller
   per-sample discard threshold bounds total omitted energy; the visible cutoff
   is applied after a building's faint windows have added together.
5. Check the source building's detailed wall masks and the existing 16-layer
   building occupancy, plus terrain height, along the source-to-ground segment.
   Cached standalone masks are also added to the packed world blockers.
   For the first 1.5 coarse cells, detailed self-walls and terrain do the blocking;
   the world occupancy test starts farther out, avoiding false self-shadowing
   from a coarse raster cell extending outside its emitting wall. Other buildings
   within that small bias region are an approximation limit.
6. Add completed fields to a separate HDR atlas. `radiance_scene.lua` consumes
   this atlas at composition, before the existing tone response/albedo multiply.
   It does not enter propagation, fog-emitter metadata or the cascade solve.
   Deferred model pixels are excluded, preventing the ground field from appearing
   on roofs. Terrain outside the cascade's selected height band can still receive it.

## Lifetime and cost

The standalone script publishes `mosaic_window_revision`: zero during construction,
positive after showing the house, negative when hidden. Show/hide invalidates the
capture; death and LOS loss remove cached sources at the 5 Hz refresh. The module
also exposes `Invalidate(id)` for future users of this rendering helper. Spinning
decorations are not continuously recaptured; this prototype targets static facades.
The explicit rebuild command remains available for manual model changes.

Ground-height changes and building-occupancy changes invalidate lighting bakes.
Their previous completed light remains visible until a replacement is ready.
Adding or removing a camera-selected facade mask only invalidates fields whose
projection footprints overlap that mask, padded by one coarse blocker texel.
Removal events for units that never supplied blockers, and empty updates for
absent blockers, leave bakes running. View culling retains its conservative radius
after capture so small houses near the screen edge cannot repeatedly evict and
recapture themselves, resetting every building's bake.
Day/night and strength changes reuse the captured sources and completed fields.
One shared work field holds the current 16-chunk bake. Its texture handle swaps
with the house's completed field when the bake finishes, without a GPU copy.
The active house keeps that work field across camera-priority changes. Cold
caches publish completed houses progressively. Warm replacement batches retain
the existing combined atlas until completion, instead of re-adding every retained
house after each individual completion. Source removals update it immediately at
the normal refresh boundary.
The per-frame bake queue becomes idle when all fields are complete. Normal daytime
and zero strength skip window GPU work; debug overlays remain opt-in.
Changing range/cutoff explicitly rebuilds the caches. Partially baked fields are
never displayed. A genuine blocker change can temporarily display the previous
completed shadow solution during its replacement bake.

Up to 32 nearby, view-intersecting eligible buildings are cached. Approximate
texture payload at that limit is 45.75 MiB: two 256×64 RGBA32F captures, two 64×64
RGBA8 masks and a 256×256 RGBA16F ground field per building; a 1024-square HDR
atlas, 256-square terrain heights, a packed 2048-square R8 blocker atlas, and
one shared 256-square RGBA16F staging field. Staging adds 0.5 MiB to the previous
45.25 MiB payload; these figures exclude driver/FBO metadata and allocation padding.
Capture FBOs/depth targets are temporary. Source-point lists are shared. The selected
house is prioritized for capture and baking, so it cannot lose its place to 32
nearer houses. Diagnostics show captured light pixels and fitted bounds; an empty
capture is reported instead of silently retrying and starving the other houses.
No GPU readback, model recapture, blocker packing or atlas rendering occurs for
an unchanged warm cache at constant intensity. The final scene still samples the
cached atlas. During a warm replacement, the existing scene enable uniform now
carries the ratio of current to published gain. This keeps the normal night fade
moving without an atlas redraw each refresh. The old per-house cutoff shape is
retained only while the ratio stays within 0.8–1.25. Larger changes, explicit
strength changes, removals and batch completion recompose the exact cutoff.
Outside a replacement batch, fades continue updating the atlas as before.
The scene uses the same texture samples, pass and number of uniform updates;
scaling its nonnegative window sample replaces the previous max-with-zero.

The mocked lifecycle fixture measured 100 atlas redraws over 100 unchanged refreshes
before the cache cleanup, and zero afterward. Two pending houses now require one
blocker pack and exactly 32 bake chunks, with no discarded startup chunks. The
`work since load` line from `/windowlight status` reports capture, bake-chunk,
blocker-pack and atlas-update totals for checking this in-game. Status itself
still performs an explicit field readback to report peak intensity.

Continuity/cost fixtures compare the production module with the pre-fix module.
A constant-gain 32-house blocker rebuild keeps all 512 projection chunks but
reduces atlas passes from 32 to 1 and house copies from 528 to 32. A 20-second
fixture using the real night curve reduces copies from 2016 to 896, with the
same projection workload. Small removals and exact brightness reclassification
can require a few additional copies to retain surviving light. The comparison
reports these explicit budgets; `--strict-cost` rejects all such increases.
See [cache-continuity validation](window-lighting-cache-continuity-validation.md)
for complete results and target-hardware limitations.

This is not yet a measured performance claim on the target GPU. A full synthetic
building bake took about 3.6 seconds on software Mesa at the fixture's 128-square
field size, which motivated chunking. Real-model capture stalls, warm-up time and
steady-state performance still require an in-game check on Recoil/NVIDIA.

## Approximation limits

* A U-shaped/open courtyard is connected to the street and is intentionally
  considered outside. Strict exclusion of such yards needs authored exclusions.
* Four side views can miss windows occluded by overhangs or other parts of a
  deeply recessed facade. The classification overlay helps distinguish selection
  from capture visibility. It is not a promise of exhaustive surface extraction.
* Four wall bands, a coarse terrain height texture and the existing occupancy
  bands approximate geometry. Thin blockers, overhangs, small passages and roof
  occlusion along downward rays are not represented exactly. Detailed self-walls
  are checked over the model's full fitted height; world blockers above 2048
  elmos remain outside the existing occupancy range.
* Output is direct **terrain** illumination. It does not light other buildings,
  water, fog or rain reflections in this prototype. With the depth-copy fallback,
  matching reconstructed height to the terrain replaces deferred model rejection.
* These are diffuse area-light footprints, not sharp indoor-projector images of
  window frames. No secondary bounce or additional propagation is performed.

## Verification

```text
python3 tests/window_lighting_gpu.py
lua tests/window_bounds.lua
lua tests/window_exterior.lua
lua tests/window_lighting_lifecycle.lua
lua tests/window_lighting_continuity.lua
lua tests/neon_radiance_lifecycle.lua
lua tests/fog_radiance_heights.lua
```

`texlua` also runs the Lua fixtures. The GPU fixture invokes Lua/texlua for the
production flood fill and checks actual barrier rasterization, closed/open yards,
untapered positions, Recoil/legacy clip depth, direct projection, source height,
wall shadowing, cutoff fading, one-time scene addition, roof rejection and terrain
outside the cascade band. Lifecycle tests cover every allocation failure, both
engine pixel-readback layouts, cache reuse, revision changes, LOS, terrain updates,
bake completion during unrelated unit removals and screen-edge visibility checks,
real blocker invalidation, unchanged-atlas reuse, gain changes, capture batching,
and cleanup. The continuity fixture additionally covers completed-field ownership,
warm replacement, source removal, real night fades, transient LOS/cloak changes,
and shutdown/re-enable. Exterior ground-light spill has been confirmed in-game; the cache
optimizations still need target-GPU profiling before claiming an FPS improvement.
