# Burning car: one broad upward FlamePainter flame

Scope: `vehiclecorpse` only. Spawn on dry open ground with `/cheat 1`, then
`/give vehiclecorpse`. Start a fresh game after updating the script and client.

The car script still does not emit recurring SFX 1025 (`custom:flames`). Shared
CEG files, textures, tank wrecks, initial explosions, falling debris, smoke/ash
calls, and randomized burn/wreck lifetimes are unchanged. The LOS-scoped
`mosaic_fire_broad=1` opt-in replaces the obsolete `mosaic_fire_flames` count.
The emitter piece and expiry parameters keep their existing meaning.

The client reshapes the existing car ribbon into one broad upward column:
90 elmos long, 20 wide, direction `{0,1,0}`, speed 3, curl 0.28, wind influence
0.18, and trail time 0.7. Four internal mesh strands provide detail within that
single emitter; there are no offset sibling flames. Flame emission is
`{3.5,0.35}` and source-glow alpha is 0.55. The original interpolated anchor,
stable per-wreck seed, colours, and end-of-burn fade are retained.

One radiance light keeps its previous position, strength, radius, colour and
flicker. Flame size does not enlarge or brighten that light. Each burning car
now reserves one ribbon rather than three. The removed sibling fanout no longer
queries vehicle heading. `extraFlames` remains in use for Cinder side streamers;
the existing light and renderer budgets are unchanged.

Tank wrecks do not publish the broad-flame opt-in and retain their one 1.5-scale
ribbon and CEG flames. Ground fires, weapon trails, building flames, police lights
and the soft-shadow shaders are not retuned by this change.

Checks: `texlua tests/vehicle_wreck_flames.lua` and
`texlua tests/combat_effect_events.lua`. The first runs the actual car script and
combat collector with unrelated modules isolated; the second runs the actual
combat event bridge and both wreck scripts. These are Lua/source regressions,
not Recoil visual or target-hardware performance acceptance. In-game, inspect
one broad upward flame, preserved smoke, normal burnout, and an unchanged tank
wreck. This retuning does not diagnose the earlier orange-quad artifact.
