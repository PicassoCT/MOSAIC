# Shore bioluminescence

Dry nights now have blue-green swash along sandy shorelines. At maximum run-up,
each wave deposits a stationary, irregular line on the sand. The lines have a
six-second half-life and illuminate their surroundings through the existing
radiance cascade. The moving front and deposited contour share a shader phase.
Stock engine foam remains unchanged; this does not recolor or synchronize to
Recoil's private coast/foam textures.

Enabled automatically on Last Day of Dubai when its distribution texture is
present. The map's red splat channel is sand. Other maps can opt in with
`mapconfig/shore_bioluminescence.lua` returning
`{sandTexture='maps/my_sand_mask.png'}`; red must identify sand in world-map UVs.
There is no material-guessing fallback.

## Behavior and controls

- Uses the existing radiance day/night curve. Current rain smoothly suppresses
  glow between rain intensities 0.001 and 0.03; residual ground wetness does not.
- Missing rain provider fails closed, including reload intervals. Rain/day/off
  clears history once, so old deposits do not reappear the next night.
- Clock and history follow simulation time, including pause and rewind.
- Camera movement and window resize leave world-space history untouched.
- `/biowaves on` restores automatic dry-night behavior; `/biowaves off` disables it.
- `/biowaves test on` forces illumination regardless of weather/time for visual
  inspection. `/biowaves test off` restores automatic behavior.
- `/biowaves status` reports initialization progress, atlas size and intensity.

## Rendering and cost

The unsynced widget does a one-time, incremental height scan at 32-unit spacing.
Only tiles around water/land crossings are allocated. A GPU initialization pass
finds signed distance to actual water within 96 units and applies the sand,
slope and elevation masks. Initial mask construction is limited to one tile per
draw. Persistent GPU history lives in two R16F atlases; the static mask is RGBA16F.
One-texel overlap at tile edges prevents cross-tile filtering and seams.

Atlas dimensions never exceed 1088 by 1088: at most 13.55 MiB for these three
textures. Resolution adapts to coastline tile count; ordinary tiles use 4–8
world units per texel. Extremely fragmented maps can use coarser texels. Maps
exceeding the bounded atlas budget disable this effect with a diagnostic.

History updates at most once per draw and at 10 Hz of simulation time. Old
history decays analytically between updates. Dormant history performs no update
passes after its single clear. The visible mesh is limited to the coastal strip
and culled by tile. Wave motion renders every frame. Radiance captures use one
flat quad per tile at the existing 5 Hz cadence, including camera-local detail;
only the ground height band receives shore emission. The existing propagation
and scene passes supply the surrounding illumination without another solver.

`WG.GetMosaicRainIntensity()` exposes one local scalar.
`WG.CaptureShoreBioluminescence(bottom, top, domain)` draws borrowed GPU data
into the caller's emission FBO. There are no synced gadgets, network messages,
GPU readbacks, per-wave Lua entities, new light lists, or per-frame GPU allocations.
Provider removal and all partial allocation failures release owned resources.

The eligibility mask is built at widget initialization. Reload LuaUI after
terraforming a coastline to rebuild it. The 32-unit startup scan can miss water
features smaller than that spacing. This is intended for broad beach surf.

## Validation

- `python3 tests/shore_bioluminescence_gpu.py`: real production GLSL on Mesa/EGL,
  half-float FBOs, coast/sand/cliff masking, thin fixed deposits, exponential decay,
  pause, moving front, intensity scaling and radiance height bands.
- `lua tests/shore_bioluminescence_lifecycle.lua`: incremental scan, atlas budget,
  texture feedback prevention, ownership, pause/rewind, dormancy, each allocation
  failure, real widget initialization, weather provider and diagnostic controls.
- Existing neon radiance, rain capture/weather, headlight live-field and combat
  lifecycle suites remain passing. Modified Lua parses under Lua 5.1.

Recoil appearance, exact terrain/water compositing, and GTX 1050 Ti frame time
still need an in-game check. At a sandy beach, compare `/biowaves off` with
`/biowaves test on`, zoom out, then pan away and back. Verify the marks remain
fixed, cliffs/roads stay dark, and `/weatherman on` suppresses the automatic mode.
