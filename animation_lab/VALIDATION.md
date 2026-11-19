# Validation performed on 18 November 2026

The external harness is implemented and its automated contracts pass. **No Mosaic animation has yet been visually accepted, and a successful live end-to-end capture has not been demonstrated in this environment.**

## Automated checks

53 focused tests passed with Python, Pillow and Lupa's Lua 5.1 runtime:

```bash
python -m unittest discover -s animation_lab -p 'test_*.py' -v
```

The checks cover:

- Read-only source staging into an independent snapshot, including distinct file inodes, source/output separation, symlink rejection, and preservation of existing run evidence.
- Missing Git-indexed assets, including sparse-checkout paths, rejected before copying or engine startup.
- Scenario/action/check validation, scalar and reference arguments, map/startscript delimiters, seeded startup and use of the concrete staged archive filename.
- Process deadlines and completion markers tied to the correct run ID; a zero process exit without capture evidence is rejected.
- Lua 5.1 execution of the actual controller and observer against a synthetic engine/thread scheduler: readiness, native order dispatch, displacement and attachment checks, yielding script calls, explicit rejection, deliberate destruction, and completion/error paths.
- Opening-cinematic gating: phases cannot run before the observer receives actual capture callbacks; camera control is deferred until then.
- The observer writing complete PNGs and JSONL to disk, with those outputs then consumed by the real analyzer. These pixels are explicitly synthetic fixtures, not game renders.
- Missing, truncated, duplicate, malformed, other-run and out-of-phase evidence; invalid samples cannot fill required phase coverage.
- Real FFmpeg encoding and FFprobe duration verification using explicitly synthetic image fixtures, preserving the recorded simulation-time gaps.
- Advisory emission-point metrics, explicit runtime errors and failed mechanical checks, and preservation/staleness detection of a prior review.

Python compilation and scenario validation also passed. Independent review checked the runner/config/Lua/analyzer contracts and the workflow documentation.

## Actual Recoil bootstrap attempt

A bounded attempt downloaded the official graphical Linux **Recoil 2026.09.03** release and verified the published archive digest. It used an official small map and the official engine development game as disposable infrastructure fixtures. Neither fixture was represented as Mosaic animation evidence.

| Item | Observed result |
| --- | --- |
| Release archive SHA-256 | `f4323cce98b522047f38019974ac4d6ee57df4c8ed1ef3a406f7b8a99813a205` |
| Executable SHA-256 | `e4e9600921471b79059f8dd71eb7540dcb27fe613d041f6dd6a56181c5a5a21b` |
| Real graphics context | OpenGL 4.5 compatibility, Mesa 25.0.7, llvmpipe |
| SDL driver | `offscreen` |
| Map/game loading | Staged archive, map, terrain, water and unit model definitions loaded |
| Native interface initialization | Engine crashed before LuaRules/LuaUI/observer initialization |
| Final process result | Exit 21; `capture_failed`; no completion marker |
| Captured animation frames | **0** |

The supported offscreen SDL path cannot provide window-manager information. Official engine source suggests a null hardware-cursor pointer during interface initialization; this is consistent with the observed crash stage. `HardwareCursor=0` did not resolve it. The binary was not patched or rebuilt. The alternate local display-server attempt was blocked by this environment's Unix-domain socket restriction.

Actual execution exposed three launcher defects, which were fixed: use the windowed resolution configuration keys; include the engine installation in isolated content search paths; identify the staged game by archive filename rather than relying on a display-name/version concatenation heuristic.

The available Mosaic source was also incomplete: the inspected Git index contained 9,547 paths, of which 7,663 were missing from that checkout. The harness correctly rejects that input instead of silently producing an incomplete game copy.

## Remaining live gate

Run a bundled scenario with a **complete Mosaic checkout and a graphical Recoil installation on a supported desktop display**, then inspect the resulting images. The live gate requires real phase coverage, complete PNGs, no relevant runtime errors, successful mechanical checks and a separately recorded visual review. Unit/scheduler tests and the successful OpenGL-context probe do not replace that gate.

A normal Windows or Linux desktop run remains unverified by this session. The implementation supports both through the same Python CLI, but cross-platform execution is not claimed as tested.

## Primary runtime sources

- [Official Recoil 2026.09.03 release](https://github.com/beyond-all-reason/RecoilEngine/releases/tag/2026.09.03)
- [Official Spring menu map](https://github.com/spring/menu-map.sdd/tree/98bf5b9d1921cdf4bf2ae6c01a8169b389e42a86)
- [Official engine development game](https://github.com/spring/dev-game.sdd/tree/b4fd32020f63f1e0348a68a6a77696c22afb61fd)
- [Hardware cursor allocation](https://github.com/beyond-all-reason/RecoilEngine/blob/2026.09.03/rts/Game/UI/HwMouseCursor.cpp)
- [Mouse cursor initialization](https://github.com/beyond-all-reason/RecoilEngine/blob/2026.09.03/rts/Game/UI/MouseCursor.cpp)
- [Native game initialization](https://github.com/beyond-all-reason/RecoilEngine/blob/2026.09.03/rts/Game/Game.cpp)
