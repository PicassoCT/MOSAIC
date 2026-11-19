# Model standardization TODO

This is the separate model-work list for Picasso. It records the current authored files in `~/.spring/games/Mosaic.sdd/objects3d`. **The original audit below predates the user’s re-exports; the current status section supersedes its civilian findings.** Checked names and parent relationships are confirmed static findings; pose, scale, and visual consequences still need engine verification. The detailed source hashes and node records are in [inventory.json](review_inventory/inventory.json).

## Current civilian export status

Rechecked after the user’s model repair pass. Static checks only; runtime acceptance remains pending.

- [x] All 12 civilians have the 16 required core names, with no duplicate names and correct immediate parents.
- [x] `civilian0_arab` and `civilian4_arab`: `Hand1` and `Hand2` added under the corresponding forearms.
- [x] `civilian2_arab` and `civilian3_arab`: corrected root/center/torso chain and legs under center.
- [x] `civilian3_western`, `civilian4_western`, `civilian5_western`: corrected upper-leg parents.
- [x] `civilian4_western` and `civilian5_western`: center now at pelvis height (about 51.0% and 52.8% of body height).
- [x] `civilian5_arab`: center moved from foot level to 49.89% of body height (hip midpoint 44.83%). All 95 pieces, UV arrays and triangle counts retained. All world-space mesh vertices preserved within 0.00019 authored units. Core hierarchy passes. The remaining ~5.06%-of-height offset above hip midpoint should be judged during animation review; static correction is complete.
- [x] `civilian2_western`: user-authorized `Handbag5` removal recorded; `Deco3` added. Do not restore that removed variant automatically.
- [ ] Western 2’s remaining bag variants still have no exact `Handbag` target for `UPBODY_LOADED`. Resolve or explicitly exclude the missing target in the animation mapping; removing `Handbag5` alone does not resolve this.
- [ ] Review hand/prop motion, Western 4/5 torso geometry changes, and Arab 4’s intentional pose-switched cloth covers in the engine. Preserve the cloth-piece names and behavior.
- [ ] Anatomical placement review remains for `civilian0_western` and `civilian3_arab`; neither is a foot-pivot outlier.

All composed center-axis directions agree within export rounding. Raw scale differences alone are not grounds for resetting transforms. Western 3 also renamed `cofee01`/`cofee002` to `cofee1`/`cofee2`; include these props in runtime coverage. Operative and animation-code tasks below remain open.

Latest measurements: `/home/picasso/MosaicDev/transform-audit/civilian-centers/audit.json` and `pivot-comparison.png`. Earlier reports and unchecked historical table rows below describe the initial audit, not the present export state.

## The target standard

Use **civilian0_western.dae as the initial civilian hierarchy reference**, not as a requirement to copy its body shape, scale, clothes, or proportions. Its hierarchy supplies the common body names plus hands. Verify its pivots and axis directions in Recoil before treating its transforms as a reference.

```text
root
└── center                         pelvis and whole lower-body motion
    ├── UpBody                     torso, independent of pelvis/legs
    │   ├── Head1
    │   ├── UpArm1 → LowArm1 → Hand1
    │   └── UpArm2 → LowArm2 → Hand2
    ├── UpLeg1 → LowLeg1 → Feet1
    └── UpLeg2 → LowLeg2 → Feet2
```

Operatives keep their existing compatible **center → Torso → Head** naming and leg/arm chains. Use **operative_propagator.dae as the initial operative hierarchy/hand reference**. Do not rename `Torso` to `UpBody` or `Head` to `Head1` without a deliberate, coordinated animation/script migration. A shared semantic body contract can map these names between families; merely renaming them does not retarget an animation.

The common contract must specify parentage, joint-axis directions, neutral pose, pivot placement, forward/up directions, unit conversion, and required attachment sockets. Keep optional equipment in named sets. Preserve body types, clothing, all bag variants, hair, coat bones, and procedural variation.

For reparenting, preserve each piece's world-space rest transform: compute the new local transform from the inverse new-parent world transform and the old child world transform, using the DCC's matrix convention. Preserve mesh placement and, where applicable, bind matrices/weights. Re-export and verify in the engine. Do not drag parts into a similar-looking pose and assume their pivot frames match.

## Civilian models

All 12 present civilian models have the 14 currently checked core body names. Five differ in core parentage. This is a compatibility risk because the shared animations and upper/lower-body masks assume independent pelvis, torso, and limb control.

| Done | Exact model | Confirmed mismatch | Work needed for the proposed standard |
| --- | --- | --- | --- |
| [ ] | `civilian0_arab.dae` | No `Hand1` or `Hand2` nodes. Core hierarchy otherwise matches. | Add properly placed hand joints/pieces under the corresponding lower arms if hand-articulated clips are to be shared. Preserve visible hands and prop alignment; engine must retain the new nodes. Recheck prayer and passenger poses. |
| [ ] | `civilian1_arab.dae` | Core hierarchy and hands match. Its authored root matrix uses an identity orientation plus translation, unlike most other civilians' rotated root. | Check the complete ancestor/mesh transforms and engine import; normalize the export's root/axis convention only with compensation that preserves the visible pose. Verify all three rotation axes and foot contact. |
| [ ] | `civilian2_arab.dae` | Current chain is `root → UpBody → center`; legs descend from `center`. | Change to `root → center → UpBody`, keeping legs on `center`. Preserve world-space rest pose. Revalidate pelvis translations, torso-only aiming/prayer, wounded gait, and death. |
| [ ] | `civilian3_arab.dae` | Same inverted pelvis/torso chain as Arab 2. | Apply the same world-pose-preserving hierarchy correction. Keep this model's proportions and equipment. Repeat walking, seated, wounded, and collapse captures. |
| [ ] | `civilian4_arab.dae` | No `Hand1` or `Hand2`; core hierarchy otherwise matches. | Add compatible hand pieces/joints as for Arab 0; retain weapon, RPG, bag, and shopping-bag attachments. Verify wrist pivots and prayer gestures. |
| [ ] | `civilian5_arab.dae` | Core hierarchy and hands match. Authored root basis has scale magnitude `15`, versus roughly `0.89–1.20` for most other civilian roots. | Audit the complete scale chain and rendered size. This does **not** prove a 15× oversized model: mesh/child transforms may compensate. Consolidate equivalent scale into the agreed export convention without changing intended stature, limb lengths, or animation travel. |
| [ ] | `civilian0_western.dae` | No checked hierarchy/name mismatch; proposed reference. Root basis magnitude is about `0.888277`. | Establish a baseline engine rig dump and neutral/axis poses. Verify feet, hands, sockets, local axes, and mesh bounds before approving it as the reference. Do not blindly copy its offsets to other bodies. |
| [ ] | `civilian1_western.dae` | No checked hierarchy/name mismatch. Authored root has scale/translation differences. | Retain hierarchy. Verify normalized axis/pivot contract and attachment positions; record intentional stature differences. Only change transforms where engine measurements show incompatibility. |
| [ ] | `civilian2_western.dae` | No exact `Handbag` node; variants include `Handbag1`, `Handbag2`, `Handbag003`, `Handbag004`, `Handbag5`. Shared `UPBODY_LOADED` targets `Handbag`. | Agree a canonical bag socket/piece and an explicit mapping for variants. Preserve every bag variant. Either supply the required target with correct ownership or update the animation's selected-bag mapping together with code; do not rename one randomly and discard the others. |
| [ ] | `civilian3_western.dae` | `UpLeg1` and `UpLeg2` are children of `UpBody`, not `center`. | Reparent both upper legs to `center`, preserving rest pose and all descendant transforms. Verify torso-only gestures no longer rotate/drag the legs, then test coverwalk, wounds, and death. |
| [ ] | `civilian4_western.dae` | Both upper legs are children of `UpBody`. | Same correction as Western 3. Keep its proportions and props; check stop/start, kneeling, passenger pose, and terrain contact. |
| [ ] | `civilian5_western.dae` | Both upper legs are children of `UpBody`. | Same correction as Western 3. Verify the weapon-carrying upper-body overlay independently of walking legs and repeat death captures. |
| [ ] | `civilian6_western.dae` | File is absent; `units/neutral/civilian_western/Civilian_western6.lua` deliberately disables the unit. | Keep disabled. Treat restoration as a separate content task: locate/build the model, conform it to the agreed rig, validate all required assets/animations, then explicitly enable it. Do not count it as reviewed. |

### Civilian cross-model work

- [ ] All 12 models expose `Head1`, while the shared `PARACHUTE_POSE` contains `Head` targets. Prefer correcting/mapping the civilian clip to `Head1` over renaming every model. Check whether this clip is actually reachable for civilians before scheduling its gameplay test.
- [ ] `UPBODY_PRAY` references hands missing on Arab 0/4. Distinguish this legacy entry from the eight registered `UPBODY_PRAYER_1…8` entries; test what the gameplay path actually selects.
- [ ] Shared setup currently removes commands for missing pieces. Check the resulting command array and playback coverage; absence of a Lua error does not establish that the intended motion survived.
- [ ] Compare actual engine piece maps, parents, local rotation axes, bounds and rest transforms with the authored COLLADA records. The current report does not normalize Assimp conversion or sidecar transforms.
- [ ] Audit each matching `.dae.lua` sidecar alongside its model. All checked COLLADA assets declare `Y_UP` and `meter=0.025400` with the label `centimeter`; document effective importer units instead of guessing from that label. Do not change scale declarations alone.

## Operative models

The three operatives agree on the checked 11 core names and immediate parents. Their authored transforms, extra pieces, and animation tables differ. **They are not yet certified as interchangeable rigs.**

| Done | Exact model | Confirmed difference | Work needed for the proposed standard |
| --- | --- | --- | --- |
| [ ] | `operative_asset.dae` | No `Hand1`/`Hand2` nodes; its weapons attach within the existing arm hierarchy. Uses its own 9-entry animation table. Root `center` has a different scale/offset from the other operatives. | Add compatible hand articulation/sockets if clips will be shared; preserve pistol, gun, sniper rifle, muzzle flashes, grappling hook, ropes, and `hostagePoint`. Normalize axes/pivots with mesh compensation only after engine measurement. Keep asset-specific animation behavior. |
| [ ] | `operative_propagator.dae` | Common core and hands present; 70 named coat bones, coat alternatives, laptop states and `hostagePoint` are model-specific. Uses 11 animation entries. | Use as the initial operative hierarchy reference; establish approved neutral/axis poses. Keep all coat bones and coat variants. Check hand-held laptop/pistol, human-shield socket and coat clearance in crouched/fighting/death poses. |
| [ ] | `operative_investigator.DAE` | Common core and hands present. Hair/tail, drone, jaw and extra scene node `fem` differ from the propagator. No exact `hostagePoint` in the authored node list. Uses 18 animation entries. | Preserve its distinct silhouette, hair/tail, drone and idle gestures. Measure retarget axes and offsets against the operative reference. Add a shield socket only if investigator shield support is deliberately enabled; absence alone is not a bug. Keep the uppercase source filename accounted for in export/packaging. |

None of these authored operative node lists includes separate `Feet1`/`Feet2` pieces. Do not require them accidentally by applying the civilian schema. If articulated feet become part of a new cross-family standard, add them as a coordinated model/animation migration for all operatives, with explicit acceptance tests.

## Animation code issues to handle alongside model work

These are not mesh edits and should stay in the code backlog:

- [ ] `scripts/animation_assasin_male.lua:23–24`, `FIGHTING`, `UpArm2`: Y and Z commands contain unkeyed values `0` and `-60*deg_1` instead of `t=...`. The player defaults missing `t` to zero, so the Z command currently loses that authored nonzero value. Confirm the intended pose, make targets explicit, and compare the fight sequence before/after. This is not presently evidence of a nil-target crash.
- [ ] Resolve civilian `Head`/`Head1`, missing legacy prayer hands, and Western 2 bag targets without deleting clips or procedural variants.
- [ ] Cross-check runtime-selected names against each bank, including asset references such as `PARACHUTE_POSE` and `SLAVED` that are not keys in its loaded nine-entry table. Determine reachability and state ownership before adding, redirecting, or retiring anything.

## Completion checklist for every changed model

1. Save an isolated feature branch and the original model/sidecar hashes. Record the exact node changes.
2. Export without missing or duplicate required names; verify parentage and sidecar/import settings.
3. Compare neutral silhouette, world bounds, intended stature and all original props against the old model. Preserve authored diversity.
4. Run small positive and negative rotations on each joint axis plus pelvis/root translations. Inspect actual rendered pivots and limb direction.
5. Capture idle → walk/run → stop, torso gesture while walking, wounded/cover movement, seated attachment and every applicable death mode. Include side and three-quarter views; front/rear for asymmetry.
6. Retest prayer, fleeing, weapons, carrying, hostage and close-combat cases appropriate to that model. Record exact frame/image evidence in the lab review ledger.
7. Approve a model only when the static rig contract, engine piece contract, and visual regression all pass. A familiar-looking rest pose alone is insufficient.
