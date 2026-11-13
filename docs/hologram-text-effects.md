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

## New effects

**Spline following (`splineShapeFollowing`):** upright letters traverse a short randomized cubic Bezier curve in source order, entering every 300 ms. Spaces reserve their delay; repeated glyph meshes alternate between active occurrences. An arc-length lookup keeps travel speed steady through bends. The lead letter takes at most 12 seconds, and the last letter finishes at most `12 + 0.3 × (logical slots − 1)` seconds after the first enters. There is no extra hold. The effect restores the phrase and parent spin afterward; both initial layouts are supported. Engine-interpolated motion updates at 20 Hz.

- **Civilian conga:** chooses a live civilian within 650 world units, drops the physical letters to terrain height over 800 ms, and follows a bounded path history with phased sway and hopping. Letter spacing uses the authored glyph's transformed bounds. A cached inverse of each glyph's parent-world basis accounts for house heading, parent rotation, imported scale and axes. Motion updates at 5 Hz for at most 16.6 seconds, ending early on disappearance or departure beyond 750 units. Letter leases also rotate through conga positions. No civilian orders, MoveCtrl or new gadgets are involved.
- **Hostile takeover:** selects a different phrase from the sign's existing phrase pool and places it below the original. Private glyphs stay in formation and recoil while shared physical glyphs shoot across the gap in opposing directions on a 500-ms beat for 12 seconds. Each shot travels through a raised midpoint for 120 ms, lands over 130 ms, then holds for 250 ms; engine interpolation supplies the motion. There are no weapon projectiles, damage, extra letter meshes or per-frame workers. Repeated occurrences cycle through their leased slots too. The original layout is restored afterward.

**One-armed bandit:** horizontal text becomes a row of slot-machine reels. Six shuffled rolls cycle the phrase's available glyphs downward through their slots, then reels slow and stop from left to right on the original phrase. Each physical glyph belongs to exactly one reel at a time; locked letters cannot be borrowed by the remaining reels. Spaces stay empty, and exhausted repeated-letter leases resume during the final three-second readable hold. Parent spin pauses during the effect and resumes afterward. There are no extra meshes or background workers.

**Meteor crater:** the first glyph leads the slogan down a diagonal wake into a common ground impact. Letters scatter in tumbling ballistic arcs, then reform the original phrase around a terrain-following crater rim for six seconds. Word gaps keep their slots and repeated glyphs rotate through their leases. The effect restores the original layout and parent spin, uses the actual model scale and unit heading, and bounds its movement waits. It creates no terrain damage or separate rock mesh.

**Letter tornado:** the phrase winds upward around an expanding cone, with eight logical slots per turn and word gaps preserved. Letters stay upright with the corrected cube/DNA facing. The letters orbit the cone in their actual horizontal plane at 30 Hz for 15 seconds, with their facing following the orbit. Speed is at least 60°/s and follows the selected direction; the parent stays still during the effect. It then restores the phrase for a three-second hold and resumes the previous parent spin.

**Heart monitor:** a separate mode; the existing `SinusLetter` is unchanged. Two ECG-shaped pulses travel along one straight line, including a small lead-in, negative dip, sharp upward spike, undershoot and recovery. Only glyph height changes. Word gaps remain, parent spin pauses for readability, and the line returns to its baseline before restoring the original layout.

**Smiling face:** letters form exactly two eyes and a curved smiling mouth in the text plane, without a nose or face outline. Tiny phrases can borrow unused alphabet pieces to complete the features. Every borrowed piece is hidden/reset afterward; the original phrase and selected parent spin return after a seven-second hold.

**Letter plant:** letters sprout from terrain beneath the sign, first growing a vertical stem from the ground and then alternating branches from that stem. Growth uses the imported model's scale and heading; branch ends stay above the terrain. After a six-second grown hold, the original phrase and selected parent spin return.

**Travelling push (`syncToFrontLetters`):** a four-slot-wide pressure wave travels behind one straight line of text, pushing neighbouring letters forward in depth and smoothly releasing them back to the same positions. No glyph rotates or leaves its baseline. This remains distinct from the vertical heart-monitor pulse.

**Cross letters:** two phrase segments cross at a shared character, preferably near the middle of both segments. A near-middle space is preferred for splitting. The intersection uses one physical glyph; the duplicate occurrence is hidden during the cross. If the segments share no letter, the existing middle glyph becomes their junction without inventing or reordering text. The layout holds for seven seconds and restores the phrase.

**Matrix:** three repeats of the same motion used by `consoleLetters`, arranged as a vertical column at eight times the normal console speed. Each repeat waits for its moves to finish and holds for 150 ms. The ordinary console effect retains its original layout, speed and ten-second hold.

The uniformly selected catalogue now has 29 modes: each has a **1/29 chance (~3.45%) per selection**. Sign eligibility and layout gates still apply. Conga requires a nearby live civilian; takeover requires another phrase. Ineligible effects return without a new retry loop.

## Validation

Run from the repository root with Lua 5.1:

```sh
luac5.1 -p scripts/lib_textFx.lua scripts/house_western_hologram_script.lua scripts/house_western_brothel_hologram_script.lua
lua5.1 tests/hologram_text_fx_test.lua
python3 tests/hologram_text_axes_test.py
```

The regression suite executes the real shared library and both scripts' production functions with strict animation-call mocks. It covers exhaustion, direct occurrence ordering, UTF-8 gaps, selection, logical spacing, half-second leases and restoration, matrix parameters, radius/no-rest handling, glow lifetime, all 29 registered modes, empty groups, parent rotation/scale inversion, conga lifecycle, takeover crossfire timing/trajectories, slot-machine reel ownership/ordered stops, projection geometry, travelling pulses, terrain-based growth, borrowed-piece cleanup and scratch-global isolation. CI uses native Lua 5.1; local validation can also run the same suite through `lupa.lua51` (Lua 5.1).

No Recoil visual or target-hardware performance validation has been performed. In Recoil, check a long repeated-letter slogan, day/night and blackout transitions, all projection modes, conga descent on slopes and rotated houses, turns/stops/death of the target civilian, and takeover cleanup when a phrase changes or the hologram is destroyed. Confirm glyph size, facing, ground clearance and movement timing against actual exported models. Compare zoomed-out frame times in a dense city.

## Ordinary-model test unit

Start a new local match, enter `/cheat`, then `/give text_fx_test` to spawn at the
cursor. It uses `house_western_hologram.dae` and the real `lib_textFx.lua` functions,
with ordinary engine Show/Hide drawing and no neon registration. The phrase is
`Lorem Ipsum`; console messages identify each mode, layout and parent rotation.
Tiglil dances continuously alongside the letters using the shared smoothed drum,
tango, headshake and dance routines. This preview has no night-only eligibility
or shared performer cap, and text cleanup never hides the dancer. Both loops
and their child animations stop when the unit is destroyed.

Each case runs its shared animation to completion, allows about five seconds
for remaining finite glyph moves/turns, then holds for five simulation seconds
before the next case. Cleanup immediately hard-resets already-hidden glyphs;
if visible cleanup exceeds the deadline, it hides and hard-resets those too.
Reset replaces queued engine targets before snapping and leaves the glyphs
hidden for an engine tick so an old target cannot pull the next layout apart.
The production signs use the same cleanup. Conga tracks actual piece translations
when calculating speeds, and fireworks bounds its launch/burst/fall waits too.
Continuous spins keep running during the hold. All glyph transforms/spins are
reset between cases; long effects are no longer cut short. The cycle has
96 cases: plain horizontal/upright text, all 29 shared modes (matrix and arch use
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
their requested duration subject to that minimum. The synchronized yoga helper
uses a common arrival time and avoids division by zero on neutral angles.
Spins without authored acceleration/deceleration use a 180 ms ramp; explicit
spin settings remain intact. Setup and show shutdown cancel the motion worker,
and hidden shutdown resets replace queued engine targets.

The external `tiglil_motion_test.lua` checks trajectories, shortest-angle turns,
native waits, interruptions, cancellation/restart and real setup, gait, pose,
yoga and shutdown callbacks. This is procedural smoothing, not captured motion;
foot contact, silhouette and perceived weight still need a fresh-match visual
check with the actual model.
