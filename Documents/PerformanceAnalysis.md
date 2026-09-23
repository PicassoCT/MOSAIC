# Mosaic performance analysis: zoomed-out 7 FPS

Prepared against master f1c0ce53576055bb5f0d584294a128f3d910ed29.
7 FPS is about **143 ms/frame**. 30 FPS needs 33.3 ms/frame, a reduction of
roughly 109.5 ms (77%); 60 FPS needs 16.7 ms. No measured speedup is claimed.
The code findings below are hypotheses to rank with real captures.

## Quick start

Enable **Mosaic Performance Capture** in the widget selector (F11), or:

```
/luaui enablewidget Mosaic Performance Capture
/mosaicperf start 30 zoomout_baseline
```

It waits three seconds, then measures 30 seconds of DrawScreenPost-to-
DrawScreenPost wall-clock intervals. Keep the game focused and camera still.
This measures rendered-frame pacing including simulation/driver/presentation
waits between callbacks, not GPU duration or monitor presentation timestamps.
It reports mean FPS (interval count divided by elapsed time), mean/p50/p95/p99/
maximum milliseconds, plus individual intervals in `MosaicPerf/*.csv` in the
engine writable directory. Summary and highest LuaUI costs go to `infolog.txt`.
CSV contains comment metadata, a frame interval section, then a widget section.

For LuaUI attribution, repeat separately:

```
/mosaicperf start 30 zoomout_lua lua
```

This mode times currently registered widget callbacks and ranks their total
inclusive wall time per captured frame. It preserves callback return values and
restores only hooks still owned by it. It never rewrites handler dispatch.
Disable the older Widget Profiler first. Do not reload or enable/disable widgets
inside a capture: new or replaced callbacks are not instrumented until the next
capture. Nested timings can overlap; do not sum them as exclusive CPU cost.
Driver stalls can appear in Lua draw time; asynchronous GPU work can be absent.
Synced gadgets, unit scripts, unsynced gadget callbacks and engine work are NOT
covered by this LuaUI ranking. Use the engine and GPU tools below for those.

Captures are bounded to 5–120 seconds and 120,000 intervals. Writing happens
after sampling. File failures retain a useful summary in the log. Disabling the
widget or `/mosaicperf stop` restores timing hooks. Start/end metadata includes
camera, viewport, engine/game/map, speed, pause, accessible and visible unit
counts, selected graphics settings and active widgets. Also record the exact
git revision, CPU/GPU/driver, resolution scale, weather and screenshot yourself;
not all platform fields or visual settings are exposed on every engine build.

## Controlled A/B tests

Start with a replay paused at the same late-game timestamp, same spectator/LOS
state and exactly the same camera. Pausing is a rendering isolation experiment,
not a representative gameplay result. Also test unpaused at 1x to measure the
full cost. Keep VSync, FPS caps, debug overlays and graphics settings fixed.
Close the console before measurement starts. Repeat baseline → change → restored
baseline three times, then compare median run means and p95/p99. Do not compare
different game states or treat FPS deltas as additive.

These new gates suppress only local gadget DrawWorld work; simulation and effect
registrations remain active. They do not persist settings or modify gameplay:

```
/mosaicperf effect holograms off
/mosaicperf start 30 zoomout_no_holograms
/mosaicperf reset
/mosaicperf effect clouds off
/mosaicperf start 30 zoomout_no_clouds
/mosaicperf reset
/mosaicperf effect smoke off
/mosaicperf start 30 zoomout_no_smoke
/mosaicperf reset
```

Wait for completion before each following command. Reset, or disable the widget,
to restore all three gates. Capture completion restores timing hooks but leaves
explicit effect gates as selected until reset, allowing repeated runs.
Hologram suppression does not suppress its radiance emission: that is deliberate
isolation of the mesh draw, not a complete lighting disable. Clouds and smoke
resume from current simulation records. This does not suppress legacy CEG smoke.

Additional existing controls, each tested independently and restored afterward:

| Experiment | Disable | Restore | Interpretation |
|---|---|---|---|
| Rain renderer | `/luaui disablewidget Raymarched Rain` | `/luaui enablewidget Raymarched Rain` | Also removes its wetness provider; not purely the rain shader |
| Rain light glitter | `/rainglitter off` | `/rainglitter on` | Incremental glitter cost with rain present |
| Radiance scene composite | `/radiancelight off` | `/radiancelight on` | Does NOT stop the base propagation solve |
| Local radiance detail | `/radiancelight detail off` | `/radiancelight detail on` | Should matter close up; already disabled far out |
| Live headlight field | `/headlights motion off` | `/headlights motion on` | Tests direct-field refresh/interpolation path, not all headlights |
| Whole radiance widget | `/luaui disablewidget NeonLight Radiance Cascade` | `/luaui enablewidget NeonLight Radiance Cascade` | May activate fallback headlight rendering; inspect the image |

Restore the actual initial state if it was already off. Existing commands are
not managed by `/mosaicperf reset`. Do not combine these with rain snapshot
capture. `/weatherman off` restores natural weather; it does **not** force dry.
Use matched replay times for dry/rain and day/night comparisons.

Test zoomed-in, mid, and full-map views; paused/unpaused; day/night; dry/rain.
Start with the slowest reproducible scene before expanding the matrix. Also
compare full resolution with half width AND half height (one quarter the pixels),
keeping camera/aspect ratio/scene fixed. Large improvement suggests pixel/shader/
bandwidth pressure; little improvement directs attention toward draw submission,
geometry or simulation. These are indicators, not proofs. Record VRAM usage and
paging externally; high CPU total utilization is not required for a thread limit.

## Engine and GPU attribution

1. Capture the engine `/debug` profiler overlay separately; keep it off in timing
   baselines. Compare simulation, unsynced update and rendering costs on the
   actual installed engine. Zoom dependence makes rendering a strong suspect,
   but does not exclude simulation stealing time from rendering.
2. For CPU detail, use a Tracy-enabled build of the **same engine revision**, and
   a compatible Tracy client. Inspect main-thread draw submission, LuaRules,
   unit-script work, GC spikes and waits. Detailed zoning/memory profiling add
   overhead; enable only as needed. Official instructions:
   https://beyond-all-reason.github.io/RecoilEngine/development/profiling-with-tracy/
3. Capture a slow frame in RenderDoc. Inspect the event list, draw count,
   framebuffer/depth copies, transparent passes and supported GPU-duration/
   fragment counters. Capture several frames, including a radiance refresh frame
   and an intervening frame: radiance refreshes at 5 Hz. Counter availability is
   driver dependent. Replay timings help locate expensive work; validate gains
   in the live game without capture overhead. Official counter documentation:
   https://github.com/baldurk/renderdoc/blob/v1.x/docs/window/performance_counter_viewer.rst

Do not insert gl.Finish or synchronous query reads into every draw to time the
GPU. That serializes execution and changes the workload being diagnosed.

## Code-backed improvement priorities

| Priority | Evidence in current code | Proposed improvement if confirmed |
|---|---|---|
| 1: Hologram draw scaling | `luarules/gadgets/gfx_neonHolograms.lua`, `RenderAllNeonUnitsDrawWorld`: all in-view units; commented distance cutoff; separate FRONT and BACK loops over every piece; full viewport depth copy before the loop | Introduce projected-size LOD with hysteresis: detailed mesh nearby, simple textured geometry at medium distance, omit subpixel detail far out while retaining coarse radiance. Batch by material. Assess a single two-sided draw instead of two CPU submissions, verifying front/back semantics and appearance. This alone does not halve fragment work. Avoid depth copy when nothing will draw. |
| 2: Rain GPU work | `gfx_rain.lua` renders rain into an FBO then composites; shader includes surface runoff and lighting | If GPU capture confirms cost, separate close surface detail from distant rain; use half-resolution rain/lighting with depth-aware upsampling, and projected-footprint suppression of tiny ripples. Preserve the stable Voronoi runoff network. Verify edges and temporal stability, not just FPS. |
| 3: Radiance cadence and emission capture | `gfx_neonlights_radiancecascade.lua`: 0.20 s refresh, per-piece capture, possible separate scene/preview band solves; `radiance_propagation.lua`: four 256² cascade targets and up to 256 trace steps | Avoid invisible diagnostic-band work unless actually needed by a consumer; cache static emission and update dirty regions; lower far-view solve frequency with smooth interpolation. Track emitter removal, animated pieces, moving lights and occlusion invalidation explicitly. GPU timing must separate refresh spikes from ordinary frames. |
| 4: Building occlusion updates | Global dirty flag rebuilds all 16 occupancy layers by iterating building voxel columns | Precompute static geometry per band and invalidate only changed building/band regions. Local capture currently traverses building columns too; use spatial bins for the local domain. Preserve correct shadows after building completion/destruction. |
| 5: Base city geometry/shadows | Not measured by widget Lua timings; full-map view exposes many buildings, civilians and vehicles | If slow with custom effects suppressed, profile model/shadow passes. Use proper far building LOD/impostors, simpler distant shadow casters and existing icon transitions. Preserve recognition of operatives and important objectives. |
| 6: Cloud/smoke overhead | Cloud renderer already limits to 24 candidates and a viewport-scaled sample budget; smoke already has size-based distance culling and segment LOD | Do not add redundant distance culling blindly. Use gates to measure actual contribution; then cache shared unit/piece data, reduce per-record table churn and cap work by projected size. The cloud budget can still allow substantial raymarch work. |
| 7: Headlight candidate preparation | `include/vehicle_headlights.lua` scans visible non-icon units, builds transforms and sorts before taking 48 lights; capture results already cached within one draw frame | Filter by projected importance before expensive lamp transforms; maintain a vehicle candidate set and bounded selection. Preserve the existing smooth motion interpolation. |
| 8: Simulation work | Only prioritize if unpaused cost materially exceeds the paused case or engine profiles show it | Rank synced gadgets/unit scripts by time and unit count. Continue event-driven civilian/truck updates, amortize searches and reduce allocation where measured. Camera-dependent suppression must never change synced gameplay. |

Existing safeguards worth retaining: local radiance turns off beyond its distance
threshold (with hysteresis); global occlusion rebuilds only when dirty; clouds
have distance/frustum/icon gates and pixel-work limits; smoke already has distance
LOD; headlights reuse a same-frame candidate snapshot. No Recoil model shader
framework is restored by this work.

There is also a real but narrow bug: `gfx_rain.lua:cameraIsUnchanged` compares
fresh Lua tables by identity, so its paused-camera early return never succeeds.
Fixing component comparison can help paused benchmarking, but is not a solution
to ordinary unpaused 7 FPS and must not freeze other animated lighting inputs.

## Acceptance and next data

Return the baseline, individual effect-off and restored CSVs, `infolog.txt`, a
screenshot of the slow camera, hardware/driver and exact game/engine revisions.
For each optimization require a repeatable mean and p95/p99 improvement in the
same replay, with no close-view visual or LOS regression. Initial milestone:
30 FPS (33.3 ms mean) in the specified full-map scene, then test worst-case rain,
night and combat. This is a target, not a forecast.

The prepared tool has Lua 5.1 mock coverage for pacing/percentiles, warmup,
duplicate draw callbacks, frame-only vs timed modes, nil-preserving callback
returns, restoration, gate state, metadata, file errors and shutdown. It still
needs an in-engine smoke test on the user's installed Recoil build.
