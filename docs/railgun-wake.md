# Railgun radiance and lingering wake

The Nimrod's ground and orbital railguns retain their expanding CEG rings,
impact sparks, electrical arcs and sounds. Surface lighting now uses the shared
radiance pipeline. Each observed shot also deposits a thin, cold cyan wake which
loosens into translucent blue-grey strands and disappears within 15 seconds of
the shot being created.

## Appearance and timing

- The muzzle radiance pulse lasts 0.4 simulation seconds; the impact pulse lasts
  0.6 seconds. Both remain visible in daylight and cool rapidly.
- The moving projectile has a small cyan radiance source. It uses the existing
  bounded projectile-light discovery; the wake itself uses explicit projectile
  events so even a shot completed within one simulation frame is retained.
- A narrow emissive core fades during the first second. Smooth curls and holes
  reveal loose, non-emissive vapour afterwards. By 12 seconds only faint wisps
  remain, with zero output at the shot's 15-second expiry.
- Time is measured in simulation frames using `Game.gameSpeed`. Pausing pauses
  the effect; changing simulation speed changes its wall-clock duration.
- Nimrod deployment retains both original flash pairs at their original
  ground-relative heights (45/10 and 65/35), now as finite radiance sources.

Only the old CEG ground-flash lighting and its firing/deployment calls are
replaced. Weapon damage, velocity, range, costs, reload, burst behaviour,
collision behaviour, reveal-on-fire and hologram interactions are unchanged.
The unused `railgunshine` definition remains available for compatibility.

## Factory launches

Successful Nimrod-built satellite and Icarus departures now produce the same
short cyan muzzle radiance and a vertical 15-second Eraser wake. This is a
visual launch stroke: it creates no damaging projectile and does not change
orbital insertion, weapon costs, reloads, cloak state or reveal-on-fire rules.

The effect gadget records the builder when a supported payload is created.
`GG.NimrodLaunchFX.Departure(payloadID, optionalAbsoluteTopY)` consumes that
record once, after construction has completed and actual departure begins.
Canceled builds, unrelated builders, transferred payloads and orbital retasking
do not emit extra launches. The satellite hook runs before its map-edge orbital
insertion; Icarus calls the same API before its scripted ascent.

The stroke starts at the Nimrod barrel piece, with the payload position as a
fallback, and rises locally toward the supplied flight altitude, capped at
2,048 elmos. It never connects the barrel to a satellite's distant orbital
entry. One event supplies at most 33 visibility samples and 32 retained spans;
there is no new continuous unit/projectile tracker. Negative synthetic IDs and
a monotonic serial keep launches separate from engine projectiles and from
same-frame reuse of a unit ID. The flash inherits railgun **High** priority;
residue and lighting share the existing caps below.

Own/allied players and full-view spectators can see a cloaked Nimrod's launch
feedback. Enemy clients require an uncloaked source in LOS at departure, and
all normal clients still require per-point and interior LOS. Hidden enemy
events are discarded immediately; later revealing the gun cannot reconstruct
them. The existing deployment charge flashes keep their separate timing and
visibility behavior. LuaUI reload does not replay an old launch.

## Actual trajectories and visibility

`gfx_explosion_lights.lua` captures a shot's initial position before generic
muzzle-event throttling, then samples only active railgun projectiles each
simulation frame. Identity includes both projectile ID and creation frame, so
reused IDs and overlapping orbital bursts remain separate.

The ground railgun finishes at its actual explosion position. Orbital rounds
have `noExplode = true`, so an impact adds a path point while tracking continues
until the engine destroys the projectile. Destruction reads the final position
while it is available, with the last sampled position as a fallback. Neither
path uses the intended target as a fabricated endpoint.

The unsynced bridge forwards visible positions and coordinate-free gap events
for hidden samples. `railgun_wakes.lua` checks visibility again before accepting
samples and their interiors. Unobserved stretches are never joined or restored
later. Retained spans are also checked against current LOS at a three-frame
cadence; changing ally team or spectator full-view invalidates that cache.
Offscreen spans are culled before this work. Normal scene depth testing hides
the wake behind buildings.

After deposition, the wake contains copied world coordinates and timestamps.
It does not follow the gun, target or projectile and survives their destruction.
Its lifetime is independent of radiance capture and draw selection. A LuaUI
reload discards old residue; still-flying shots can begin a new visible section
on their next sample, retaining the original expiry.

## Work budgets

- At most 32 active railgun projectiles are sampled in synced code. No other
  weapon gains continuous path sampling.
- The client retains at most 16 wakes with at most 96 spans each. Admission is
  stable under overload: older rejected continuations cannot repeatedly evict
  the retained shots. Old spans are trimmed if an unusually long path exceeds
  its per-shot bound.
- The renderer accepts at most 256 spans and 384 tessellated cells, or 1,536
  vertices, in one batched draw. It selects whole recent shot groups and then
  lowers their tessellation to fit; budget pressure does not cut arbitrary
  middle spans from a selected group.
- Curling, cooling and erosion are analytical shader operations. The wake adds
  no particle simulation, collision solver, framebuffer, scene copy or full
  screen pass. Cool residue contributes no radiance source per segment.
- The existing 128-transient / 96-submitted-light limits still apply to the
  short radiance pulses.

These are structural cost limits, not a hardware FPS claim. Actual Recoil
appearance and GTX 1050 Ti frame time must be checked in-game.

## In-game checks

Enable **Combat lights and fire** and the normal radiance cascade. In a test
game, give a Nimrod a ground attack order and inspect both a short shot and a
long shot across several buildings. Move the camera after impact to verify
that the trail stays in world space. Check the faint residue around 12 seconds
and complete disappearance by 15 simulation seconds. Repeat in daylight and
at night. Fire an orbital burst to verify that each round retains its own path
and continues through nonterminal impacts.

Use these on-demand diagnostics:

```
/effects status
/railgun status
```

`railgun status` reports shader availability, retained and active shots, stored
spans, the last draw's spans/cells/draw calls, and budget evictions. There is no
per-frame log output.

## Automated checks

Run from the repository root with Lua 5.1, or `texlua` for the portable
standalone tests:

```
lua5.1 tests/railgun_effect_events.lua
lua5.1 tests/nimrod_launch_fx.lua
lua5.1 tests/orbital_bands_test.lua
lua5.1 tests/railgun_wakes.lua
lua5.1 tests/railgun_radiance.lua
lua5.1 tests/railgun_wake_renderer.lua
lua5.1 tests/light_effects_widget_startup.lua
lua5.1 tests/combat_effect_events.lua
lua5.1 tests/combat_effects_lifecycle.lua
python tests/railgun_wake_gpu.py
```

The factory-launch test exercises the real event bridge and wake accumulator:
completion/departure separation, cancellation, source destruction, ownership,
duplicate calls, same-frame ID reuse, local launch anchoring, hidden enemy and
allied feedback, LOS gaps, High priority, shared budgets and fixed expiry.

The GPU test uses NumPy and system Mesa EGL/OpenGL libraries to compile and
render the production shaders. It checks emission cooling, erosion, fixed
expiry, transparency, short-shot endpoint fades, visibility gaps and scene
depth occlusion. `--preview /absolute/path.png` optionally writes a shader
contact sheet; that image is a shader test, not an engine screenshot.
