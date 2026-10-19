# Window-light cache continuity: patch validation

Validated on 19 October 2026. Branch: `fix/windowlight-cache-continuity`.

## Result

The patch removes the reproduced cache-induced blackout while rebuilding direct
window lighting. All 23 instrumented production-module scenarios pass, with no
partially baked field exposed and no loss of an unaffected completed source.
The same fixtures produce 186 behavior-check failures on the old module. Those
are individual fixture assertions, including checks for the new behavior; they
are not a count of flickers observed in a game recording.

Expensive projection work and its per-frame budget do not increase in the tested
scenarios. Large rebuilds use substantially less atlas composition work. A literal
zero-additional-cost claim is **not supported**: one shared staging texture adds
0.5 MiB, and a few small removal/brightness scenarios require extra atlas copies.
No physical-GPU or Recoil frame-time measurement was available in this environment.

## Baseline and scope

The isolated checkout starts at `d4895b9e623b372654693708549729f5dd4ccd04`.
GitHub master was checked at `0b791e52bde03e638c5b505af5cc90ff243765a0`.
The GitHub comparison confirms that none of this patch's existing files changed
between those commits. Thus the tested old production modules and patch preimages
match master at that revision. This is not a claim that unrelated intervening game
changes were exercised by these isolated tests.

Production changes are confined to:

- `luaui/widgets_mosaic/include/window_lighting.lua`
- `luaui/widgets_mosaic/include/radiance_scene.lua`
- `luaui/widgets_mosaic/shaders/radiancecascade/scene.frag`

The remaining changes add regression/benchmark fixtures, update the scene-uniform
name in existing tests, and document the behavior and costs.

## What changes

A replacement bake writes into one shared 256 by 256 RGBA16F staging texture.
The last completed house field stays intact. After all 16 chunks finish, swapping
texture handles publishes the new field without a GPU copy. The active house
keeps ownership of staging across camera-priority changes and brief visibility
interruptions. Persistent invalidity is still removed at the normal refresh.

Camera admission and eviction dirty the blocker atlas and only invalidate house
fields that overlap the changed facade footprint, with one coarse blocker texel
of conservative padding. Physical occupancy and terrain changes still invalidate
all affected generations. Source removal excludes the removed source immediately
at the existing 5 Hz refresh while retaining surviving completed light.

Cold caches publish completed houses progressively, preserving initial visibility
timing. Warm replacement batches retain the combined atlas until completion. This
avoids redrawing every retained house after every individual bake completes.

The normal night curve changes gain continuously. During a warm replacement, the
existing scene enable uniform becomes a float gain: zero disables windows, and a
positive current-to-published ratio scales the retained atlas. This replaces the
previous max-with-zero operation on nonnegative window RGB. It adds no scene pass,
texture sample or uniform update. Explicit strength changes, source removals,
completion, and ratios outside 0.8–1.25 trigger exact atlas recomposition.

The intended visual approximation is a previous completed shadow solution during
replacement, plus its previous per-house cutoff shape while the bounded gain ratio
tracks the night fade. Final recomposition uses current gain and cutoff exactly.
The existing 32-source selection cap remains, so a source's own contribution can
still enter or leave with that selection. The patch prevents that event from
blanking unrelated houses.

## Deterministic work comparison

`tests/window_lighting_continuity.lua` executes the actual production Lua module
with an instrumented Spring/OpenGL boundary. Baseline and patch receive identical
event schedules. Texture contents carry symbolic source/revision/chunk information
to detect partial publication, stale removed sources, texture aliases and invalid
resource lifetimes. Counters measure submitted work, not elapsed GPU time.

| Fixture | Baseline | Patched |
| --- | ---: | ---: |
| Unchanged warm cache, including selection-only reorder | Zero capture/bake/pack/atlas work | Same |
| Cold 32-house capture/readback/chunks | 32 / 65 / 512 | Same |
| Cold 32-house atlas passes / copies | 32 / 528 | Same |
| First cold projection | Frame 204, after 22 submitted chunks | Same |
| 32-house physical rebuild: projection chunks | 512 | 512 |
| 32-house physical rebuild: atlas passes / copies | 32 / 528 | 1 / 32 |
| Real night curve, 20-second rebuild fixture: chunks | 512 | 512 |
| Real night curve, 20-second fixture: atlas passes / copies | 98 / 2,016 | 28 / 896 |
| One replacement at the 32-house limit: chunks | 512 | 64 |
| Distant source admission: chunks | 48 | 16 |
| Distant source eviction: chunks | 32 | 0 |
| Maximum chunks per Step / Refresh / rendered frame | 1 / 1 / 2 | Same |

The constant-gain rebuild uses 93.9% fewer atlas copies. The real-night fixture
uses 55.6% fewer. The latter includes the remainder of the fixed observation
period after the replacement completes, when normal gain-driven atlas updates
resume. Neither percentage describes whole-game FPS.

### Explicit additional costs

Nominal live and peak texture payload at 32 houses changes from 47,448,064 bytes
(45.25 MiB) to 47,972,352 bytes (45.75 MiB). The exact 524,288-byte difference is
one shared RGBA16F staging field, about 1.1% of this subsystem's old payload.
Driver metadata, FBO objects and allocation padding are excluded.

| Fixture | Baseline atlas copies | Patched atlas copies | Reason |
| --- | ---: | ---: | --- |
| Three sources reduced to two | 3 | 4 | Remove one source promptly while retaining both survivors, then publish replacements |
| Removal during a rebuild | 3 | 4 | Same continuity requirement |
| Removal with a gain change | 3 | 4 | Same requirement with current brightness |
| Explicit strength sequence 2 → 0 → 0.7 during a rebuild | 7 | 9 | Exact cutoff reclassification for user controls |
| Crossing both gain retention bounds | 6 | 9 | Refresh cutoff shape beyond the permitted ratio |

These fixtures add no projection chunks, captures, readbacks or atlas passes.
The normal comparison allows only these named copy budgets and the fixed staging
allocation. Unbudgeted work increases still fail. `--strict-cost` was also run:
it exits with failure for all five extra-copy cases. The memory increase is always
reported separately. Passing the declared-budget test must not be described as
passing a zero-cost requirement.

## CPU and actual GLSL measurements

Seven alternating CPU trials each contained 30,000 Step calls, 5,000 Refresh calls
and 5,000 Update calls on a warmed 32-house cache. The patched median was 0.395360 s
(range 0.374424–0.437100); baseline was 0.404024 s (0.390573–0.428458), ratio 0.9786.
The ranges overlap. This shows no consistent warm-path slowdown in the mocked
environment and does not establish a reliable speedup or an in-game CPU result.

GPU fixtures compiled and executed production GLSL through Mesa EGL. Renderer:
llvmpipe, LLVM 20.1.2, Mesa 25.2.8. This is software rendering.

The atlas benchmark uses the existing `copy.frag`, the real 1024-square RGBA16F
atlas and 256-square RGBA16F fields, linear filtering and additive blending. Final
pixels match exactly across the compared sequences. At 128- and 256-pixel atlas
footprints, completed wall time for the whole constant-gain 32-house rebuild fell
from 19.99 to 1.42 ms and from 51.99 to 3.17 ms respectively. Cold work was unchanged
and its timings were similar. These numbers exclude projection, Lua and game work.

A stronger small-removal sample used 21 alternating rounds with 64 repetitions
per path. The paired median additional completed wall time was 0.0407 ms and
0.1054 ms for the two footprint sizes. OpenGL elapsed-query deltas were too noisy
to resolve a reliable incremental GPU cost. This still establishes that the
extra copy is real work; it must not be called free.

The full scene-shader comparison uses both baseline and patched mobile-capable
shaders. Gain ratio one produces bit-identical RGBA16F output. Ratios zero, 0.5,
one and two match expected linear-light scaling before the existing exponential
tone map; outputs are finite and nonnegative. The ordinary fallback also compiles
and passes the existing soft-mobile-shadow fixture.

With single-thread llvmpipe, 21 alternating rounds of eight draws produced:

| Scene size | Baseline median wall time | Patched median | Paired median delta | Paired delta interquartile range |
| --- | ---: | ---: | ---: | ---: |
| 1280 × 720 | 51.43 ms | 52.25 ms | +0.314 ms | −2.27 to +1.62 ms |
| 1920 × 1080 | 117.03 ms | 114.81 ms | −0.678 ms | −3.69 to +0.94 ms |

The mixed deltas and overlapping variation do not establish a stable timing
increase or a literal zero cost. These are synthetic scene timings, not Recoil
frame times on the user's GPU.

## Checks run

- `texlua tests/window_lighting_lifecycle.lua`: PASS, including both readback
  layouts, static reuse, day/night, source revisions and every allocation failure.
- `texlua tests/neon_radiance_lifecycle.lua`: PASS, including widget delivery,
  common scene integration, fallback, bindings and cleanup.
- `texlua tests/window_lighting_continuity.lua --compare OLD_MODULE`: PASS under
  the explicit budgets; 23 scenarios and zero patched behavior errors.
- The same comparison with `--strict-cost`: expected FAIL for the five documented
  additional-copy cases; no behavior failure.
- `python3 tests/window_lighting_gpu.py`: PASS, including actual capture,
  courtyard masks, source height, projection, occlusion, cutoff, single scene
  addition, retained gain, roof rejection and terrain above the cascade band.
- `python3 tests/soft_mobile_shadows_gpu.py`: PASS, including ordinary fallback
  and full scene compilation, depth/normal receivers and shadow behavior.
- New atlas and scene GLSL comparison fixtures: PASS for pixel/GL correctness;
  timing limitations and results are given above.
- `git diff --check`: PASS.

The auxiliary `tests/mobile_radiance_shadows_gpu.py` was updated for the renamed
float uniform but could not execute: `moderngl` is absent in both available Python
runtimes. This does not negate the separately executed production-shader tests;
it remains an unrun auxiliary suite.

## Reproducing the comparison

Run from the repository root with Lua/texlua, Python, numpy and Mesa EGL available.
The scene benchmark also needs Git history containing the baseline revision.

```bash
git show 0b791e52bde03e638c5b505af5cc90ff243765a0:luaui/widgets_mosaic/include/window_lighting.lua > /tmp/window-lighting-before.lua
texlua tests/window_lighting_continuity.lua --compare /tmp/window-lighting-before.lua --cpu
texlua tests/window_lighting_continuity.lua --compare /tmp/window-lighting-before.lua --strict-cost
python3 tests/window_lighting_gpu.py
python3 tests/window_lighting_composition_gpu.py
LP_NUM_THREADS=1 python3 tests/window_lighting_scene_gpu.py --rounds 21 --repetitions 8
```

The remaining practical check is an A/B run in Recoil on the target GPU, with
the same save, camera route, night phase and graphics settings. Check stationary
warm performance, movement across the source limit, a physical blocker change
and dawn/dusk. Record median and tail frame times alongside `/windowlight status`
counter deltas. The local evidence supports this patch's continuity and bounded
work claims; it does not certify target-hardware frame times.
