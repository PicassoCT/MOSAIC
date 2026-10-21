# High / Low visual effects

This is an importance policy, not a graphics-quality selector. A High deserves
budget because the unit is expensive, the event is rare/large, or the player
must react or micro. A Low is common, small, or attached to a cheap unit. Classify
the **effect layer**, not just the weapon: a readable bullet can stay while its
expensive surface illumination disappears.

## This implementation

| Layer | Class | Behaviour |
| --- | --- | --- |
| Sticky detonation | High | One radiance source and two short hot ribbons at the detonation coordinates. Stack damage still produces one event. |
| Blackout activation and affected-device pulses; information-payload electrical bursts | High | Brief blue-white light and electrical ribbon. Target visibility/cloak is checked; no persistent map-wide energy dome. |
| S16 / Javelin / military AA and AT / F35 interceptor / campaign missile motor | Low | Up to eight compact exhaust ribbons with local warm radiance, close-up only. Existing projectiles and CEG smoke remain. |
| Mortar and support-mortar hot impact | Low | One two-strand upward fireburst and short radiance flash, close-up only. Existing dust/CEG/sound and gameplay remain. |
| MG / AA / gunship / escort gun radiance | Low | Pooled short ground-level muzzle pulse near a gun; no moving per-bullet radiance or radiance on every hit. High-flying guns do not project a false ground flash. |
| Existing cheap night tracer geometry | Readability cue | Not an expensive-detail tier; retains the existing day/night window and 64-projectile discovery ceiling. Not cut by the Low lighting gate. Engine bullets are unchanged. |
| Generic unclassified weapon lighting | Low | Conservative default; `customParams.sfx_priority = 'High'` or `'Low'` overrides per weapon. |
| Existing railguns, tank cannon/muzzle, Molotov/Cinder hazards, tank wreck, aiming dot, debug lamp | High | Retain their existing effect shapes and gameplay cues; shared selection prefers them. Cinder keeps its separate, previously bounded collision/detail LOD. |
| Civilian car-wreck enhancements and police lightbar surface illumination | Low | Close-up only; legacy flame/smoke CEGs and vehicle/lightbar models remain. Car's accepted broad-flame shape is unchanged. |

The four new families are the approved first package, not implementation of all
11 concept boards. For subsequent work the design classifications are:
RPG backblast **Low**; airstrike impact **High**; SSIED detonation **High**;
aircraft crash fire **High** for a significant crash; nuclear flash **High**;
tiny stun-contact arcs **Low** (keep a readable stun state cue); orbital
interception **High**. Their new concept treatments are not added here.

## Camera and visibility rules

The central policy is `luaui/widgets_mosaic/include/combat_sfx_policy.lua`.
Low detail is full within 900 elmos of the camera, smoothly fades from 900 to
1400, and is **zero at and beyond 1400**. Actual 3D camera distance includes
height, so a top-down orbital view cannot retain Low ground detail merely by
looking directly at it. The overview camera also vetoes Low detail; its state
is read once per draw. These are initial tuning distances, not visually
validated thresholds on every map/camera configuration.

Low events are rejected before queue allocation when already too far away;
projectiles are rejected before ribbon construction. Existing active records
are re-gated every draw, so zooming out does not leave Low radiance or ribbons
behind. New Low heat-distortion particles are not spawned from far away.
Existing LUPS particles already born nearby retain their own short lifetime.

High is not an instruction to show hidden information. LOS, cloak checks for
attached effects, frustum and scene depth still apply. High ribbons have a
camera-relative finite envelope inside the existing renderer so its normal
small-plume distance cutoff does not erase them at strategic zoom. Their
physical dimensions are not enlarged with zoom. High events can still lose
slots to other High events under overload; budget is finite.

## Work limits and preservation

The new events have separate 32-record High and Low pools. At most eight new
High events and eight new Low events are prepared per draw. Missile exhaust
has a separate eight-source admission cap. Sticky side tongues share their
main light. At most 64 visual script notifications cross the synced bridge
per simulation frame. These messages use reserved negative visual IDs -101
and -102; they never enter WeaponDefs, damage, or the command serializer.

Everything joins the existing **96 combat lights / 64 combat ribbons** limits.
High lights and ribbons are selected before Low; Low transient traffic cannot
evict retained High flashes. Cheap tracers are no longer dependent on admission
to a lighting slot. There is no new framebuffer, scene copy, full-screen pass,
shader program, collision solver, or per-segment radiance source.

Damage, reload, ammunition, projectile trajectories, unit prices, stun duration,
fuses, CEG smoke/dust, sounds, railgun wakes and existing launch/aircraft work
are not changed. No synced camera-dependent branch or RNG consumption is added.
This is a migration of the shared combat path, not a claim that every legacy
CEG, cloud, attached ribbon, window light and atmospheric effect in the game
has already been migrated to this policy.

## Diagnostics and acceptance

```
/luaui sfx status
/luaui effects status
```

The first command reports new High/Low events, missile jets, final shared
light/ribbon counts, and cheap tracers from the last collection. It is on-demand
and emits no per-frame log. `WG.lighteffects.getSfxBudgetStats()` returns the same
counts to diagnostics.

Run `tests/combat_sfx_priority.lua`, `tests/combat_sfx_collector.lua`,
`tests/combat_sfx_events.lua`, and `tests/combat_sfx_widget.lua` with Lua 5.1
or texlua. The collector/widget tests execute the production code but stub
unchanged rendering and unrelated subsystems; they are not Recoil screenshots.
The dedicated CI also runs existing combat/tank/police/railgun/Cinder and shader
regressions on a full source checkout.

In-game acceptance: fire the four effect families at night and in daylight;
zoom from street level to overview and back during an effect; check that only
High enhancements remain far away, that bullet/tracer cues survive, and that
hidden/cloaked targets are not exposed. Repeat with simultaneous guns, 100
missiles and overlapping sticky/EMP events. Toggle the widget and test pause,
replay seek and entering/leaving LOS. Confirm no duplicate groundflash and no
missile exhaust pointing forward. Inspect the three-dimensional light reach.

The intended 1050 Ti / 1080p target remains <=0.5 ms average and <=1 ms for a
representative busy exchange, measured with the same camera and replay. These
are **acceptance budgets, not measurements**. No target GPU or live Recoil
runtime is available in the editing environment. Sizing, exact appearance,
close-up thresholds and measured frame times remain in-game acceptance work.
