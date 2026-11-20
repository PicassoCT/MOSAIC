# Animation polish work record — November 19–20, 2026

**In development; not movie-ready.** Automated success, complete captures and visual approval are separate gates. No whole-library approval has been granted.

## Saved work

All preexisting game work, including the repaired civilian exports and other gameplay changes, was committed as `6b79f902` before creating `feature/animation-polish`. The preexisting external lab/tests were saved as `bc14ae38` on `mosaic-tests`.

Current game revision: `08f59aea`. The feature branch contains:

- Eight generated conversation gestures added to the original normal/aggressive pools, with support-hand lag, neutral recovery and no immediate repeat.
- Seven paired melee styles (14 attack/defense clips) plus the original fight behavior as the eighth choice. Shared arena epochs coordinate roles, cancel stale exchanges, avoid consecutive style repeats and allow complete beats. Combat waits observe epoch changes every simulation frame; noncombat waits retain the original single sleep. Legacy fights receive their full 50-frame duration.
- Arm keyframes compiled from each operative's actual bind geometry. The propagator's T-pose and the other operatives' A-poses need different angles. Playback uses the existing player; there is no continuous arm IK thread.
- Three compact footwork clips for advancing, retreating and bracing. Original footwork remains reachable in the legacy fight style and ordinary movement.
- Correct Y-up arena transforms, body ownership on transport-to-combat handover and body-scaled foot scuffs. Existing larger dirt effects remain intact.
- Seven procedural death profiles, inherited signed native rotations, gravity-driven root support, bounded joint response, impact damping and body-chain settling against rounded piece volumes with all proximal native joint axes available. Operatives retain authored deaths as a variant. This is ragdoll-like animation, not free articulated rigid-body simulation.
- Stable conversation facing at cardinal headings, dense command lists when optional pieces are absent, per-definition civilian bank caching, injury-state/mask preservation when movement restarts, and survivor locomotion restoration after arena destruction.

Independent coat, hair, shopping-bag and other secondary physics have not been edited. No source models were modified after the checkpoint. Existing authored animation content remains reachable.

## Evidence and corrections

Raw captures, manifests, source/image hashes and reviews are under `/home/picasso/MosaicDev/animation-runs`. Failed runs are retained. Versioned decisions and fingerprints are in `review_records/20261120.json`.

| Run | Finding / disposition |
| --- | --- |
| `animation-polish-melee-01` | Overlap and stale parachute ownership; corrected transport handover and lower-body masks. |
| `animation-polish-melee-02` | Actors rolled into pavement because shared actor aliases disagreed with the native arena axes; corrected explicit arena axes. Rejected. |
| `animation-polish-melee-03` | Upright separated actors, but arrival effects intruded and ordinary running footwork was unsuitable. Changes required. |
| `animation-polish-civilian-02` / `03` | Wrong facing, then corpse supported by an extended hand. Changes required. |
| `animation-polish-civilian-05` | First gap-free capture. Full sequence exposed an east/west heading reversal at the cardinal endpoint; native engine approximation explained it. Changes required. |
| `animation-polish-civilian-06` | 435 gap-free frames, no reported runtime failures. Partner facing remains correct. Torso reaches ground, but distal legs remain elevated. Native geometry telemetry confirms this. Idle entry and fleeing also need work. Changes required. |
| `animation-polish-melee-propagator-01` | Gap-free capture exposed the propagator bind-pose mismatch and excessive running footwork. Changes required. |
| `animation-polish-melee-propagator-02` | Calibrated guards improved, but camera entered a building and the execution tool interrupted capture. Marked failed; partial images are not continuity evidence. |
| `animation-polish-melee-propagator-03` | 420 gap-free frames. Calibrated guards and compact feet improve the poses, but delayed beat response and planted-foot sliding remain. Death entry predates signed-angle fix. Changes required. |
| `animation-polish-melee-asset-04` | Gap-free second pairing: death entry/grounded pose improved. Survivor runs in place after release; fixed afterward. Cable visibility remains a separate review issue. Changes required. |
| `animation-polish-melee-propagator-05` | 420 gap-free frames. Jab timing improves; survivor returns to standing and detaches correctly. Foot contact still needs polish; propagator death remains braced. Changes required. |
| `animation-polish-melee-propagator-06` | 210 gap-free frames, no reported runtime failures. Additional shoulder Y freedom removes the upright brace: the propagator rests prone with hands near ground. Survivor returns to standing. Residual raised lower leg and earlier choreography contact issues remain; changes required. |
| `animation-polish-civilian-07` | 435 gap-free frames. Death entry preserves the walk pose and distal feet settle close to ground; torso is visibly supported. Conversation facing stays stable. Idle/fleeing still require changes. |

The native engine stores piece rotations in `[0, 2π)`. Treating these as signed bends caused an abrupt death pose at the first update. The solver now normalizes them and eases extreme inherited poses into resting limits. Regression tests now model the native wrapping rather than returning the caller's signed input.

## Validation and rig coverage

**19 targeted Lua 5.1 suites pass**, covering generated clips, variety, facing, absent props/cache, injury movement, seven death profiles, actual operative call-ins, arena roles/cancellation, lower-body and transport controllers, animation arguments, hostages, passengers, prayer and lifecycle integrations. **67 Python/Lua harness tests pass**, including single-step captures, typed fixtures, isolation and video timing. The contact Jacobian is also checked against finite differences of native Y-X-Z transforms, including rotated ancestors. These are correctness tests, not performance or appearance certification.

Fresh static inventory: `review_inventory_polish_91e2f260` — 15 models, 133 named bank entries, 617 model/clip coverage candidates. All candidates remain pending. All 12 civilians and all three operatives have the expected core names and parentage. Rest transforms differ intentionally or require runtime assessment; matching hierarchy does not prove interchangeability. Two authored clips still target absent pieces on some models; optional filtering prevents array holes but does not approve their appearance.

## Remaining acceptance work

1. Continue close-contact choreography refinement: plant feet against arena travel, align strike/block contact and validate recovery at normal speed. Adjacent-frame jab inspection confirms the new beat cancellation improves response, but does not approve every style or pair.
2. Check all operative pairs, swapped roles, multiple views/seeds and native weapon-to-arena entry. Stationary fixtures validate choreography only; native arena travel must be reviewed separately.
3. Validate each civilian model and each death profile across hit directions, slopes, explosive damage and interrupted states. Scripted destruction does not establish native damage-direction coverage.
4. Improve idle entry and fleeing; review wounded motion, existing activities and transitions in `REVIEW_PLAN.md`. Preserve old content as variants.
5. Review hand/weapon contact, body penetration, foot skating and corpse handover. Models without articulated fingers limit fist silhouettes; do not silently redesign meshes.
6. Measure normal-speed crowd performance and normal gameplay HUD integration. Single-step recording and the observer-only UI fixture are not those tests.

The external tests are local and unpushed. `.github/mosaic-tests.ref` still names the previously published suite. Publish `mosaic-tests` before updating that pin; never merge the test branch into the game branch.
