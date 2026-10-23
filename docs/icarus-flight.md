# Icarus flight and gravity drop

Icarus (`air_plane_artillery`) uses an explicit unit-script flight controller. It
waits for construction, leaves the Nimrod, unfolds and circles until given an
attack order. Its wings and telescoping panels finish folding before one native
gravity bomb takes over the visible descent.

## Commands and phases

| Phase | Behavior |
| --- | --- |
| Building | Shows the original casing/sabots and waits for completed construction. A stunned payload waits before departure. |
| Ascent | Calls `GG.NimrodLaunchFX.Departure` once, when available; raises the payload by 2,048 elmos with the existing sabot separation. The late ascent slowdown now changes the actual step. |
| Unfold | Preserves the original base, tail, rotor and wing arrangement. Uses actual wing/panel piece IDs and waits for their animations. |
| Loiter | Circles with a 180-elmo radius around its current holding point. Uses the owning unit's configured speed and cruise height; circles stay inside map edges. |
| Transit | An explicit ATTACK follows a visible ground unit or the selected ground position at flight altitude. MOVE navigates to a new holding point. PATROL keeps cycling through its waypoints, including a return leg for a single-point patrol. FIGHT navigates without selecting a bomb target automatically. |
| Fold | Stops over the designated position, locks that release point, retracts both panels and folds both wings. STOP, a replacement order, a dead/lost target, or EMP before release aborts the strike and unfolds again. |
| Drop | Creates one `AircraftBomb` with zero horizontal velocity and the map's gravity. It does not accelerate under motor power or home after release. Native projectile collision handles units, features, terrain and water. |
| Cleanup | Keeps the original owner hidden and protected until impact so the engine can resolve attacker credit; then reclaims it without a second explosion. A bounded fallback removes a stuck projectile/carrier. |

Native aircraft attack AI cannot own the movement while this controller is
active: the old missile-armed fighter behavior could dive and fire independently
of the folding animation. `AimWeapon1` rejects native firing and `BlockShot1`
blocks it as a second guard. The unit defaults to hold fire; changing fire state
does not authorize an automatic strike. Only a non-internal ATTACK command does.

Unit designations preserve the original GROUND target category. A target must
remain in the owner's LOS or radar contact until release. Its position is read
through `CallAsTeam({read=ownerTeam}, ...)`, preserving radar error instead of
reading unrestricted synced coordinates. A target that moves after folding
begins can evade the locked, unpowered drop. Ground-position attacks remain
available when unit contact is lost. STOP cancels the approach and resumes
circling at the current position.

EMP pauses scripted flight and prevents launch/release. An interruption during
folding opens the wings again; the still-current order may resume after the stun
ends. Before release, lethal damage hands movement back to the existing aircraft
crash system through `BeginAircraftCrash`; the flight controller cannot later
resume or create a bomb.

## Impact and ownership

The existing weapon retains its 512 base damage, 128 area of effect, impulse,
fire starter, impact model, explosion CEG and impact sound. Its terminal weapon
type changes from `MissileLauncher` to `AircraftBomb`; obsolete powered-flight
parameters are removed. No motor glow or smoke is added. The projectile metadata
orients the existing folded model along its velocity so its nose points down.

`Spring.SpawnProjectile` receives both the live owner and its current team, plus
weapon slot 1. The engine resolves that owner again at collision. Immediate unit
deletion would therefore lose attacker credit. During the brief fall, the
original unit is a hidden attribution carrier with no selection, minimap icon,
blocking, sensors or targetable neutral behavior. The aircraft crash gadget
protects only a marked, released Icarus against damage, new commands and reclaim;
all other aircraft retain their normal behavior. A pre-existing self-destruct is
cancelled before release. The Icarus continues to count as one unit until impact
and the brief damage-propagation grace period have finished.

The carrier polls its projectile at 10 Hz and is reclaimed after it disappears
and the explosion's finite outward damage propagation ends, preserving attacker
credit for the delayed outer splash as well as the direct impact.
The projectile has a gravity-derived finite TTL plus a margin; an additional
bounded deadline prevents an invisible carrier from persisting if the engine
does not clear its projectile. Exceptional forced removal of the carrier leaves
an already released bomb to finish its native ballistic flight and finite TTL;
the stopped controller cannot restart. Failed projectile creation leaves the visible
aircraft alive, unfolds it and clears the failed attack order.

## Cost and validation

There is one coroutine per Icarus. Movement decisions and command reads run at
10 Hz, reading at most two queued commands; MoveCtrl extrapolates the velocity
on ordinary simulation frames. There is no all-units scan or per-frame target
search. The short ascent uses simulation-frame steps. Carrier polling exists
only during the finite drop.

`tests/icarus_flight_test.lua` executes the real script with a frame scheduler,
continuous velocity, animation completion and a ballistic projectile fixture.
It covers build/launch ordering, circle movement, explicit/internal orders,
unit/ground targets and radar visibility, MOVE/PATROL/STOP and patrol replacement,
fold/panel completion, cancellation/target death/EMP, one native release, live
owner/team attribution, one impact, silent cleanup, spawn failure, finite fallback
and pre-release crashes. `tests/aircraft_crashing_test.lua` covers the narrowly
scoped carrier protection. The projectile orientation test checks the actual
model transform against the engine's draw convention.

The scripted regressions do not replace an in-game visual check. Validate an
idle circle, a ground and moving-unit designation, STOP/EMP during folding, and a
normal AA kill before release in Recoil. Confirm the casing, panels, projectile
orientation, launch wake, impact audio and explosion appearance in that run.
