# Icarus: native flight and finite glide

Icarus (air_plane_artillery) uses Recoil's native aircraft movement for circling,
MOVE, PATROL, FIGHT and attack approach. The unit script animates the model,
consumes a finite glide allowance, and gates the native weapon until folding is
complete. Only the short Nimrod launch uses enabled MoveCtrl.

## Glide budget and tuning

| Setting | Default | Meaning |
| --- | ---: | --- |
| cruiseAlt | 1536 | Initial native terrain-clearance target, in elmos |
| customParams.icarus_sink_rate | 8 | Elmos of glide altitude allowance lost per simulation second |
| customParams.icarus_terminal_height | 128 | Remaining clearance at which the forced terminal fold starts |

The glide starts when the launch/unfold animation hands movement to the engine.
Its deadline is fixed once:

    glide duration = (initial clearance - terminal clearance) / sink rate
                   = (1536 - 128) / 8
                   = 176 simulation seconds

The wings then take up to another half second to fold before the native
projectile falls. Construction time and the rail launch are outside this budget.
STOP, new waypoints, target changes, team changes and EMP do not replenish or
pause it. The two custom parameters are positive, with the terminal clearance
clamped below the initial height.

Once per second the script sets the decreasing native wantedHeight, calculated
from absolute simulation age. The first update is staggered by unit ID to spread
same-frame swarm launches. This setter happens to live at
Spring.MoveCtrl.SetAirMoveTypeData, but it modifies the active native
CStrafeAirMoveType; it does not enable script-controlled movement. No Lua loop
sets flight position, velocity, heading, banking or orbit waypoints.

The engine interprets wantedHeight as terrain clearance. Its normal terrain
avoidance can briefly raise the aircraft over a ridge, and actual altitude
responds through aircraft physics rather than following a prescribed vertical
velocity. The declining allowance and absolute deadline remain unchanged.
This is a finite gameplay glide, not a full simulation of unpowered energy
conservation. Setting the altitude target to zero alone would not guarantee
termination: normal native aircraft can clamp/bounce away from terrain.

At expiry, the current order is no longer relevant. Icarus folds and releases
the same native bomb at its **current position**, with its existing horizontal
momentum and downward vertical velocity. It cannot travel indefinitely toward
an unreachable target. A permanently stunned aircraft also expires; this passive
release is independent of the native weapon's stun gate.

## Commands and phases

| Phase | Behavior |
| --- | --- |
| Building | Casing/sabots remain visible; construction and an initial EMP finish before launch. |
| Ascent | The existing 2048-elmo rail launch emits the Nimrod departure effect once and separates the sabots. This is the only enabled MoveCtrl phase. |
| Unfold | The original base/tail orientation, rotor, wings and telescoping panels finish their animations. MoveCtrl is disabled. One native movement goal starts airborne circling even without a player order. |
| Loiter | Native aircraft steering circles around its holding goal while the altitude allowance declines. The native turn radius and physics determine the path. |
| Transit | The engine processes MOVE/PATROL/FIGHT and explicit ATTACK commands. The Lua script does not implement command navigation or move the aircraft toward a target. |
| Fold for attack | A cheap preparation check runs only during an explicit attack. It starts folding ahead of the native ballistic release window. BlockShot rejects release until both wings and both panels finish. |
| Native attack drop | The AircraftBomb weapon chooses its ballistic release point and carries aircraft velocity into the projectile. The original aircraft becomes a hidden owner only after the projectile has actually been created. |
| Exhausted drop | At the absolute glide deadline, folding and one local native projectile release happen regardless of target or EMP. |
| Cleanup | The projectile destruction event starts the finite blast-propagation grace period, then the original owner is reclaimed without a second explosion. |

Native bomb release is ballistic: it does not stop the aircraft directly above
the target or produce a perfectly vertical fall. A moving target may evade
after release; the bomb does not home.

Release requires the current explicit, non-internal ATTACK designation and the
native weapon's userTarget flag. A unit designation retains the GROUND category
restriction and must still be in the owner's LOS or radar at release. Animation
preparation reads its position through CallAsTeam, preserving radar error.
Changing fire state does not by itself authorize a strike.
The native noChaseCategory filter excludes every eligible GROUND target from
idle/FIGHT auto-selection. Explicit ATTACK bypasses that filter. This matters
because a native FIGHT-generated attack can inherit a user-target flag; that
flag alone would not establish an explicit bomb designation.

STOP, a changed active designation, lost/dead targets or EMP prevent a commanded
release and reopen the wings. Appending an unrelated shifted command preserves
the active fold. Command notifications are coalesced and read one frame later,
because Recoil emits UnitCommand before changing its queue. The shot gate stays
closed during that gap. Native movement remains active during all animations.

The engine checks AircraftBomb range before calling BlockShot and can delay
AimWeapon acquisition until the same narrow window. Folding therefore starts
in advance, using altitude, travel speed and a short animation lead. BlockShot
is the final synchronous gate. Waiting inside FireWeapon would not delay native
projectile creation; that callback only marks the shot committed and leaves
the muzzle and velocity intact.

## Event relay and ownership

unit_icarus_lifecycle.lua is an event-only bridge between native projectile and
command events and the unit script. It has no GameFrame callback, movement
controller, command polling or whole-world scan. ProjectileCreated records the
owner before notifying the script. ProjectileDestroyed removes that record and
notifies the script while the engine still exposes the projectile.

The original unit remains alive through the fall and delayed outward splash so
the engine can resolve attacker credit. It is hidden, unselectable, absent from
the minimap, nonblocking, neutral/stealthy and without sensors. Its native
movement continues briefly; it is never frozen with MoveCtrl. The existing
aircraft-crash gadget narrowly protects this released Icarus from damage,
new commands and reclaim. A pre-existing self-destruct is cancelled first.

A relay reload can recover the projectile owner directly from a destruction
event without restarting the glide or release deadline. One sleeping timeout
per released carrier covers a completely missed event or stuck projectile;
there is no recurring projectile-position poll. Exceptional external removal
of the owner leaves an already released projectile in flight.

If the exceptional exhaustion spawn fails, the script retries once on the next
frame, then hands off to native crash behavior instead of creating an immortal
glider. A lethal hit before release stops the lifetime and animation threads
through BeginAircraftCrash. No subsequent expiry bomb can appear.

The weapon retains its 512 base damage, 128 area of effect, impulse, fire starter,
folded model, explosion CEG and impact sound. The projectile metadata keeps its
nose aligned with native projectile velocity.

## Cost and validation

For an idle airborne Icarus, a normal one-second update consists of
GetGameFrame and one SetAirMoveTypeData call. There are no idle position,
terrain, velocity, target or command reads. The previous controller ran at
10 Hz and made about 90 Spring/MoveCtrl calls per second in idle flight.

This is a measured script-call reduction, not an FPS benchmark. Native aircraft
physics still has its ordinary per-unit cost. Attack preparation adds a small
amount of work at 1 Hz only while an explicit attack is active; animation and
command callbacks occur at transitions.

tests/icarus_flight_test.lua runs the actual production script with multiple
coroutines, signal masks, completed animation waits and explicit native command,
shot and projectile events. It verifies launch/handoff, idle call budget,
declining altitude, the absolute lifetime under orders and EMP, forced local
expiry, fold completion, cancellation, visibility, one-shot attribution,
cleanup, spawn failure and crash cancellation. Native aerodynamic movement is
deliberately opaque in this harness; it does not fake an engine flight test.

tests/icarus_lifecycle_test.lua checks the event bridge, including reload
recovery and synchronous event ordering. The existing crash, model orientation,
Nimrod launch and effect suites remain applicable.

An in-engine visual pass should cover idle descending circles, MOVE/PATROL,
ground and moving-unit designation, STOP or EMP during folding, passive expiry
with no target, and a normal AA kill. Inspect the first-pass fold/release timing,
terrain response, launch wake, model orientation and single impact.

## Exact target-engine references

These checks use Recoil BAR105 105.1.1-1544-g058c8ea:

- [Native movement setter](https://github.com/beyond-all-reason/RecoilEngine/blob/058c8ea/rts/Lua/LuaSyncedMoveCtrl.cpp):
  SetAirMoveTypeData modifies the active native type without enabling MoveCtrl.
- [Native aircraft movement](https://github.com/beyond-all-reason/RecoilEngine/blob/058c8ea/rts/Sim/MoveTypes/StrafeAirMoveType.cpp):
  bomber steering, terrain clearance, altitude defaults and ground handling.
- [Air command processing](https://github.com/beyond-all-reason/RecoilEngine/blob/058c8ea/rts/Sim/Units/CommandAI/AirCAI.cpp):
  native command handling and the script-movement early return.
- [Native bomb release](https://github.com/beyond-all-reason/RecoilEngine/blob/058c8ea/rts/Sim/Weapons/BombDropper.cpp):
  ballistic range, AimWeapon angle bypass, inherited velocity and projectile TTL.
- [Weapon callback order](https://github.com/beyond-all-reason/RecoilEngine/blob/058c8ea/rts/Sim/Weapons/Weapon.cpp):
  BlockShot before salvo commitment, FireWeapon before projectile creation.
