# Asian house model splitting

Baseline: `a181dc0694a9cbfafd2a05adc9743ea22e25a4a0`.

`house_asian0` remains the building-purpose entry in the city's weighted pool.
Immediately before `Spring.CreateUnit`, `spawnUnit` selects a smaller model and
passes an assembly plan to the script. All ten UnitDefs inherit the original
health, costs, footprint, collision, category, civilian build options and script.
The separate arcology/project/comb/standalone models are not changed.

Style numbers are **1 pod, 2 industrial, 3 traditional, 4 office**. Equal numbers
mean a pure style; pairs are unordered. Shared style pieces and untagged stock
remain available in every applicable model.

| UnitDef / model basename | Scene nodes | Reduction from 1,400 |
| --- | ---: | ---: |
| house_asian_split_1_1 | 1,040 | 25.7% |
| house_asian_split_1_2 | 1,167 | 16.6% |
| house_asian_split_1_3 | 1,164 | 16.9% |
| house_asian_split_1_4 | 1,175 | 16.1% |
| house_asian_split_2_2 | 940 | 32.9% |
| house_asian_split_2_3 | 1,146 | 18.1% |
| house_asian_split_2_4 | 1,212 | 13.4% |
| house_asian_split_3_3 | 570 | 59.3% |
| house_asian_split_3_4 | 1,037 | 25.9% |
| house_asian_split_4_4 | 734 | 47.6% |

These are asset counts, **not measured FPS or engine memory savings**. Assimp
adds a scene root when importing. Per-unit local model allocation has fewer
pieces; loading all ten model resources increases shared model/mesh storage.
The generated DAEs add about 487 MiB to an uncompressed checkout. Compare cold
load time and memory/VRAM as well as the per-unit improvement before merging.

## Generation and regression checks

Run from the repository root:

```sh
python3 tools/house_asian_split/generate.py
python3 tools/house_asian_split/generate.py --check
python3 tests/house_asian_split_models_test.py
lua tests/house_asian_split_test.lua
lua tests/house_asian_split_semantics_test.lua
lua tests/city_arcologies_test.lua
```

The generator needs only Python's standard library. It never rewrites the
authoring model. It prunes scene nodes and unused geometry, keeps complete
component subtrees, and copies the source `.dae.lua` import metadata. Mesh
arrays, UVs, materials, transforms, units, names and child relationships remain
unchanged. It fails if controllers, animation channels or library-node
references are introduced into the source; extend the generator explicitly
before exporting such a source. Commit all regenerated assets and both catalogues
when changing `objects3d/house_asian.dae`.

The branch-scoped `house-asian-split-assets.yml` workflow runs the generator,
reproducibility, importer, assembly and gameplay checks, then commits generated
assets only to `feat/house-asian-pre-spawn-split`. It never updates `master`.

For importer and real Lua assembly checks (Lua 5.1 through Lupa):

```sh
python3 -m venv /tmp/mosaic-model-tests
/tmp/mosaic-model-tests/bin/pip install assimp_py==1.2.0 lupa==2.8
/tmp/mosaic-model-tests/bin/python tests/house_asian_split_models_test.py --runtime
```

This imports every model through Assimp, validates all local COLLADA references,
checks lossless source subtrees/geometry and texture paths, then runs the actual
house assembly code against the imported piece maps. It exercises all ten
manual-spawn variants and all 95 preferred component plans, with piece-ID,
finite-placement, roof-completeness and component-placement assertions. It
also shares the piece cache across models to detect cross-model ID reuse.
Engine scheduling, rendering, long-running animation threads and frame timing
still require the Recoil checks below.

## Preference and determinism

The generated catalogue contains 95 complete numbered `ID_u`, `ID_l` and `ID_a`
components that fit one straight facade (including floor and roof groups).
Vertical groups form columns; horizontal groups stay on a single facade;
larger `a` groups use columns of four. Seven incomplete/misnumbered source
groups are listed in `manifest.json` as excluded from coherent preference;
their pieces are retained for ordinary assembly.

The planner uses map name, quantized location, ordered catalogue entries and a
map-wide used-group set. It does not use global RNG, unit IDs, or `pairs()` order.
Each successful Asian city spawn reserves one unused complete component until
the catalogue is exhausted. Afterwards the planner selects ordinary pure/pair
recombinations. Remaining slots always use ordinary pieces. The selected
component's pieces are withheld from random pools until placed in their reserved
slots. Open-office holes are disabled for those component-bearing houses.

Failed `CreateUnit` calls do not consume a component. Destruction removes the
per-unit plan but leaves map-wide usage intact. The state and live plans survive
a city-gadget reload through `GG`; a new game gets a fresh pool. Direct `/give`
of a variant uses only that model's styles and does not consume the city's pool.
The legacy `/give house_asian0` retains the original monolithic debug path.

Only the successful-spawn plan is published after `CreateUnit`. The house
script's existing `Sleep(1)` before assembly ensures the plan is available even
when `script.Create` executes inside `CreateUnit`. Test this handoff on the
target Recoil build as part of the normal generated-city run.

House, civilian, police, raid, safehouse, climbable-roof and window registries
include the variants. City sampling explicitly excludes them from its initial
building-purpose pool, so ten model variants do not make Asian houses ten times
more likely. Existing arcology quotas, plot rebuilding and occupancy cleanup
are preserved. The snipe widget, interior-window renderer and team-platter
exclusions recognize the variants as well.

## Exact Recoil validation

1. Fetch this branch and use a separate game checkout/archive, selecting that
   local game in your launcher. Keep the baseline available for comparison:

   ```sh
   git fetch origin feat/house-asian-pre-spawn-split
   git worktree add ../MOSAIC-asian-split.sdd origin/feat/house-asian-pre-spawn-split
   ```

   Put/link that `.sdd` directory under the Recoil data directory's `games/`
   directory. Avoid loading a stale rapid archive with the same game version.
   Use the same Recoil executable, LastDayOfDhubai map, settings, players and
   resolution for both runs. The intended reference machine is the GTX 1050 Ti.

2. Start a sandbox game, open the console, enter `/cheat` and `/godmode`, and move
   the mouse to a separate clear, flat plot before each of these commands:

   ```text
   /give house_asian_split_1_1
   /give house_asian_split_1_2
   /give house_asian_split_1_3
   /give house_asian_split_1_4
   /give house_asian_split_2_2
   /give house_asian_split_2_3
   /give house_asian_split_2_4
   /give house_asian_split_3_3
   /give house_asian_split_3_4
   /give house_asian_split_4_4
   ```

   Allow at least 30 simulated seconds after each batch. Check complete facades
   and roofs, no error icon, correct texture atlas/scale, attached subpieces,
   industrial machinery, spinning decorations and holograms. Watch a day/night
   transition for illumination. Inspect `infolog.txt` for model-load errors,
   missing pieces, nil accesses and non-finite transforms. Restart and give the
   variants in reverse order to check model-cache independence.

3. Run normal automatic city generation on LastDayOfDhubai. Verify coherent
   columns/rows appear together on early Asian houses; roofs do not have random
   pieces from another component in reserved slots. Check that ordinary houses,
   projects and the minimum three arcology plots still appear. Repeat with the
   same setup on a second client or replay; there must be no sync errors. The
   standalone deterministic test above checks the exact model/group sequence
   including complete pool exhaustion without requiring 95 Asian city plots.

4. Use an operative to enter/use a safehouse hosted by a split house and perform
   the usual raid and roof-climb actions. Confirm roof targeting/attachment,
   civilians, police responses, window rendering and snipe UI work normally.
   Destroy the host building: its safehouse must be removed; rubble and eventual
   rebuilding must still occur. A rebuild must not reset component usage for the
   map. Repeat an ordinary arcology destruction/rebuild as a control.

5. Compare baseline and branch in fresh engine processes. Record cold startup,
   city-generation frame spikes, process memory and VRAM after the city settles.
   At the same paused/unpaused camera positions, record 60 seconds of zoomed-out
   FPS after warmup, then repeat close-up at day and night. Repeat both runs
   three times and report minima/medians. The release target remains at least
   25 FPS zoomed out; this branch alone does not establish that target. Reject
   a memory/VRAM regression that outweighs the reduced per-unit copy cost.

No Recoil executable or GPU session was available in the implementation
environment. Assimp imports and Lua regression/assembly checks were run;
the in-engine and performance checks above remain a merge gate.
