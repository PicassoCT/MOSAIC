# Codex procedure for observing Mosaic animations

Use this procedure when asked to test how an animation looks. Run the actual production unit and inspect its rendered output. Script-level tests alone cannot establish visual quality.

## Inputs and scope

Find the complete game checkout, graphical Recoil executable, engine content directory and exact map name. Read the game checkout's `AGENTS.md` and the lab's `README.md`. Keep the lab outside the game and work on an isolated feature branch for any animation fixes. Do not merge the external testing branch into a game branch.

Choose the production unit/model variant, the animation or transition being examined, and observable expectations. Include a lead-in pose and a recovery phase. Record whether you are testing a native gameplay command, a public script behavior, or an attachment/clip fixture. Do not describe a direct `PlayAnimation` call as proof that the gameplay state machine reaches that clip.

## Capture

1. Validate the scenario. Prefer native movement/attack commands when checking locomotion or gameplay transitions. Use a named script entry point when the purpose is to inspect that specific behavior.
2. Run a new isolated capture. Start with one side or three-quarter view and one fixed seed. Use a map/placement where the subject is visible; inspect the initial captured frames before drawing conclusions.
3. Read `manifest.json`, `analysis/report.json` and the relevant engine log errors. If the run is `failed` or `capture_incomplete`, repair the scenario/runtime/camera issue and capture again. Preserve the failed evidence.
4. For suspected fast discontinuities, lower `capture.interval_frames` to `1`. If rendering cannot keep up, the report must retain the missed-frame finding. It is not acceptable to interpolate invented frames and call them observations.

## Inspect

Open every phase contact sheet with Codex's image-viewing capability, then open original PNGs around phase boundaries and automatically flagged frames. If a video-viewing capability is available, examine the MP4 at real speed and slow speed; otherwise inspect ordered adjacent images at the required time resolution. The report links each image to its exact simulation frame.

For each relevant phase, assess:

| Question | Evidence to inspect |
| --- | --- |
| Does the intended animation actually begin? | Requested action frame, exposed upper/lower state, first visibly changed frames |
| Is the movement continuous? | Adjacent frames at state changes, loop boundaries and reversals |
| Do feet remain plausible? | Side view, root movement and visible planted foot positions; emission points are only hints |
| Does the body stay coherent? | Limb range, torso/pelvis relationship, obvious self-intersections, stretched or frozen parts |
| Do props and passengers align? | Hands, carried objects, seats, attachment point and both units during acceleration/braking |
| Does the animation end correctly? | Recovery phase after stop, interruption, unload or release |
| Is the view sufficient? | Occlusion, clipping, hidden limbs, scale and any missing frames |

State only what the images establish. A hidden mesh cannot be judged from a piece coordinate. A lack of numeric spikes does not establish plausible motion. A fixed seed does not cover all procedural branches.

## Record the judgment

Complete `analysis/review.json` while retaining its evidence hash. Use `accepted`, `changes_required`, or `inconclusive`, with reviewer identity and a conclusion. Record each issue with the scenario, unit, phase, exact frame range and image paths, observed behavior, expected behavior, severity and confidence. Do not silently replace an existing review; preserve it or make a new run when the evidence changes. A changed evidence hash makes an old review stale.

Example finding content:

```json
{
  "severity": "medium",
  "unit": "subject",
  "phase": "stop",
  "frames": [241, 244, 247],
  "images": ["animlab/captures/frame_000000241.png", "animlab/captures/frame_000000244.png"],
  "observed": "Describe the specific visible discontinuity here.",
  "expected": "Describe the intended continuous transition here.",
  "confidence": "high"
}
```

These are illustrative fields and frame numbers, not findings from a Mosaic run. Use observed values in the real review.

## Fix and compare

If authorized to fix the animation, connect the observed frame to the script/state transition before editing. Make the smallest justified change, preserving procedural variation and other authored behavior. Run the relevant external Lua regression tests, then repeat the exact visual scenario with a new output directory, same seed, same view and same engine/map.

Compare the same phase-relative times, not merely the same absolute image filename. Inspect the changed transition plus the surrounding phases. Then cover the other useful views and multiple seeds/model variants. An issue can be resolved in one view while still occurring in another.

Report what was observed, what changed, which scenarios/views/seeds were re-run, and anything still unobserved. Keep mechanical evidence status separate from visual acceptance. If Recoil or the full game assets are unavailable, state that limitation and leave the animation visually unverified.

## Request to give Codex

> Read the external animation lab's README.md and CODEX_WORKFLOW.md. Test the selected Mosaic unit and animation using a disposable run. Use the installed graphical Recoil and complete game checkout; keep instrumentation outside production. Capture the lead-in, transition, animation loop and recovery. Inspect the actual contact sheets and adjacent PNGs, record findings with exact frames in review.json, and do not claim visual success from script tests or metrics alone. If fixes are requested, make them on a feature branch and rerun the same capture before reporting the result.
