# Orbital arrival

LuaIntro displays static loading artwork and the normal progress bar. The
satellite renderer compiles and starts only at the first LuaUI screen draw with
`Spring.GetGameFrame() > 0`. It blends from that same artwork, holds four optical
zoom snapshots, passes through clouds, and releases the actual rendered map.
It never changes the game camera, simulation speed, pause state, or sun angle.

## Sequence and visual direction

| Phase | Nominal time after the first positive game frame |
| --- | --- |
| Loading artwork blends into low Earth orbit | 0.00–0.50 seconds |
| Snapshot 1: curved horizon and regional weather | 0.50–1.00 seconds |
| Snapshot 2: region and destination acquisition | 1.00–1.50 seconds |
| Snapshot 3: city fabric and map geography | 1.50–2.00 seconds |
| Snapshot 4: district and the same selected footprint | 2.00–2.50 seconds |
| Cloud passage and live map reveal | 2.50–3.40 seconds |

Each snapshot holds its scale for half a second. The presentation clock lands
on every snapshot boundary in an actual draw; display-frame rounding or a slow
startup frame can extend the sequence so no shot is skipped. It never accrues a
backlog that fast-forwards through unseen shots. Wall time drives presentation
after the initial game-frame trigger, including while simulation is paused.

The opening fills most of the screen with Earth and a curved atmospheric limb.
The four optical stops are `0`, `0.30`, `0.64`, and `1`, expanding the apparent
planet diameter by about 9.7 times around the same surface point. A fixed local
**noon** sun illuminates every stage. The sickly golden treatment comes from
polluted amber light, grey cloud interiors, industrial aerosol, subdued ground
colors, and dark water. It does not imply a sunrise or elapsed game time.

Clouds use bounded integration through a density volume, replacing the former
height sheet with gradient-lit wrinkles. Extinction and overhead-light density
samples give the billows internal shading. Regional fronts, detached cloud
banks, thin cirrus, haze, and seeded smoke/ash/dust incidents remain separate
layers. None receives an elapsed-time or wind offset. The cloud passage changes
viewing scale through a frozen field; weather does not race over the ground.

## Ground imagery and continuity

The region and its weather are deterministic from map name, map checksum and
game ID, without consuming Lua's global RNG. A missing game ID uses a stable
map-specific fallback. The selected region is captured once, so cuts and
viewport changes never choose different weather.

The distant Earth is a fictional procedural region. At the closer stops, an
optional cached survey brings in **the map's own authored ground texture**.
Recoil's `$minimap` is the raw SMF map image, distinct from the rendered minimap
with unit icons, selections or LOS overlays. Roads, water and other authored
geography can therefore appear before live game objects or interface content.
The intermediate views never sample the live framebuffer.

The renderer projects the four map corners into the existing game view with
`Spring.WorldToScreenCoords`, fits an inverse homography, and renders the raw
map image once into a screen-aligned survey texture. A plane at the map's
central ground height supplies the projection. Screen coordinates are local to
the viewport and have a bottom-left origin; map UVs follow world X and Z.
Coverage fades at map and screen edges to blend into the generated surroundings.
The Earth shader uses the same optical magnification as the selected target
rectangle. The survey gradually contributes during the regional shot and
becomes the geographic base at city/district scale.

Generated ground remains available outside survey coverage and on maps without
a usable raw minimap. It contains inset parcels, roofs, shaded building faces,
streets, industrial areas, a river basin and larger transport corridors. The
survey preserves its authored roads and water, adding restrained parcel detail.
Missing projection APIs, invalid map dimensions, degenerate corners, missing
texture metadata, or a failed optional shader/FBO leave that fallback available.
An optional survey failure cannot abort the arrival or strand the interface.

This is a visual approximation of ground geography. The survey does not contain
live buildings or units, and a flat homography cannot reconstruct terrain height
or reproduce the generated concept board's photographic metropolis. Cloud cover
conceals the transition to the actual scene. No map data, terrain mesh, physical
camera state, or game rendering outside the arrival is modified.

## Persistent telemetry

A compact panel stays at the right edge through orbit, region, city, district,
cloud passage and the first live reveal. It retains the selected map identity,
theme, five deterministic risk metrics, status and confidence. Long labels fit
without dropping words or rerolling the packet. The values are fictional orbital
survey estimates for the game, not measurements of the current simulation.

A high-contrast leader connects the panel to a rectangle around the same
screen-centered destination footprint. The rectangle grows with optical scale;
phase and approximate altitude cues stay at the opposite edge. Panel placement
reserves clearance for the largest rectangle, including compact viewports.
Telemetry follows the artwork blend, then stays visible until cloud-descent
`0.94–0.98`, when it fades. It is absent from the exact final framebuffer.
The original city/region/district/time telex resumes after arrival releases.

## Loading ownership and the live handoff

LuaIntro passes the chosen artwork's VFS path through runtime-only configuration.
LuaUI arms immediately and draws that same static artwork in DrawScreenEffects
and DrawScreenPost while the game frame is zero. It creates no orbital shader
or GPU texture during loading. LuaIntro shutdown and city-spawn completion are
informational; neither gates the sequence. The city gadget's
`mosaic_city_spawn_complete` value is deliberately not consumed, so startup
cannot wait indefinitely for generation.

First initialization during the opening 300 game frames remains eligible.
Midgame joins/reloads are bypassed. A runtime-only `played` marker prevents
replays even at early frames, including after Escape. Handoff state is never
written to disk.

Planetary optical descent and cloud transit are separate shader values. The
fourth snapshot cannot accidentally reveal the live scene. At cloud descent
`0.42–0.55`, the cloud image fully covers the transition. The display-rate
compositor waits until the cached cloud pass has reached the covered scene
before exposing the clean live capture. Thinning clouds then reveal it at its
native screen scale, with a restrained amber grade that vanishes before release.
There is no additional three-times zoom of the live image.

The widget captures before interface drawing and reuses that clean texture in
DrawScreenPost to cover later engine overlays. All three shader passes supply
explicit bottom-left texture coordinates. Recoil's `CopyToTexture` uses a direct
OpenGL framebuffer copy and does **not** flip it; the old apparent correction
compensated for `gl.TexRect`'s implicit default UV flip. File-backed loading art
alone uses its authored top-left image orientation. The final compositor uses
`texelFetch` and an early return at cloud descent `>= 0.98`, avoiding filtering,
color grading, arithmetic mix rounding, and any stale cached cloud alpha.
The resulting final RGB pixels match the captured framebuffer exactly.

## Interface, failure handling and performance

The handler suppresses ordinary interface drawing and intercepts input before
widget actions, selection, commands or camera bindings. World postprocessing
continues for the clean capture; effects outside the `gfx_` naming convention
can declare `arrivalWorldEffect = true` in GetInfo. The tutorial waits to narrate.

The engine interface is temporarily hidden and edge scrolling is disabled via
runtime-only settings. Escape returns control immediately. Completion, shutdown,
shader failure and texture-allocation failure restore prior interface and edge
settings; an interface hidden before arrival remains hidden. Resources owned by
the renderer are deleted. The shared VFS artwork texture is never deleted.

The Earth and survey render targets use native resolution up to **1920×1080**.
Each of the four stationary Earth snapshots renders once and is reused through
its hold. The optional survey is cached once per viewport and reused throughout
the sequence. Resize/aspect changes and clock resets refresh the cached views
without changing the selected region. Cloud passage alone updates at a bounded
**12 Hz**; cuts, reveal entry and the last frame refresh immediately. Empty
weather columns skip volume integration, and uniform branches skip the unused
planet or transit path. The compositor and telemetry draw at display rate.
There is no full-resolution volume march every display frame during a held shot.

These bounds are design constraints, not a measured GTX 1050 Ti frame-rate
claim. Headless Mesa timing includes host rendering and readback. In-engine
startup stalls, capture ordering, map-specific projection and target-hardware
frame timing still require a Recoil run.

## Validation

Run from the repository root:

```sh
lua5.1 tests/orbital_arrival.lua
lua5.1 tests/orbital_arrival_telemetry.lua
lua5.1 tests/orbital_arrival_survey.lua
python3 tests/orbital_arrival_gpu.py
python3 tests/orbital_arrival_gpu.py --width 1920 --height 1080 --preview-dir /tmp/arrival-preview
```

Lua tests exercise loading ownership, runtime state, triggering, all four holds,
paused/stalled timing, fixed region/risk seeds, snapshot caching, resize,
optional map projection and failure cleanup, input interception and interface
restoration. The telemetry test collects actual production widget draw calls
at 1080p, 720p and 640×360, checking all six phases, unchanged risk content,
leader endpoints, rectangle growth, panel clearance and terminal disappearance.
The survey test uses independent forward-projection fixtures to check the
inverse mapping at corners and interior points, then exercises the renderer's
optional path and owned-resource lifecycle.

The GPU harness compiles all three production GLSL programs under headless EGL.
Independent asymmetric map and live-frame fixtures expose horizontal/vertical
mirrors, projection errors and source leakage. A real `glCopyTexSubImage2D`
capture verifies framebuffer orientation. Checks include stationary repeat
images, regional variation, optional survey coverage/fallback, feathered map
boundaries, all four distinct snapshots without live-image leakage, opaque
cloud transit, file-artwork orientation, finite output, and bit-identical final
captured RGB pixels. These checks establish correctness, not visual fidelity.
Actual shader PNGs must also be inspected against the visual direction.

`--preview-dir` writes production snapshots and reveal samples; PNG output needs
Pillow in addition to NumPy. `--region X Y` chooses a procedural seed to inspect.
`--live-image` supplies a recorded-frame preview fixture. `--survey-image`
supplies an already projected clean map image, or `--minimap-image` and nine
`--survey-rows` values exercise the production raw-map projector. Optional
images affect previews only; correctness checks retain independent fixtures.
`--metrics-json` writes descriptive color coverage and host render timings.

In Recoil, check both Dubai/Dhubai spellings, slow and fast city generation,
pause, Escape, resized/offset viewports, interface restoration and tutorial
narration. Confirm the destination projection and city assembly on the actual
map, then measure startup frame timing on the GTX 1050 Ti.

### Engine API references

The texture-coordinate contract was verified against the pinned Recoil source:

- [TexRect default UVs and CopyToTexture implementation](https://github.com/beyond-all-reason/RecoilEngine/blob/058c8ea/rts/Lua/LuaOpenGL.cpp)
- [WorldToScreenCoords](https://github.com/beyond-all-reason/RecoilEngine/blob/058c8ea/rts/Lua/LuaUnsyncedRead.cpp)
- [Viewport-local projection](https://github.com/beyond-all-reason/RecoilEngine/blob/058c8ea/rts/Game/Camera.cpp)
- [Raw minimap texture binding](https://github.com/beyond-all-reason/RecoilEngine/blob/058c8ea/rts/Lua/LuaOpenGLUtils.cpp)
- [SMF minimap loading](https://github.com/beyond-all-reason/RecoilEngine/blob/058c8ea/rts/Map/SMF/SMFReadMap.cpp)
- [Map orientation and separate unit-icon drawing](https://github.com/beyond-all-reason/RecoilEngine/blob/058c8ea/rts/Game/UI/MiniMap.cpp)
