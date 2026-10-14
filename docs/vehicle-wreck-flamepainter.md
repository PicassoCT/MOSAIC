# Burning car: three FlamePainter flames

Scope: `vehiclecorpse` only. Spawn on dry open ground with `/cheat 1`, then
`/give vehiclecorpse`. Pause once it is burning; `/give all` is unnecessary.

The car script no longer emits recurring SFX 1025 (`custom:flames`). Shared CEG
files, textures, tank wrecks, initial explosions, falling debris, smoke/ash calls,
and the randomized burn/wreck lifetime are unchanged. The existing fire rules
publish one additional LOS-scoped parameter, `mosaic_fire_flames=3`.

The client renders three equal upward flames: each retains the previous car
FlamePainter size (45 elmos long, 12 wide). Two flank the original emitter by
8 elmos along the vehicle's forward axis. They follow the interpolated model
position and use different stable seeds, with the same expiry/fade. They are
not three extra copies on top of the previous flame: the total is three.

One shared radiance light retains its previous strength/radius. Sibling flames
are created only for retained wreck lights, and share the existing 64-ribbon
allowance with other combat FlamePainter effects. At saturation, siblings can
be omitted; no rendering budget is raised. Tank wrecks omit the opt-in parameter
and retain their one 1.5-scale ribbon and CEG flames.

Checks: `texlua tests/vehicle_wreck_flames.lua` and
`texlua tests/combat_effect_events.lua`. These are Lua/source tests, not in-engine
visual acceptance. Replacing this car's CEG does not establish the cause of the
previous orange-quad artifact, nor prove that unrelated particle compositing
is correct. Inspect the preserved smoke separately if the artifact remains.
