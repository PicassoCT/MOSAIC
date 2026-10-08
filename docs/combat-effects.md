# Combat lighting and fire

`Light Effects` now feeds the radiance cascade instead of collecting lights for
the absent deferred-lighting widget. The graphics option is **Combat lights and
fire**. The existing brightness, radius and explosion lifetime controls remain.
Explosion heat distortion is retained. It still uses LUPS; the general LUPS
renderer is not removed.

## Sources and timing

- Weapon muzzle flashes, explosions and visible projectile lights are scaled
  by the cascade's night factor. `Flame` projectiles and Molotovs additionally
  use FlamePainter ribbons; persistent fire remains luminous in daylight.
- Machine-gun and AA-gun rounds get additive camera-facing tracers only during
  the same night window (fading at dawn/dusk). The five base MG/AA definitions
  and four military support variants opt in through `night_tracer = 1`.
  Their ground light uses the interpolated round position and three-dimensional
  range: rounds above the light's reach cannot illuminate the ground. Tracers
  share the 64-projectile discovery budget and allocate no lighting textures.
- Car and tank wreckage publish their emitter piece and fire expiry once,
  after the initial blast. Light and FlamePainter follow that piece locally.
  The existing `flames`, `glowsmoke` and `vehsmokepillar` CEGs remain. The
  `cburningwreckage` CEG was solely a groundflash, not a jitter effect, and is
  removed. Wreckage scripts never called the deleted flamethrower-jitter API.
- Molotovs use FlamePainter for their moving trail and ground fire. Their old
  trail CEG and repeated flame/groundflash emissions are removed; smoke,
  ignition, damage behavior and the 15-second burn duration remain. A bounded
  synced snapshot restores visible ground fires after LuaUI reload or entering
  LOS. Positions are filtered before crossing into LuaUI and checked again
  when rendering.
- **Cinder (Antagon):** the synced Flame projectiles still own damage and
  ignition. The client draws one nozzle-aligned FlamePainter jet instead of
  per-shot pellets. A single shared budget is enforced *before* collision
  sampling or ribbon allocation: at most 8 close detailed Cinders (within
  1,250 elmos), 16 additional simplified Cinders (within 2,700 elmos),
  and 48 total Cinder ribbons, sharing the 64-ribbon renderer with other fires.
  Detail has one main jet, up to three turbulent breakup tongues, or one
  breakup plus two colvol/terrain impact tongues. Simplified fire has one
  wide guarded jet, nine terrain-height queries per update and no object rays.
  The most stale detailed Cinders receive a globally limited 2 collision
  solves per simulation frame; simplified terrain is capped at 4 solves per
  frame. Visible non-icon units are sorted by camera distance *before* rays
  are allocated; the 76+ remaining firing Cinders in large battles do not
  construct cosmetic ribbons or issue collision rays.
  Near detail still truncates to the nearest visible terrain/unit/feature
  colvol, wraps around the contact surface, and cannot disappear underground.
  Side breakup profiles are sliced from the *same* eight-band main terrain
  envelope without further height queries. The two impact tongues reuse one
  shared 17-sample radial guard. All ribbons retain post-curl shader
  heightfield clamping, and radiance follows jet reach without additional
  scene textures/passes. Caches persist across rendered frames and stale
  collision samples are refreshed fairly across the globally shared budget.
  The independent fuel-tank death torch, Molotov ground fire and synced
  gameplay damage are unaffected.

- Combat lighting shares the car-light textures and scene pass: whole-map
  direct field at 10 Hz, near field every rendered frame, cascade spill at 5 Hz.
  Source intensity is applied once before capture. No additional full-screen
  pass, scene copy or lighting framebuffer is allocated. Projectile positions
  interpolate with render offset; projectile discovery runs at 10 Hz.
- There are at most 128 transient flashes, 128 persistent Molotov fires, 64
  tracked visible projectiles, 96 submitted combat lights and 64 rendered combat
  ribbons. Nearest sources are preferred for drawing. Expiry runs independently
  of capture, so disabling the cascade cannot strand the old light queues.

Removed: `gfx_dynamic_lighting.lua` and its configuration,
`lups_flame_jitter.lua`, `lups_napalm.lua` and its configuration,
`gui_captureInvalidBuildCommands.lua`, `cmd_default_set_target.lua`, the stale
set-target option and unused deferred beam/thruster-light controls. The active
neon, window and objective radiance systems remain.

## Checks

Run from the repository root:

```
texlua tests/combat_effects_lifecycle.lua
texlua tests/cinder_flame_stream_test.lua
texlua tests/cinder_flame_budget_test.lua
texlua tests/pyro_flame_collision_test.lua
texlua tests/combat_effect_events.lua
texlua tests/light_effects_widget.lua
texlua tests/night_tracers.lua
texlua tests/neon_radiance_lifecycle.lua
texlua tests/headlight_live_field_lifecycle.lua
texlua tests/smoke_ribbons_lifecycle.lua
MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/combat_light_gpu.py
```

The GPU check uses Mesa EGL with `moderngl` and `numpy`; it tests the production
shader, falloff, color, height, wall blocking and local capture transform.

For interactive load diagnostics enter `/luaui cinder fxstats` to print the
candidate count, detailed/simplified selections, submitted ribbons and
expensive/cheap collision probes used in the latest frame. The Lua budget
regression uses 100 simultaneously firing Cinders; it asserts fixed CPU,
lighting and ribbon ceilings without claiming a measured in-game FPS.
Profile frame time on the GTX 1050 Ti with 1, 10, 50 and 100 Cinders.
Do not assume that "48 ribbons" by itself guarantees 25 FPS.

In Recoil, verify Cinder fires a *single* full plume with no visible projectile dots
or oversized yellow ground disk. Check sustained fire, brief pauses, aim direction,
wind, grazing the street, a rising curb, wall/vehicle collision-volume hits,
LOS loss/re-entry, and the independent death torch. The visual rays never
change synced damage or reveal hidden units.
The hologram gadget no longer attempts to set `viewPortSize` or `rainPercent`
after the GLSL compiler optimizes them out; the hologram rendering is unchanged.

In Recoil, compare the same camera in day and night combat, including a thrown
Molotov and both wreckage types. Check flame extinction, LOS loss/re-entry,
LuaUI reload and widget disable/re-enable. Compare frame times with combat
effects enabled and disabled: this change adds working effects, so automated
correctness checks do not establish an FPS improvement on the 1050 Ti.
