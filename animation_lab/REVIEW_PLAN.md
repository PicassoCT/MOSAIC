# MOSAIC animation review plan

Review skeleton compatibility first, then civilian behavior, operative behavior, and close combat. Each result needs an actual rendered capture plus a separate reviewer decision. Script tests and static model checks help find defects but do not approve an animation's appearance.

The separate artist/model work list is [MODEL_FIX_TODO.md](MODEL_FIX_TODO.md). Use it for exact filenames and proposed rig corrections. This plan organizes the capture and review work; it does not authorize deleting content, reducing procedural variety, or treating all models as visually identical.

## Scope and current inventory

The initial source snapshot is MOSAIC commit `8af2bda5`. The [inventory](review_inventory/inventory.json) records full revision and source hashes; [clip-review.csv](review_inventory/clip-review.csv) has one pending row per named entry. The [model and clip ledger](review_inventory/model-clip-review.csv) expands this to 470 combinations. These are coverage candidates, not 470 confirmed reachable gameplay states: first resolve applicability and missing-target flags. All start pending.

| Family | Present models | Named entries in inspected banks | Additional behavior to review |
| --- | --- | --- | --- |
| Civilians | Arab 0–5 and Western 0–5: 12 | 36, including registered prayer and aerosol entries | Procedural idle/head/prop motion, stun, transport, human-shield poses, fleeing and seven death profiles |
| Operative asset | `operative_asset.dae` | 9 | Sprint budget, breathing, grappling/rooftops, transport/falling, weapon changes and hostage handling |
| Operative propagator | `operative_propagator.dae` | 11 | Coat/laptop/drone/idle routines, cloak/disguise, transport and hostage handling |
| Operative investigator | `operative_investigator.DAE` | 18 | Hair/tail/drone, eight distinct idle entries, cloak/disguise, weapons and transport |

The 74-entry count covers these four banks only. It includes entries such as `SLAVED` that may be intentional no-ops, and does not count procedural functions as clips. `civilian_western6` is disabled because its model is missing. Keep it as blocked inventory, not a passing model.

Civilian agents and suicide bombers reuse `civilian0_arab.dae` with `civilianagentscript.lua`; review those script paths separately even when the model already passed. Police, recruited civilians, paired civilians, hologram people, text effects, and other animated units enter the extension pass below.

## Review order and gates

| Order | Work | Gate before moving on |
| --- | --- | --- |
| 0 | Finish lab setup and one live capture | Complete, real PNG evidence with correct subject, phases, timing and no blocking runtime errors |
| 1 | Civilian rig standard and engine import | Every present civilian has an explicit compatible rig result or a model-specific blocker |
| 2 | Civilian baseline locomotion and survival | Idle, walk, turn, fleeing, cover/wound, stun, death and recovery reviewed per model |
| 3 | Civilian activities and interactions | Props, prayer, social behavior, passengers, weapons, hostages and aerosols reviewed |
| 4 | Operative rig standard and individual animations | Asset, propagator and investigator pass their own body/weapon/prop contracts |
| 5 | Close combat | Native gameplay entry, two-body alignment, arena motion, injury/death and survivor exit all reviewed |
| 6 | Coverage expansion and regression | Additional variants, seeds, views, terrain and background load covered; no unaccounted active behavior |

Do not wait for every low-priority idle gesture before investigating a crash or broken rig. Resolve P0 blockers first, then return to the ordered review. Preserve failed runs as evidence.

## First working session

1. Read [LOCAL_SETUP.md](LOCAL_SETUP.md), the current smoke-test report, and MODEL_FIX_TODO.
2. Establish approved reference captures for civilian Western 0, then compare Arab 2/3 and Western 3/4/5 because their body hierarchies differ.
3. Review Arab 0/4 hand-dependent behaviors and Western 2 bag targeting.
4. Capture civilian fleeing, nonlethal hits, wounded movement and death with props visible.
5. Establish each operative's neutral and walk/stop baseline; investigate the asset fighting target-value issue before paired combat.
6. End the session by updating evidence paths and decisions. Keep work blocked by missing harness actions separate from animations judged defective.

## Skeleton validation procedure

For every model, compare required names, duplicate names, parents, sidecar settings, rest transforms, local axes, scale/handedness, pivots, bounds and attachment sockets. Distinguish required body joints from optional clothing/equipment. Do not require matching raw offsets across intentionally different physiques.

The authored static audit is already available. It found five civilian hierarchy mismatches, missing hand nodes in Arab 0/4 and the asset, and three civilian entries with absent authored targets. These findings do not substitute for an engine import test.

Add a runtime rig-dump fixture to capture `GetUnitPieceMap`, `GetUnitPieceInfo`, local transforms/rotation bases and piece bounds before procedural animation takes ownership. Dump the initialized pose separately. Perform controlled single-axis rotations and pelvis translations in a **pose fixture**, then restore and run native locomotion. Record emitter points separately from pivots and bounds; `GetUnitPiecePosDir` is not a contact-point measurement.

Use a common semantic schema with civilian names (`UpBody`, `Head1`) and operative names (`Torso`, `Head`) mapped explicitly. Cross-family retargeting is a separate deliverable; sharing a joint name does not establish equal orientation, bind pose or timing. If a rig changes, invalidate affected prior animation approvals using the model/sidecar/animation hashes.

## Civilian review matrix

Run every applicable row for all 12 civilian models, followed by the civilian-agent/bomber script variants. Mark a behavior not applicable only with the source reason and reviewer approval; never silently skip an absent clip.

| ID | Behavior and transitions | Trigger and observations |
| --- | --- | --- |
| CIV-01 | Neutral, idle, head turns, breathing; idle → walk → idle | Native move/stop. Check stance, feet, T-poses, reset timing and jitter. Bundled `civilian_locomotion.json` is the starting case. |
| CIV-02 | Walk, turn/reversal, speed changes, terrain | Native paths with 90°/180° turns, short repeated starts/stops, slope/curb/rough-ground cases. Check planted feet, stride speed and pelvis continuity. |
| CIV-03 | Fleeing and panic | First inspect public `startFleeing(threatID)` as a behavior fixture, then provoke the actual threat/damage path. Capture arms-up, accelerated movement, blocked route, threat loss, interruption and return to normal behavior. Verify travel, not just leg motion. |
| CIV-04 | Hit, coverwalk, wounded gait | Controlled nonlethal weapon damage at defined health/damage levels. Review hit-direction response, cover → wounded transition, stop/restart and wounds while carrying items. A direct `HitByWeapon` call does not prove native damage behavior. |
| CIV-05 | Stun/interrogation and recovery | Native stun weapon first, public `startInterrogationStun` as a labeled diagnostic fixture. Check interruption of walk/prayer/phone, no concurrent limb controllers, and correct movement recovery. |
| CIV-06 | Death and corpse transition | Seven profiles in `lib_civilian_death.lua`: collapse, backwards, sideways, coiling, shivering, blasted, swirling. Capture ordinary and explosive branches, both lateral directions, varied hit directions, standing/walking/wounded/seated/hostage starting poses, slope contact and bodybag handover. Log the selected profile rather than assuming a seed exercised it. |
| CIV-07 | Carrying and everyday props | Handbag variants, shopping bag, trolley, baby, food/drink, cigarette, phones and umbrella where present. Inspect wrist contact, prop ownership, swing settling and hide/show during walk/stop/stun/death. |
| CIV-08 | Social and emotional actions | Normal/aggressive talk, filming, phone, wailing 1/2, hands-up and protest. Inspect partner-facing, lip/head/arm motion where present, end timing, interruption and locomotion overlays. |
| CIV-09 | Prayer and parade | Eight registered prayers, legacy prayer reachability, parade participation and cancellation. Use bundled `civilian_prayer_interrupt.json`; include interruption before/after entering the pose and return to walking. |
| CIV-10 | Armed civilian and anarchy | AK, Molotov and RPG aiming/firing where eligible. Test stationary and moving, headings/pitches, turn limits, projectile/muzzle alignment and transition back to civilian poses. |
| CIV-11 | Vehicle passengers | Bundled `truck_passenger.json` checks attachment, movement, braking and unload. Extend to native boarding/unloading commands; armed/unarmed seated ownership, different truck seats, carrier death and dismount recovery. Fixture attachment alone does not prove boarding works. |
| CIV-12 | Human shield, hostage and escape | Pickup/hold/walk/aim, struggle, release, carrier death, victim death, stun and escape sprint. Check both bodies, weapon line, hand/neck clearance and no residual attachment after release. |
| CIV-13 | Aerosols and altered behavior | Inspect registered collapse/strike, depressol, tollwutox and lunge, wanderlost, zombie standing/walking. Trigger actual aerosol exposure as well as isolated clip fixtures; check entry, duration, interruption, recovery and death. |
| CIV-14 | Environmental/procedural transitions | Rain/umbrella, sun reactions, bag/body variations, looting, protest equipment, delayed activities and any paired/adult civilian behavior reachable in production. Preserve existing content and record applicable variants explicitly. |
| CIV-15 | Lifecycle and concurrency stress | Orders during transition, rapid repeated commands, pause/resume, speed changes, transport/cloak/morph where supported, death during every long-lived behavior, and cleanup after unit removal. |

For damage/death, retain real engine destruction call-ins. Calling `script.Killed` while leaving a unit alive is not a gameplay death test. The current `destroy` action can test basic destruction, but cannot select nonlethal damage, attacker direction, weapon type or death profile; those need explicit harness support.

## Operative review matrix

Apply the shared rows to **asset, propagator and investigator separately**. Their clip banks and equipment are not interchangeable.

| ID | Coverage | Required checks |
| --- | --- | --- |
| OP-01 | Idle, walk, run, stop, turning and recovery | Native commands; walk/run cadence, foot contact, body twist and torso/leg independence. Asset sprint exhaustion and recovery get a separate case. |
| OP-02 | All individual idle entries | Asset standing gun/pistol; propagator idle/prop routines; investigator ballerina, earpiece, snack, low-ready, pivot scan, pose, wall lean and arms-folded. Check weights/conditions and transitions, not just direct playback. |
| OP-03 | Weapon readiness, aim, fire and reset | Pistol/stun pistol; asset gun/sniper; supported raid/arrest actions. Test headings, vertical aim, stationary/moving fire, muzzle alignment, equipment visibility and interruption. |
| OP-04 | Cloak/disguise and discovery | Request visible state for first captures. Then review native disguise/cloak entry, discovery, fire/raid exit and recapture. Confirm that the rendered body is the intended operative rather than a decoy civilian. |
| OP-05 | Damage, stun, interrogation, death | Nonlethal hits, any supported wounded reaction, recovery, each operative's `DEATH`, death while moving/aiming/transported/fighting, and corpse visibility. If no wounded animation is implemented, record that as a design gap rather than inventing a clip. |
| OP-06 | Transport, falling, parachute and landing | Boarding/riding, unload, falling callbacks, parachute ownership, ground contact and return to locomotion. Verify referenced clip names exist for that operative. |
| OP-07 | Human shields and close-contact tasks | Eligible carrier/victim combinations, movement/aim overlays, release, death and interruption. Investigator eligibility must be confirmed rather than inferred from other operatives. |
| OP-08 | Asset rooftop/grapple behavior | Hook/rope, takeoff, ascent/descent, ledge and roof transitions, equipment ownership and cancellation. Preserve asset-specific motion and silhouettes. |
| OP-09 | Model-specific props | Propagator coat bones/laptop/drone/cigarette; investigator hair/tail/jaw/drone/laptop; asset ropes/backpack/weapons. Inspect penetrations during turns, sprint, kneel/fight and death. |
| OP-10 | Repeated/overlapping orders and cleanup | Moving aim interrupted by combat, cloak during actions, rapid stop/start, unit removal and death. No stranded signal masks, pose locks or stale attachments. |

## Close combat review

Source path: `luarules/gadgets/game_ProjectileImpacts.lua` creates `closecombatarena`, calls `addCloseCombatants`, and informs both combatants. `scripts/closeCombatArenascript.lua` attaches fighters, moves/rotates the arena, drains health, detaches the survivor and destroys the arena. The actor's `FIGHTING` animation is only one part of this sequence.

1. Establish each actor's fight pose independently. Check the asset's unkeyed target values before accepting its upper-arm pose.
2. Test native weapon/command entry: approach, range, facing, eligibility and arena creation. Do not present a manually spawned arena as proof of native engagement.
3. Separately use an arena fixture to examine attachment offsets, actor scale differences, opposing facing, foot height, hand contact, distance and mesh overlap.
4. Cover each supported unordered pair of the three operatives: asset/asset, asset/propagator, asset/investigator, propagator/propagator, propagator/investigator, investigator/investigator. Swap attacker/defender roles for asymmetric cases. Test same-team rejection separately from enemy engagement.
5. Confirm eligible civilian, agent and police opponents in the real dispatch/category rules; add each supported rig pairing. Ineligible targets need an explicit rejection check, not a missing animation verdict.
6. Capture both initiative branches, pulse counts, rotations, arena travel, actor upper/lower blending and surrounding terrain. Inspect cinematic-speed motion and original adjacent frames.
7. Interrupt with stun, external weapon damage, participant death, both participants dying and arena destruction where reachable. Check health transfer, detachment, visibility restoration, pose reset and survivor locomotion.
8. Include short/tall pairings, all camera sides, obstacles/curbs and repeated engagements. Confirm no orphan arena, lingering attachment, invisible survivor, or frozen combat state.

## Harness work still required

The supplied scenarios are useful starting points, not a complete test suite. Add these capabilities in the external lab, never as production-only debug hooks:

- Runtime rig dump and controlled pose/axis fixture with explicit observation of engine-imported nodes.
- Controlled damage action: known attacker, weapon, magnitude and direction; distinguish nonlethal, lethal and explosive cases. Add meaningful tests for dispatch and resulting state.
- Native custom-command action for boarding, hostage/arrest, cloak and combat entry, using the game's actual command IDs and legality checks.
- Trigger/state telemetry for selected death profile, clip, upper/lower controller ownership and attachment changes. Instrument the disposable copy and record the instrumentation hash.
- Scenario expectations for dying/removed subjects and dynamic arena/corpse units, so expected lifecycle events do not become false capture failures or hide premature death.
- Deterministic prop/variant coverage as explicitly labeled fixtures, followed by natural gameplay coverage with original procedural choices preserved.
- Better follow cameras for two actors and dynamic arenas; a one-actor camera can hide important contact errors.

Never expand the scenario language to execute arbitrary supplied Lua. Keep named, typed actions and preserve the existing source/output isolation and failed-run evidence.

## Captures, sampling and acceptance

Start with seed `1337`, side and three-quarter views. Once a case works, add `2026` and `7301`, front/rear views where contact or asymmetry matters, then targeted seeds until every recorded procedural branch has actually been observed. Three seeds are a starting sample, not proof of exhaustive coverage.

Use three-frame intervals for broad locomotion and one-frame intervals for hits, contact, death, snap transitions and interruptions. If rendering misses samples, retain the gaps and rerun with an adjusted capture load; never synthesize intermediate poses to manufacture smoothness. Include lead-in, action/loop and recovery. Record engine, map, source and asset hashes, unit IDs, seed, creation order, terrain and view.

For every case, inspect each phase contact sheet, original adjacent PNGs at boundaries/flagged frames, and video at observed timing. Review silhouette, continuity, plausible joints, foot planting, ground penetration, prop contact, attachment alignment, pose ownership and correct exit. Telemetry is supporting evidence, not a substitute for images.

Ledger statuses: `not_reviewed`, `needs_target_triage`, `blocked_by_rig`, `needs_scenario`, `capture_incomplete`, `needs_visual_review`, `changes_required`, `accepted`, and `not_applicable_with_reason`. A mechanically complete run is only `needs_visual_review`. The run's own `analysis/review.json` uses the workflow's reviewer outcomes (`accepted`, `changes_required`, or `inconclusive`); do not insert ledger-only statuses there. Preserve its evidence hash and put the reviewer, exact frames/images, expected/observed behavior, severity and confidence in each finding.

P0: runtime failure, missing required body pieces, corrupt evidence or source mutation. P1: broken hierarchy/contact, frozen animation, severe penetration, wrong state/attachment or missing recovery. P2: visible timing/pose/prop defects. P3: minor polish. Fix a demonstrated defect on an isolated feature branch, run relevant external regressions, then compare the same scenario/seed/view before expanding coverage.

## Extension pass for the rest of the animation work

After the above gates, inventory every remaining active unit-script animation source, not just files named `animation*`. Add police (`animations_police.lua`), recruited/paired civilians, ground walkers (`animations_ground_walker.lua`), hologram people and `tigLilAnimation.lua` consumers, and the supplied text-FX cycle. Then inventory vehicle occupants/turrets/deployment, aircraft/VTOL/crashing, buildings/assembly/damage and other procedural unit effects as separate families with their own rigs and expectations. These counts are not included in the initial 74 entries.

Existing external tests that support the human review include `operative_animation_arguments_test.lua`, `prayer_animations_test.lua`, `civilian_death_test.lua`, `civilian_parade_test.lua`, `aerosol_behaviour.lua`, `asset_rooftop_test.lua`, and `civilian_western6_disabled_test.lua`. Run them via `/home/picasso/MosaicDev/tests/MOSAIC/run.sh -- lua tests/<file>.lua` when touching those systems. Passing them does not certify visual quality.

## Finish criteria

Every enabled model has a recorded rig decision; every active clip, procedural behavior and relevant transition has evidence or an explicit blocker/design decision; high-severity findings are resolved and recaptured; completed reviews link immutable evidence and source hashes. Preserve content diversity. Do not declare the review complete from one model, one seed, one camera angle or a green unit-test run.
