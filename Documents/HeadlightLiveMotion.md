# Live headlight cones

Near headlight footprints now redraw every rendered frame, independently of the
0.20-second radiance solve. The whole-map direct field refreshes every 0.10
seconds; the camera-local field refreshes each DrawWorld call while local detail
is available. At distant zoom, only the whole-map field is used.

This keeps the cone shader and radiance scene path that worked in-game. It does
not return the main lighting to the earlier standalone spotlight implementation.

## Position and direction

Lamp positions use `Spring.GetUnitViewPosition`, the engine's draw position,
when available. Direction uses the current unit front/up/right vectors each
rendered frame. Named piece anchors receive the difference between simulation
and draw positions as well. Thus turning is no longer held until the next
cascade update, and position follows the engine's interpolation. No extra
angular extrapolation is applied ahead of the rendered car. Older engines
without GetUnitViewPosition retain current simulation positions.

The engine implementation was checked in Recoil's `LuaUnsyncedRead.cpp`:
GetUnitViewPosition returns drawPos, while GetUnitTransformMatrix uses the
current object basis and draw position. Sources:
https://github.com/beyond-all-reason/RecoilEngine/blob/master/rts/Lua/LuaUnsyncedRead.cpp
https://github.com/beyond-all-reason/RecoilEngine/blob/master/rts/Sim/Units/Unit.cpp

## Separate direct light and slow spill

The moving direct field receives full cone emission. Existing cascade captures
receive an 8% contribution as an inexpensive approximation of indirect spill.
The scene combines direct and propagated RGB with component-wise max before the
existing exposure/night/material calculation, rather than adding full direct
light twice. The weak spill can still lag by up to a cascade interval; the main
cone no longer does. This is not a physically exact bounce decomposition.

Neon capture, cascade solve count and solve cadence are unchanged. Rain retains
its radiance-field glints; vehicle contribution there is the weaker slow spill.
The visible road cone is composited by the existing scene shader.

## Cost and failure behavior

- Two fixed 512 × 512 RGBA8 FBO textures: about **2 MiB** additional colour storage.
- One near-field cone capture per rendered frame, one whole-map capture at 10 Hz.
  No extra full-screen pass, scene depth copy, or cascade solve.
- Up to 48 visible vehicles, two cone quads each, retaining building-atlas
  clipping. All captures in one draw frame share the vehicle snapshot.
- Up to two direct-field samples and occupancy checks in the existing scene pass.
- No live capture while scene lighting is disabled or at zero night intensity.
- Allocation failure restores the previous full-strength 5 Hz cascade cones.
  Provider removal hides live fields immediately; texture allocation is not
  repeated per frame. Owned textures are deleted on widget shutdown.
- The existing standalone surface fallback remains for disabled/unavailable
  radiance scene rendering.

GPU frame-time cost on the user's hardware has **not** been measured. Dense
traffic near the camera is the important performance check; no FPS guarantee.

## A/B test

`/headlights motion off` restores the old 5 Hz cone capture.
`/headlights motion on` restores the new moving direct field (default).

Compare moving/turning traffic from a close camera, then zoom out. Check pauses,
sharp changes of direction, passing a building, disabling local detail, and
LuaUI reload. In a static view the light should not double in brightness.
For daylight use `/radiancelight test on`, then restore it to `off` afterward.

## Validation

- `tests/headlight_live_scene_gpu.py`: renders the actual cone shader into a
  texture, then the actual radiance scene shader. Holds the cascade texture
  fixed and verifies translation/rotation, local composition, no double
  brightness, off/daytime and removal clearing.
- `tests/headlight_live_field_lifecycle.lua`: 60 draw frames produce 60 local
  captures and approximately 10 coarse captures, with exactly two allocations;
  checks domain exit, provider/off/daytime behavior, cleanup and allocation failure.
- `tests/headlight_cone_lifecycle.lua`: existing capture/fallback tests plus
  engine draw offsets, fresh headings and named piece anchoring.

GPU tests run with Mesa EGL/llvmpipe using numpy and moderngl:
`MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/headlight_live_scene_gpu.py`.
Lua fixtures run from repository root with Lua 5.1+ (also checked with lupa).
In-game visual confirmation remains outstanding.
