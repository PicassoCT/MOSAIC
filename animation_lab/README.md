# Mosaic animation observation lab

This is an external development tool for observing actual animations in graphical Recoil. It spawns production units, performs named actions, records the rendered frames and engine state, and creates an evidence package for Codex or a person to review.

All source files for the tool live in this separate `animation_lab` folder on a branch based on `mosaic-tests`. The playable Mosaic checkout is a read-only input. Each run copies it to a new disposable `.sdd`, adds the observer and controller only to that copy, and uses its own engine configuration and output directory. Do not merge this test branch into the game branch or copy the overlay into the production checkout.

## First run

Requirements: Python 3.10 or later, Pillow, a graphical Recoil installation with its base content, a complete Mosaic checkout, and an installed map. FFmpeg is optional for MP4 creation. A headless or dedicated engine cannot supply rendered animation evidence. A lobby is not needed.

Install the Python dependency in your development environment:

```bash
python -m pip install -r animation_lab/requirements.txt
```

From the external test checkout, run:

```bash
python animation_lab/animlab.py run \
  --game /home/picasso/Mosaic.sdd \
  --engine /path/to/recoil/spring \
  --data-dir /path/to/spring-data \
  --map "Exact installed map name and version" \
  --scenario animation_lab/scenarios/civilian_locomotion.json \
  --output /home/picasso/MosaicDev/animation-runs/civilian-side-1337 \
  --seed 1337 --view side --timeout 240
```

Replace the game, engine, data and map paths with your actual installation. On Windows use `python` and the graphical `spring.exe`; the same arguments work with quoted Windows paths. `--data-dir` may be repeated. The engine's own directory is also searched for its packaged base content. `--map-archive /path/to/map.sd7` can copy and hash a specific `.sd7` or `.sdz` into the run.

Use an empty output directory for every run. A run never overwrites earlier evidence or a source checkout. A source copied from Git must have all indexed files present; a partial clone or sparse checkout with missing assets is rejected before the expensive copy. For a complete export without Git metadata, use `--allow-unversioned-game`; the tool still hashes the files, but cannot verify them against a Git index.

`prepare` accepts the same staging arguments and creates a reviewable run without launching Recoil. `--engine` is optional for preparation. Preparation alone is not an animation test. `validate` checks a scenario without copying the game:

```bash
python animation_lab/animlab.py validate animation_lab/scenarios/truck_passenger.json
python animation_lab/animlab.py analyze /home/picasso/MosaicDev/animation-runs/civilian-side-1337
```

## What a run does

1. Records the source revision and file hashes, scenario, engine version and executable hash, map identity, random seed, camera view, and launch arguments.
2. Starts a private local game using a fresh data directory. The ordinary game scripts and models run unchanged in the snapshot. The fixture uses two passive teams and disables zero-unit team death through the existing game option.
3. Waits until Mosaic's opening cinematic releases the capture callback. The observer acknowledges actual render availability before the controller spawns subjects.
4. Spawns the named production units on a player team, allows initialization time, and executes actions on specified simulation frames.
5. Follows the subject from a fixed initial view and saves real framebuffer PNGs. Every sample identifies its simulation frame, interpolation offset, phase, camera, units, piece emission points, and exposed animation states.
6. Checks capture completeness and mechanical assertions, then produces an explicit **needs visual review** result when the evidence is valid. Codex examines the images and records its own judgment separately.

The default interval of three simulation frames is about ten samples per simulated second. Set `capture.interval_frames` to `1` for a denser animation review. Actual render gaps remain visible in the report. The tool does not invent in-between poses, retime a slow capture into a smooth-looking result, or silently count missing samples.

## Evidence files

| Location in the run directory | Contents |
| --- | --- |
| `manifest.json` | Run provenance, scenario, configuration and process result |
| `source-files.json` | Source snapshot file sizes and SHA-256 hashes |
| `startscript.txt`, `springsettings.cfg` | Exact generated engine inputs |
| `engine-data/games/animlab-<run>.sdd/` | Disposable game snapshot with temporary instrumentation |
| `engine-data/animlab/events.jsonl` | Timestamped phases, actions, checks and image/telemetry records |
| `engine-data/animlab/captures/` | Original rendered PNGs |
| `engine-data/animlab/complete.json` | Completion marker tied to this run ID |
| `engine-console.log`, `engine-data/infolog.txt` | Preserved engine and script diagnostics |
| `analysis/index.html` | Review page with contact sheets, original-image links and playback |
| `analysis/animation.mp4` | Optional video, holding captured images for their observed simulation durations |
| `analysis/report.json` | Capture problems, runtime failures and candidate frames to inspect |
| `analysis/review.md`, `analysis/review.json` | Review instructions and the separate reviewer decision |

`failed` means an engine/runtime/mechanical failure. `capture_incomplete` means the evidence cannot support a complete review. `needs_visual_review` means the evidence is available; it says nothing about whether the animation looks good. The process exit code alone never establishes successful capture.

## Included scenarios

| Scenario | Purpose |
| --- | --- |
| `civilian_locomotion.json` | Idle, native walking, stop, direction change and return to idle |
| `operative_locomotion.json` | Visible propagator locomotion and enough idle time to inspect prop transitions |
| `civilian_prayer_interrupt.json` | Production prayer entry point, interruption, then native movement recovery |
| `truck_passenger.json` | Actual attachment and production passenger pose during movement, braking, unloading and walking again |
| `text_fx_cycle.json` | Observation of the existing `text_fx_test` unit and its diagnostic mode/rotation/speed parameters |

The truck case is an **attachment fixture**: it verifies the rendered passenger pose and transport state after `UnitAttach`. It does not prove that the player's boarding command works. Prayer uses a public script entry point; locomotion uses native move orders, so the character actually travels. These distinctions are retained in `fixture_kind`.

The harness deliberately keeps procedural variety. Different seeds, unit IDs, cultures, models and action histories may produce different poses. `FixedRNGSeed` improves repeatability; comparisons also need the same engine, map, source, creation order and scenario. Native background activity and render scheduling are recorded context, not a promise of pixel-identical output.

## Add an animation scenario

Copy a scenario and change its production unit definition, phases and actions. A phase lasts `frames` simulation ticks; Recoil normally runs simulation at 30 ticks per second. Unit positions and move/detach destinations are offsets from the map center. The controller rejects out-of-map and underwater placements. Choose an unobstructed land area/map and check the first captures for buildings, terrain or other units hiding the subject.

Supported actions:

| Action | Required fields beyond `type` | Meaning |
| --- | --- | --- |
| `move` | `unit`, `x`, `z` | Native move order; exercises engine movement callbacks |
| `stop` | `unit` | Native stop order |
| `attack` | `unit`, `target` | Enables fire and issues a native attack on another declared subject |
| `call` | `unit`, `function`; optional `args` | Calls an existing public script function in a yieldable unit coroutine |
| `attach` | `unit`, `transporter`, `piece` | Creates a known attachment fixture with the real model piece |
| `detach` | `unit`, `x`, `z` | Detaches and places the subject at a known test location |
| `destroy` | `unit` | Triggers production destruction/death behaviour; subsequent absence is explicitly expected |

Call arguments are scalars, arrays or unit references such as `{"ref":"partner"}`. A function name can be `startPraying` or `script.TransportPickup`; it is not Lua source to evaluate. Missing functions, unit definitions and requested pieces fail visibly. A newly added ability can be tested on its feature checkout without requiring a production merge.

Optional checks run at the end of a phase:

```json
"checks": [
  {"type": "displaced", "unit": "subject", "min": 15},
  {"type": "transported", "unit": "subject", "transporter": "truck"},
  {"type": "detached", "unit": "subject"},
  {"type": "alive", "unit": "subject"}
]
```

Use only checks appropriate to that phase; transported and detached are mutually exclusive. `displaced` measures the unit root's horizontal change from the phase start, not the number of animated limb movements. `expected_motion: true` enables an advisory freeze check. It does not turn a heuristic into visual approval.

`units[].pieces` optionally selects exact model piece names for telemetry. Without a selection the observer records up to 256 alphabetically sorted pieces and reports the total and sampled counts. These coordinates come from `GetUnitPiecePosDir`: they are **synced emission points**, not necessarily pivots, mesh bottoms or ground contacts. Hidden pieces can still have coordinates. Treat their changes as pointers to images worth inspecting.

The views are `front`, `side`, `rear`, and `threequarter`, relative to the subject's initial forward direction. The camera follows translation while preserving that viewing direction, so a turn remains visible rather than being cancelled by a rotating camera. Change the camera distance/height/target height in the scenario if the subject or its props do not fit. Off-screen subjects require a new capture.

## The Codex review loop

Read [CODEX_WORKFLOW.md](CODEX_WORKFLOW.md) for the full agent procedure and a ready-to-use request. The core loop is:

**capture → inspect real images → identify exact defective frames → make a focused animation change → capture the same scenario again → compare transitions and other views.**

A contact sheet is an index into the evidence. Review original adjacent frames around transitions; do not approve foot planting, attachment alignment or timing from a single thumbnail. When video input is unavailable, inspect the ordered PNG sequence instead. Save findings with exact frame/image references and distinguish artistic judgment from mechanical failures.

## Validate the harness itself

```bash
python -m pip install -r animation_lab/requirements-dev.txt
python -m unittest discover -s animation_lab -p 'test_*.py' -v
```

The optional Lupa dependency executes the controller and observer under Lua 5.1 with a synthetic scheduler. The tests verify isolation, scenario dispatch, readiness, coroutine behavior, PNG/error handling, evidence integrity and video timing. Synthetic tests are identified as such; they do not count as in-game validation. See [VALIDATION.md](VALIDATION.md) for the checks actually performed for this version.

## Engine references

- [Recoil startscript format](https://github.com/beyond-all-reason/RecoilEngine/blob/master/doc/StartScriptFormat.txt): `FixedRNGSeed`, map/game identity and team setup.
- [Recoil OpenGL Lua implementation](https://github.com/beyond-all-reason/RecoilEngine/blob/master/rts/Lua/LuaOpenGL.cpp): `gl.SaveImage` framebuffer capture and options.
- [Recoil draw and simulation timing](https://github.com/beyond-all-reason/RecoilEngine/blob/master/coding-agents/ENGINE_PERFORMANCE.md): fixed simulation ticks, render updates and interpolation.
- [Recoil data directory discovery](https://github.com/beyond-all-reason/RecoilEngine/blob/master/rts/System/FileSystem/DataDirLocater.cpp): isolated writes and additional content search paths.
