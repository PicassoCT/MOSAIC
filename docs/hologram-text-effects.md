# Letter-piece holograms

Western and brothel signs share inventory-aware phrase selection and slot allocation in `scripts/lib_textFx.lua`. Complete phrases are preferred without editing the source phrase pools. If none fit, the full pool remains available. Unavailable glyphs occupy one logical slot (including one slot per unsupported UTF-8 character), preserving spacing. Repeated supported glyphs borrow an already allocated physical piece: original and borrowed positions alternate instantaneously every 500 ms during readable holds. A donor with several borrowed positions cycles through them in source order. The layout stores unique physical IDs separately from logical slots.

A single text owner schedules the leases; other text effects do not compete with a background leasing thread. Static signs also run readable holds. Authored highlight glitches, RGB ghosts and night flickering remain. An obsolete highlight worker is stopped when changing phrases. Text restoration now uses a 400-ms engine-interpolated arrival; phrase replacement also uses a 400-ms departure. These are movement transitions, not opacity fades. Unit-script Show/Hide does not expose opacity. Glow-worm reveals retain their deliberate stepped visibility but correctly split the requested flicker lifetime and handle empty groups.

The shared effect review repairs piece/axis arguments, missing all-piece waits, the circle radius parameter and no-rest flag, the personal projection's civilian identity, scratch-global leakage, empty inputs, repeated-gap spacing in curved effects, and the duplicate wait helper. Matrix arrivals place every axis before dropping. Waterfall restoration targets each actual axis. The cube's loop index is no longer mutated.

## Upright spiral and helix axis

Glyph layout, drops and individual-letter yaw use local Z. The whole text spinner has a separate `textSpinnerAxis = y_axis`, restoring the parent rotation used before `eb6c1863`. Sharing the glyph Z axis with the parent caused the entire upright pillar to tip over in game. Setup, personalized facing, and spin pause/resume after conga or takeover all use the separate parent axis. New messages still reset the spinner before choosing a new rotation so a previous personalized facing cannot leak into a static sign.

The DAE basis test checks exported bind poses and glyph geometry; it does not establish the running engine's parent rotation behavior. The Y-axis restoration follows the reported in-game regression and still needs a live visual recheck.

Spiral now always uses the visually approved vertical variant: radial engine components 1/2, upward progression on component 3, and its existing facing and spacing. The lengthwise branch is removed from the shared library used by the house, brothel and blimp scripts, and from the preview cycle. Its old horizontal/upright console labels described the starting text layout, not the resulting spiral orientation. DNA helix also replaces either starting layout with a vertical staircase. Spiral, DNA helix, arch, tornado, smile and plant accept either starting layout; matrix is selected only for upright text.

DNA pairs consecutive available letters at the same height, on opposite sides of the helix, with their backs toward each other and fronts facing outward. Each successive pair rises by `sizeDownLetter` and advances by π/7 around the vertical axis. Spaces have no mesh and do not consume a partner; an odd final letter occupies the last step alone. The radius remains seven letter spacings divided by 2π. The whole staircase rotates rigidly through the parent spinner for 15 seconds, using the selected parent speed/direction or 20°/s when no rotation was selected. That temporary default spin is stopped and its heading reset after the letters hide; an existing parent spin continues. Glyph placement/yaw use explicit engine components 1/2/3 to avoid the header's swapped aliases.

Arch divides a semicircle into equal angular cells and applies a 2D rotation matrix to each slot position in the DAE Y/Z text face plane. Glyphs remain unrotated; spaces and unavailable glyphs reserve their cells, giving uniform spacing along the curve. Up to 20 logical phrase slots use one arch; longer phrases split evenly across two stacked arches, with the first half above the second and at least 1.25 glyph heights between the rows. The radius uses the longer row's slot count and the configured letter spacing; exceptionally long phrases enlarge both arches instead of dropping letters. It supports both initial layouts and keeps its 35-second hold.

Cube wraps the phrase around the four vertical faces of an invisible square cube. Letters stay upright and face outward, turning by 90 degrees at each corner. Logical slots are balanced across the faces, with cell centres keeping letters away from corners and spaces preserving gaps. Phrases over 20 slots continue on a second row around the same cube, 1.25 glyph heights below the first. The side length grows with the busiest face to retain the configured letter spacing; no phrase content is truncated or duplicated. The effect keeps its 35-second hold and hides the letters afterward.

Fireworks launches balanced groups of up to 12 available letters from one shared world-space point just above the terrain under the sign. A group rises together for two seconds, then expands over one second into a complete circle in the sign's vertical text plane. Letter order and word gaps are retained, all glyphs stay upright, and the burst pauses for three seconds. It then accelerates downward over four seconds while preserving its arrangement; each glyph disappears at its own ground contact. Groups launch sequentially with a half-second gap. World-space conversion accounts for model scale, heading and differing glyph bind offsets. Radius and launch height follow the glyph proportions. Parent rotation pauses during the effect for readability and resumes afterward if it was selected. A circular phrase is read clockwise from its crown; legibility still depends on camera angle and needs a live visual check.

The production script header defines `x_axis=1`, `y_axis=3`, `z_axis=2`; these aliases are not the DAE axis names. Circle therefore uses explicit engine components 1/2 for its ground-plane spread and component 3 for upright yaw. Arch, cube and DNA also use explicit glyph components; fireworks uses world-space targets rather than the circle effect. The circle's radius, angular span, facing direction and hold duration are unchanged. The projection regression loads the actual header aliases; the preview scheduler does too. Ring projects a full 360° circle in the DAE Y/Z text plane, reading clockwise from its crown with upright, unturned glyphs and preserved logical gaps. Its lowest point stays at the original text baseline. It retains its authored radius unless more clearance is needed between letters, waits for the two-second formation move, then holds for 15 seconds. Parent spin pauses during the readable hold and resumes afterward; individual letters no longer spin edge-on. Personalized signs convert civilian positions into the imported text plane using the unit's heading, and restore the ordinary spin afterward. Deliberate face-plane rocking in conga and takeover effects remains.

## Playback speed

Each selected effect runs at a fresh random multiplier between 1.00x and 3.00x. Movement and angular speeds scale together, effect sleeps shorten proportionally, and spin acceleration/deceleration scale quadratically to preserve their ramp timing. Rates are scoped to the effect coroutine; Tiglil and the preview’s five-second gaps keep their own timing. The original parent spin resumes at its selected speed afterward. Preview console messages and the `text_fx_test_speed` unit rule expose the chosen multiplier. Calling `runHologramTextFx` with a final numeric argument selects a fixed rate, clamped to the same range.

## New effects

**Wall impact (`wallImpactText`):** a staggered volley of letters flies toward a nearby house, mixing straight bullet-like arrivals with spinning throwing stars. Each letter settles against the wall; the complete phrase holds for four seconds before returning to the sign. Visible piece bounds supply upright wall faces, including imported scale and house rotation. Long phrases wrap into rows; word gaps and repeated-letter leases retain their slots. Walls must fit the glyphs at their existing size. Missing, unfinished, too-small or destroyed houses exit cleanly. Both starting layouts and the shared 1–3× speed multiplier are supported. Place the preview unit near a house to see this mode.

**Spline following (`splineShapeFollowing`):** upright letters traverse a short randomized cubic Bezier curve in source order, entering every 300 ms. Spaces reserve their delay; repeated glyph meshes alternate between active occurrences. An arc-length lookup keeps travel speed steady through bends. The lead letter takes at most 12 seconds, and the last letter finishes at most `12 + 0.3 × (logical slots − 1)` seconds after the first enters. There is no extra hold. The effect restores the phrase and parent spin afterward; both initial layouts are supported. Engine-interpolated motion updates at 20 Hz.

- **Civilian conga:** chooses a live civilian within 650 world units, drops the physical letters to terrain height over 800 ms, and follows a bounded path history with phased sway and hopping. Letter spacing uses the authored glyph's transformed bounds. A cached inverse of each glyph's parent-world basis accounts for house heading, parent rotation, imported scale and axes. Motion updates at 5 Hz for at most 16.6 seconds, ending early on disappearance or departure beyond 750 units. Letter leases also rotate through conga positions. No civilian orders, MoveCtrl or new gadgets are involved.
- **Hostile takeover:** selects a different phrase from the sign's existing phrase pool and places it below the original. Private glyphs stay in formation and recoil while shared physical glyphs shoot across the gap in opposing directions on a 500-ms beat for 12 seconds. Each shot travels through a raised midpoint for 120 ms, lands over 130 ms, then holds for 250 ms; engine interpolation supplies the motion. There are no weapon projectiles, damage, extra letter meshes or per-frame workers. Repeated occurrences cycle through their leased slots too. The original layout is restored afterward.

**One-armed bandit:** horizontal text becomes a row of slot-machine wheels, with up to three spare alphabet glyphs per wheel. Symbols travel in a vertical circle and turn with the wheel. Characters absent from the phrase are preferred; a limited alphabet can use spare copies of other characters, never the wheel’s winning character. Six free revolutions lead into sequential stops from left to right. Each final letter replaces a rear symbol and rolls to the front; all remaining wheels keep turning. Locked letters stay still. The effect borrows only available meshes and hides/resets them afterward. Spaces remain empty, repeated-letter leases resume during the final three-second hold, and the selected parent spin returns.

**Meteor crater:** the first glyph leads the slogan down a diagonal wake into a common ground impact. Letters scatter in tumbling ballistic arcs, then reform the original phrase around a terrain-following crater rim for six seconds. Word gaps keep their slots and repeated glyphs rotate through their leases. The effect restores the original layout and parent spin, uses the actual model scale and unit heading, and bounds its movement waits. It creates no terrain damage or separate rock mesh.

**Letter tornado:** the phrase winds upward around an expanding cone, with eight logical slots per turn and word gaps preserved. Letters stay upright with the corrected cube/DNA facing. The letters orbit the cone in their actual horizontal plane at 30 Hz for 15 seconds, with their facing following the orbit. Speed is at least 60°/s and follows the selected direction; the parent stays still during the effect. It then restores the phrase for a three-second hold and resumes the previous parent spin.

**Heart monitor:** a separate mode; the existing `SinusLetter` is unchanged. Two ECG-shaped pulses travel along one straight line, including a small lead-in, negative dip, sharp upward spike, undershoot and recovery. Only glyph height changes. Word gaps remain, parent spin pauses for readability, and the line returns to its baseline before restoring the original layout.

**Smiling face:** letters form exactly two eyes and a curved smiling mouth in the text plane, without a nose or face outline. Tiny phrases can borrow unused alphabet pieces to complete the features. Every borrowed piece is hidden/reset afterward; the original phrase and selected parent spin return after a seven-second hold.

**Letter plant:** letters sprout from terrain beneath the sign, first growing a vertical stem from the ground and then alternating branches from that stem. Growth uses the imported model's scale and heading; branch ends stay above the terrain. After a six-second grown hold, the original phrase and selected parent spin return.

**Travelling push (`syncToFrontLetters`):** a four-slot-wide pressure wave travels behind one straight line of text, pushing neighbouring letters forward in depth and smoothly releasing them back to the same positions. No glyph rotates or leaves its baseline. This remains distinct from the vertical heart-monitor pulse.

**Cross letters:** two phrase segments cross at a shared character, preferably near the middle of both segments. A near-middle space is preferred for splitting. The intersection uses one physical glyph; the duplicate occurrence is hidden during the cross. If the segments share no letter, the existing middle glyph becomes their junction without inventing or reordering text. The layout holds for seven seconds and restores the phrase.

**Matrix:** three repeats of the same motion used by `consoleLetters`, arranged as a vertical column at eight times the normal console speed. Each repeat waits for its moves to finish and holds for 150 ms. The ordinary console effect retains its original layout, speed and ten-second hold.

The uniformly selected catalogue now has 30 modes: each has a **1/30 chance (~3.33%) per selection**. Sign eligibility and layout gates still apply. Conga requires a nearby live civilian; takeover requires another phrase. Ineligible effects return without a new retry loop.

## Validation

Run from the repository root with Lua 5.1:

```sh
luac5.1 -p scripts/lib_textFx.lua scripts/house_western_hologram_script.lua scripts/house_western_brothel_hologram_script.lua
lua5.1 tests/hologram_text_fx_test.lua
python3 tests/hologram_text_axes_test.py
```

The regression suite executes the real shared library and both scripts' production functions with strict animation-call mocks. It covers exhaustion, direct occurrence ordering, UTF-8 gaps, selection, logical spacing, half-second leases and restoration, matrix parameters, radius/no-rest handling, glow lifetime, all 30 registered modes, empty groups, parent rotation/scale inversion, conga lifecycle, takeover crossfire timing/trajectories, slot-machine reel ownership/ordered stops, projection geometry, travelling pulses, terrain-based growth, borrowed-piece cleanup and scratch-global isolation. CI uses native Lua 5.1; local validation can also run the same suite through `lupa.lua51` (Lua 5.1).

No Recoil visual or target-hardware performance validation has been performed. In Recoil, check a long repeated-letter slogan, day/night and blackout transitions, all projection modes, conga descent on slopes and rotated houses, turns/stops/death of the target civilian, and takeover cleanup when a phrase changes or the hologram is destroyed. Confirm glyph size, facing, ground clearance and movement timing against actual exported models. Compare zoomed-out frame times in a dense city.

## Ordinary-model test unit

Start a new local match, enter `/cheat`, then `/give text_fx_test` to spawn at the
cursor. It uses `house_western_hologram.dae` and the real `lib_textFx.lua` functions,
with ordinary engine Show/Hide drawing and no neon registration. The phrase is
`Lorem Ipsum`; console messages identify each mode, layout and parent rotation.
Tiglil dances continuously alongside the letters using the shared smoothed drum,
solo footwork, shuffle, disco, popping, acrobatic poses, full backflip/handstand, headshake and dance routines.
Each routine echoes its name. `idle_stance17` now performs six phrases of solo footwork with controlled turns; `idle_stance4` and
`idle_stance5` are separate, explicit acrobatic entries. This preview has no night-only eligibility
or shared performer cap, and text cleanup never hides the dancer. Both loops
and their child animations stop when the unit is destroyed.

Each case runs its shared animation to completion, allows about five seconds
for remaining finite glyph moves/turns, then holds for five simulation seconds
before the next case. Cleanup immediately hard-resets already-hidden glyphs;
if visible cleanup exceeds the deadline, it hides and hard-resets those too.
Reset replaces queued engine targets before snapping and leaves the glyphs
hidden for an engine tick so an old target cannot pull the next layout apart.
The production signs use the same cleanup. Tornado formation has a 2.5-second movement deadline. In the test unit, phrase restoration has a 1.5-second deadline; stalled movement targets are cancelled and the phrase is restored so the cycle can continue. Recovery emits a diagnostic in the console. Conga tracks actual piece translations
when calculating speeds, and fireworks bounds its launch/burst/fall waits too.
Continuous spins keep running during the hold. All glyph transforms/spins are
reset between cases; long effects are no longer cut short. The cycle has
96 cases: plain horizontal/upright text, all 29 runnable shared modes (matrix and arch use
upright), an extra upright DNA-helix case, each at 0, +20 and -20 degrees/second
around the same parent Y axis used by production holograms.

Existing effect eligibility is preserved: personal projection and conga need a
nearby civilian; night flicker needs night. Achromatic shivering rejects repeated
letters, so `Lorem Ipsum` makes it return without animating; the console notes
this. Takeover uses `Ipsum Lorem` as the opposing phrase. The external
`text_fx_test_unit_test.lua` runs the actual shared functions with a unit-thread
scheduler and verifies coverage, completion-before-hold timing and parent rotation. Live model
appearance still needs an in-game check.

## Tiglil motion

The Journeywar performer remains in `scripts/tigLilAnimation.lua`, used by both
western hologram scripts and the advertising blimp. Its authored poses, routine
order, random branches and holds are retained. Scoped helpers route movement
through `lib_tiglil_motion.lua`; other hologram animations use their existing
helpers.

One worker per active performer updates native speeds at 30 Hz toward the
original final targets. Quintic easing softens starts and stops; interrupted
poses carry forward same-direction velocity without overshooting. Native
`WaitForMove`/`WaitForTurn` still wait for the final pose. Speed-based movements
retain their nominal duration with a 100 ms minimum blend. Timed poses keep
their requested duration subject to that minimum. At the end of easing, a native
completion step uses at least the authored speed so float precision cannot
leave a turn queued forever. The synchronized yoga helper
uses a common arrival time and avoids division by zero on neutral angles.
Spins without authored acceleration/deceleration use a 180 ms ramp; explicit
spin settings remain intact. Setup and show shutdown cancel the motion worker,
and hidden shutdown resets replace queued engine targets.

The external `tiglil_motion_test.lua` checks trajectories, shortest-angle turns,
native waits, interruptions, cancellation/restart and real setup, gait, pose,
yoga and shutdown callbacks. `tiglil_precision_test.lua` also models the engine’s
float32 angle normalization and runs setup plus all six preview routines.
This is procedural smoothing, not captured motion;
foot contact, silhouette and perceived weight still need a fresh-match visual
check with the actual model.

Flute grips use five poses calibrated to the shorter arms and instrument of the
three hologram rigs (`lib_tiglil_flute.lua`). Shoulders and the mouthpiece remain
at their bind positions; palm contacts lie on the flute with separate grips.
Both musical variants and the up/down sway remain, and grips settle before
their readable hold. The flute tests cover the actual DAE contact geometry and
force both branches through the float32 animation scheduler.

The backflip waits for its last 3 rad/s landing turn before normalizing the
body angle. Its trajectory test checks a full revolution without the former
fast-reset snap at the end.

## Solo dance styles

`idle_stance17` replaces the old deep tango dips and abrupt quarter-turn resets
with six phrases of crossing steps, side weight shifts and opposing arm sweeps.
`danceShuffle` uses running-man lifts and heel-toe steps; `danceDisco` alternates
diagonal overhead reaches and side steps; `dancePopping` uses short torso and arm
accents with deliberate holds. Every routine works without a partner or props.

The routines share `lib_tiglil_dance.lua`, use the existing Tiglil smoothing and
retargeting, randomly mirror their choreography, and finish in a neutral stance.
Body height follows the supporting foot using the exported leg geometry instead
of an arbitrary vertical bob. Both western holograms and the advertising blimp
include the new routines; the western techno pool includes them too. The preview
announces each style by name. Model and scheduler checks do not replace a live
visual review of timing, foot sliding and silhouettes.

`danceJoi` adds a solo routine inspired by the overhead reach, alternating arm
sweeps, hip rocks and turning steps in the [user's reference](https://www.reddit.com/r/bladerunner/comments/z83alc/the_joi_dance_was_trending_on_tik_tok_so_i_made/)
and its linked [source clip](https://www.youtube.com/watch?v=6Ov9EL709cc).
It performs four 16-beat phrases with gradual quarter-turns, then settles to
neutral. This is a rig-adapted interpretation: Tiglil's rigid arm pieces cannot
reproduce the reference's elbow bends. The clip and audio are not game assets.
The preview includes `danceJoi (Joi-inspired solo)` alongside the other solo styles; normal and techno pools
include it alongside the other styles.

The circle/drum dance retains its five laps, randomized quarter-lap stops,
overhead/front drum gestures and both twirl directions. Its torso now leans at
most 8 degrees forward/back and 4 degrees sideways, with at least 450 ms for
body changes and 300 ms for limb changes. Twirls use 3 rad/s instead of 7 rad/s,
retain the entry heading, and settle upright before the next orbit segment.

## Pole choreography

`dancePole` now performs an approach, walking turn, tucked spin, two-stage climb,
inverted overhead split, sideways tucked hold, extended-leg turn, free-arm flourish
and controlled descent. The split opens from an inverted tuck, straightens both
legs into a full straddle above the head, holds for 1.2 authored seconds, and folds
back before the sideways hold. Both hands remain on the pole throughout.
The old sideways pose and folded-leg silhouette survive as a short adapted hold;
the drum branch still calls the routine at its current stage height. It is also
selectable independently in `text_fx_test`.

The body moves around the pole's actual centre while the pole remains stationary.
Hand contacts follow the imported shoulder offsets and rigid arm lengths; a free
arm returns before the other releases. Piece offsets and bounds account for the
blimp's different pole mount and shorter pole, limiting its climb accordingly.
Interpolated grips, floor clearance, completion, cancellation and restoration of
parent placement are tested. Shoulder arcs approximate grip changes on this rig,
which has no elbow joints; live visual review is still needed.

Pole routines are now composed from support-compatible components, rather than
playing one fixed list. Each performance varies orbit direction, tempo, aerial
skill order, fan-kick direction and two to four floor-bridge lifts. The split,
salvaged sideways tuck, climb, extended-leg turn and descent remain present.
Grounded body waves can precede the orbit; fan kicks return to a two-hand hang.
A lowering lunge connects the grounded descent to floor work, and a supported
rise closes the routine.

For the floor bridge, the dancer lies back, bends both knees and raises/lowers
the pelvis. An analytic two-bone solve keeps the feet planted while the torso
pivots about the upper back. Tests check actual mesh clearance for the head,
torso and feet, as well as planted-foot stability through native interpolation.
Forty seeded compositions cover both directions and all retained components.
Each show now also selects one held accent: a raised stag, long-leg diagonal,
or supported pike. Both hands stay on the pole for these shapes. The new accents
are shared wherever the pole routine already plays.


## Standalone ballet

`danceBallet` is a separate solo routine, available in all three hologram idle
pools. The preview announces it as `danceBallet (solo ballet)`.
The roughly twenty-second phrase includes a demi-plié, overhead port de bras,
left/right side extensions, a held arabesque, a raised-knee full turn, a soft
landing and a closing reverence. Each performance can mirror the choreography.
It does not invoke the pole sequence or display its prop.

The torso stays upright, with a modest forward inclination for the arabesque
and bow. The existing rigid arms and feet limit classical elbow/ankle positions.
Four timed quarter-turn targets preserve a full revolution despite the engine's
shortest-path rotation rules; stationary balances do not rotate the stage.
Native scheduler checks cover both turn directions, floor clearance during
transitions and a neutral exit. Mesh checks cover the poses on all three models.


## Western business advertisements

Only `house_western_hologram_buisness` adds `advertiseSales`, `modelWalk` and
`presentGala` to its existing techno selection. The ordinary idle, casino,
brothel and blimp pools do not register them. Diagnostic `text_fx_test` previews
all three first and announces their business-only labels.

The sales routine welcomes the audience, directs attention to each side of a
display, explains features with arm gestures and head nods, and closes with an
invitation. The runway routine walks eight body units forward, holds front and
profile poses, turns, walks back and faces the audience again. The gala presenter
walks to a nearer mark, addresses the audience, introduces a guest to one side,
thanks the audience and walks back. Walk-and-talk is conveyed through gestures;
these routines do not add speech audio. They mirror between performances, keep
limbs attached, and return to neutral at the starting mark.

The controller clears glow sticks between routines and uses them for the existing
techno dances only. Tests execute the production pool selection for business,
casino and ordinary holograms, check that old dances remain available, and verify
prop changes between a dance and a presentation. Native motion tests cover both
mirrors of each new routine; model tests check grounding against the DAE meshes.


## Street conversations

`idle_stance` and `idle_stance2` can project beside a nearby stationary civilian
on the normal western and brothel building holograms. The blimp does not enable
personalized animations and retains its stage presentations.
A clear, nearly level patch is selected within 400 world units of the hologram;
trucks, buildings, dead or transported people and moving pedestrians are excluded.
With no suitable person or space, the original stage presentation still runs.

An identity `tiglil_anchor` parent was added to all three models without changing
any rest transforms. It isolates street placement from the old animation pivots,
faces the projection toward the person and compensates for moving parent pieces.
Animated mesh bounds keep the silhouette above the ground, including floor poses.
Placement ends when the routine finishes, the person moves away, the blimp moves
away, or the show is cancelled; the anchor then returns to its authored identity.
Conversation gesture/head threads are stopped at the end of the routine.
The preview includes both street routines; placing a stationary civilian nearby
exercises relocation, while an empty test area exercises the fallback.


## Brothel choreography

The original suggestive routines (`idle_stance13`, `idle_stance15`,
`idle_stance18`, the mixed gestures in `idle_stance2`, and the drum/pole branch)
were already included in the brothel pool and remain available. A misspelled
hair-piece reference in stance 15's final waits is corrected.

The brothel alone adds `danceBurlesqueSway`, `danceBurlesqueWave` and
`danceBurlesqueFan`: weight-shifting hip sways, rising/falling body waves with
arm arcs, and alternating fan-like arm/leg silhouettes. They use the rigid arm
pieces directly, mirror their phrases and return to neutral. The diagnostic
preview includes all three. Native motion checks cover the new dances and the
original conversational and suggestive routines across multiple seeds.


## Personalized pedestrian performances

Building holograms add `greetPasserby`, `embracePasserby` and `kissPasserby`.
They play a greeting dance, a rigid-arm embrace, or a brief cheek-kiss gesture
in front of a stationary civilian. The normal western idle/techno/business pools
and the brothel pool include them; the blimp neither registers nor enables them.
These performances are skipped when no suitable pedestrian or clear space exists.
They never issue movement orders to the pedestrian, and end early if the person
leaves. Business/casino interactions do not receive glow sticks.

Close staging uses the pedestrian's collision width and actual head location
where available: the generic model radius/height can substantially overstate
both. Incompatible heights skip the close gesture. Contact is an approximation
on this rig, which has no elbow, wrist or mouth articulation; live visual review
is still needed for different civilian silhouettes.

Only the brothel adds `invitePasserby`, its seductress interaction: attention and
gaze changes, a shoulder-driven beckoning gesture, slow sways, a step aside and
a held invitation. It uses the same pedestrian selection, grounding and
interruption rules. These four personalized routines are named in `text_fx_test`;
place an idle civilian nearby to exercise them.


`lingerBrothel` adds ten held model poses to the brothel pool: hip-shift,
overhead stretch, one-arm arch, over-shoulder glance, narrow crossed stance,
inclined invitation, open-chest silhouette, opposing hip and gaze, side-leg
extension and low curtsy. Each pose transitions for 0.9 seconds and holds for
2.1 seconds; the complete mirrored sequence lasts about 31 seconds including
entry/exit. This is a stage routine, independent of pedestrian availability.
It appears in the diagnostic preview and remains absent from ordinary
advertisement and blimp pools.


`danceEmbracePasserby` adds a brothel-only close dance embrace. After opening
and closing the arms, Tiglil performs two left/right sway pairs with small
alternating knee bends and lateral steps, settles briefly, releases and steps
back. Forward placement stays constant during the sways. The mirrored routine
lasts about 12.5 seconds, uses the existing close-embrace distance/height checks,
and ends early when its pedestrian leaves. It is excluded from normal western
and blimp pools and appears in `text_fx_test` when a suitable civilian is near.

`danceBehindGlass` is a brothel-only stage placeholder, available in
`text_fx_test`. Edit its eight named poses in `scripts/lib_tiglil_glass.lua`.
The 25.3-second sequence places both hands against an imaginary pane, slides
them upward, alternates shoulder stretches and head turns, holds silhouettes,
and returns to neutral. Each pose has a 1.5-second transition and hold; the
shared player mirrors the sequence and grounds the supporting foot. There is
no glass mesh or pedestrian dependency. Hands approximate contact using the
rig's rigid arms; there are no wrist joints. Normal advertisements and blimps
do not register this routine.

`danceShakira` adds an approximately 19-second solo phrase: hip isolations,
two figure-eights, a short knee-driven shimmy, a torso wave and overhead arm
sweeps. It suggests Shakira-inspired movement using Tiglil's rigid torso and
arms rather than reproducing a particular performance. Its editable sequence
is in `scripts/lib_tiglil_shakira.lua`; the shared player mirrors it, grounds
the feet and restores neutral. It is available in normal western, techno,
business, brothel and blimp dance pools, and previews first in `text_fx_test`.

The test unit plays both text effects and Tiglil routines newest-added first.
Text starts with wall impact, restored spline and meteor, followed by older
addition groups; repairs do not move an effect forward. Each effect runs its
0, +20 and -20 degree/second parent variants together. The two plain layouts
come last, and the next cycle starts with the newest effect again. Every
registered effect remains in the cycle. Entries added together retain their
registry order. (`waterFallProject` is only defined by production house
scripts, so it is absent from this unit’s shared registry.)
Prepend new effects to `newestFirst` and dances to `routines` in the preview
script. Unlisted registered effects still run first as a fallback; list them
explicitly to establish their relative addition order.
