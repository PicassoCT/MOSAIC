# Icarus: native flight and finite glide

Icarus (air_plane_artillery) uses Recoil's native aircraft movement for circling,
MOVE, PATROL, FIGHT and attack approach. The unit script animates the model,
consumes a finite glide allowance, and gates the native weapon until folding and
native braking are complete. Only the short Nimrod launch uses enabled MoveCtrl.

## Glide budget and tuning

| Setting | Default | Meaning |
| --- | ---: | --- |
| cruiseAlt | 1536 | Initial native terrain-clearance target, in elmos |
| customParams.icarus_sink_rate | 8 | Elmos of glide altitude allowance lost per simulation second |
| customParams.icarus_terminal_height | 128 | Minimum transition reserve above terrain or the city's highest roof, in elmos |
| customParams.icarus_folded_speed_factor | 0.25 | Native maximum-speed fraction selected after the wings finish folding |
| customParams.icarus_brake_seconds | 1 | Native braking time before either release path |

Completed payloads wait for the map-wide city roof calculation before launching.
The glide starts when the launch/unfold animation hands movement to the engine.
Its initial maximum duration is `(cruiseAlt - terminal_height) / sink_rate`.
The actual deadline also accounts for the city's highest roof and the room
needed to finish folding and braking. It can only move earlier.

The clearance calculation uses absolute world height, including buildings on
raised ground. It reserves the next one-second sampling interval, the half-second
wing animation and the one-second braking dwell. For that 2.5-second interval,
the reserve is the largest of:

- The configured minimum clearance (128 elmos).
- The distance travelled at the greater of the original native speed and the
  aircraft's actual horizontal speed.
- The vertical distance lost at its actual downward speed (at least the configured
  sink rate), plus full bomb gravity over the interval.

The last term conservatively allows for loss of flight control during EMP. With
gravity 130 elmos/s², speed 75 elmos/s and sink 8 elmos/s, the reserve is
`8 * 2.5 + 0.5 * 130 * 2.5² = 426.25` elmos above the higher of terrain and the
fixed rooftop limit. On flat ground this gives about 138.7 seconds without buildings,
or 113.7 seconds with a 200-elmo roof. Different terrain, buildings, gravity or
actual descent can shorten those examples.

The script checks actual altitude as well as the decreasing target height. A
low or rapidly descending aircraft commits to its local terminal drop immediately
at the next check, rather than waiting for its original timer. STOP, waypoints,
target changes, team changes, demolition and EMP cannot replenish or pause the
budget. Folding then takes up to half a second, followed by the bounded braking
dwell. Construction time and the rail launch are outside the budget.

Once per second the script sets the decreasing native wantedHeight, calculated
from absolute simulation age. The first update is staggered by unit ID to spread
same-frame swarm launches. This setter happens to live at
Spring.MoveCtrl.SetAirMoveTypeData, but it modifies the active native
CStrafeAirMoveType; it does not enable script-controlled movement. No Lua loop
sets flight position, velocity, heading, banking or orbit waypoints.

The engine interprets wantedHeight as terrain clearance. Its normal terrain
avoidance can briefly raise the aircraft over a ridge, and actual altitude
responds through aircraft physics rather than following a prescribed vertical
velocity. The declining allowance is still tied to absolute elapsed time.
Faster descent or movement over lower terrain can shorten the deadline; terrain
changes cannot extend it.
This is a finite gameplay glide, not a full simulation of unpowered energy
conservation. Setting the altitude target to zero alone would not guarantee
termination: normal native aircraft can clamp/bounce away from terrain.

At expiry, the current order is no longer relevant. Icarus folds, selects the
native braking profile and releases the same native bomb at its **current
position**, with the momentum remaining after braking and downward vertical
velocity. It cannot travel indefinitely toward
an unreachable target. A permanently stunned aircraft also expires; this passive
release is independent of the native weapon's stun gate.

## One map-wide rooftop calculation

game_building_clearance.lua calculates one absolute skyline height for the
generated city. After CitySpawnComplete, it takes one map-wide unit snapshot.
Each procedural house contributes its selected, transformed geometry once its
layout is ready, including rooftop decoration. This happens before slow cosmetic
construction reveals. A house still choosing its layout waits for its readiness
event; there is no readiness polling or provisional hidden-variant model height.
Whole static buildings can use their conservative native model bounds.

Piece matrices and the unit basis include world elevation and importer scale.
Hidden alternative building variants never become physical rooftops. Detailed
measurements are spread across at most four queued buildings per frame during
this one initial calculation.

If a house script fails to report its plan within 60 simulation seconds of the
snapshot, its physical collision envelope supplies a fallback. This recovery
uses the same four-entry frame budget, warns once for each failed house and
does not rescan the world. A getter that throws an error uses that fallback
immediately, with its unit-script context restored. A broken house script
therefore cannot indefinitely block Icarus launches.

When all captured live buildings are resolved, the maximum is frozen and saved
in game rules. Every Icarus reuses that one value. Destruction, raid hiding,
reconstruction and later buildings do not recalculate it; the skyline gadget
also removes its frame/destruction callbacks. Reload reads the saved result
without rescanning the map. An empty city saves a valid zero-height result.
No glider scans houses, pieces or nearby units.

## Commands and phases

| Phase | Behavior |
| --- | --- |
| Building | Casing/sabots remain visible; construction and an initial EMP finish before launch. |
| Ascent | The existing 2048-elmo rail launch emits the Nimrod departure effect once and separates the sabots. This is the only enabled MoveCtrl phase. |
| Unfold | The original base/tail orientation, rotor, wings and telescoping panels finish their animations. A launch already beneath the skyline threshold stays folded. MoveCtrl is disabled. One native movement goal starts airborne circling even without a player order. |
| Loiter | Native aircraft steering circles around its holding goal while the altitude allowance declines. The native turn radius and physics determine the path. |
| Transit | The engine processes MOVE/PATROL/FIGHT and explicit ATTACK commands. The Lua script does not implement command navigation or move the aircraft toward a target. |
| Fold for attack | A cheap preparation check runs only during an explicit attack. It starts folding ahead of the native ballistic release window, allowing for braking. BlockShot rejects release until both wings and panels finish and the braking dwell expires. |
| Native attack drop | The AircraftBomb weapon chooses its ballistic release point using the aircraft's actual reduced velocity. The original aircraft becomes a hidden owner only after the projectile has actually been created. |
| Exhausted drop | At the shortened deadline or actual clearance threshold, folding, native braking and one local native projectile release happen regardless of target or EMP. |
| Cleanup | The projectile destruction event starts the finite blast-propagation grace period, then the original owner is reclaimed without a second explosion. |

After folding, a single native maxSpeed change recalculates CStrafeAirMoveType's
aerodynamic drag. The engine reduces forward motion during the braking dwell;
Lua does not force a velocity, teleport to a target or steer the projectile.
The slow profile also reduces lift and turning authority, so proactive folding
requires an aligned approach. If an unreleased approach loses alignment while
clearance remains sufficient, the script restores normal speed and unfolds for
another pass. Separate entry/cancellation thresholds avoid repeated toggling.
The AircraftBomb itself has no horizontal drag, so it inherits the remaining
velocity and falls along the native ballistic arc. Gravity makes that arc
progressively steeper. A moving target may evade after release; the bomb does
not home or stop perfectly above it.

Release requires the current explicit, non-internal ATTACK designation and the
native weapon's userTarget flag. A unit designation retains the GROUND category
restriction and must still be in the owner's LOS or radar at release. Animation
preparation reads its position through CallAsTeam, preserving radar error.
Changing fire state does not by itself authorize a strike.
The native noChaseCategory filter excludes every eligible GROUND target from
idle/FIGHT auto-selection. Explicit ATTACK bypasses that filter. This matters
because a native FIGHT-generated attack can inherit a user-target flag; that
flag alone would not establish an explicit bomb designation.

With sufficient clearance, STOP, a changed active designation, lost/dead targets
or EMP prevent a commanded release, restore native flight speed and reopen the
wings. At insufficient clearance the terminal transition is irreversible:
those events cannot reopen the wings or save the remaining glide allowance.
Appending an unrelated shifted command preserves
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

For an idle airborne Icarus, a normal one-second update consists of GetGameFrame,
position, velocity and terrain reads, and one SetAirMoveTypeData call. Diagnostic
rules parameters update only when the deadline or rounded clearance changes.
There are no idle target/command reads or per-glider building scans. The previous
flight controller ran at 10 Hz and made about 90 Spring/MoveCtrl calls per second
in idle flight; the ordinary clearance-aware update uses five calls per second.

This is a measured script-call reduction, not an FPS benchmark. Native aircraft
physics still has its ordinary per-unit cost. Attack preparation adds a small
amount of work at 1 Hz only while an explicit attack is active; animation and
command callbacks occur at transitions.

tests/icarus_flight_test.lua runs the actual production script with multiple
coroutines, signal masks, completed animation waits and explicit native command,
shot and projectile events. It verifies launch/handoff, idle call budget,
declining altitude, the nonrenewable lifetime under orders and EMP, actual
rooftop/descent clearance, native braking configuration and dwell, forced local
expiry, guarded cancellation, visibility, one-shot attribution,
cleanup, spawn failure and crash cancellation. Native aerodynamic movement is
deliberately opaque in this harness; it does not fake an engine flight test.

tests/icarus_lifecycle_test.lua checks the event bridge, including reload
recovery and synchronous event ordering. tests/icarus_clearance_test.lua checks
selected-piece bounds, world transforms, delayed layout readiness, the single
map-wide pass, bounded failure recovery, freezing and zero-scan reload.
The existing crash, model orientation,
Nimrod launch and effect suites remain applicable.

An in-engine visual pass should cover idle descending circles, MOVE/PATROL,
ground and moving-unit designation, STOP or EMP during folding, passive expiry
with no target, elevated/low buildings, and a normal AA kill. Inspect the
first-pass fold/brake/release timing, terrain response, launch wake, model
orientation and single impact. The Lua fixtures do not certify native
aerodynamic trajectories or visual/FPS performance.

## Exact target-engine references

These checks use Recoil BAR105 105.1.1-1544-g058c8ea:

- [Native movement setter](https://github.com/beyond-all-reason/RecoilEngine/blob/058c8ea/rts/Lua/LuaSyncedMoveCtrl.cpp):
  SetAirMoveTypeData modifies the active native type without enabling MoveCtrl.
- [Native aircraft movement](https://github.com/beyond-all-reason/RecoilEngine/blob/058c8ea/rts/Sim/MoveTypes/StrafeAirMoveType.cpp):
  bomber steering, terrain clearance, altitude defaults, SetMaxSpeed's drag
  recalculation and per-frame native drag integration.
- [Air command processing](https://github.com/beyond-all-reason/RecoilEngine/blob/058c8ea/rts/Sim/Units/CommandAI/AirCAI.cpp):
  native command handling and the script-movement early return.
- [Native bomb release](https://github.com/beyond-all-reason/RecoilEngine/blob/058c8ea/rts/Sim/Weapons/BombDropper.cpp):
  ballistic range, AimWeapon angle bypass, inherited velocity and projectile TTL.
- [Weapon callback order](https://github.com/beyond-all-reason/RecoilEngine/blob/058c8ea/rts/Sim/Weapons/Weapon.cpp):
  BlockShot before salvo commitment, FireWeapon before projectile creation.
