# Antagon Human Shield and passenger animations

Select an **Antagon-owned Propagator or Asset**, choose **Human Shield**, and
click an ordinary civilian. The operative approaches within 80 world units and
attaches the civilian to the model's authored **`hostagePoint`**. Protagon-owned
versions of either unit do not receive the ability. The command also checks the
current owner when it executes, including after a capture or team transfer.

The civilian stops normal city and parade activities while held. The operative
uses a restraint stance with breathing, short matching steps, and a one-arm
aiming pose. The hostage breathes, struggles, and shuffles with the operative.
Inside an allowed car, both use a seated restraint pose. Releasing the civilian
restores the ordinary animation systems and movement.

## Rules while holding a hostage

- The operative moves at **60% of normal speed**. The factor composes with later
  scripted speed changes and does not slow a car carrying the operative.
- Hostile **Protagon** units cannot attack, damage, or interrogate the operative
  or hostage with ordinary weapons. Protection includes automatic targeting,
  explicit and queued attacks, in-flight damage, and scripted hit effects.
- **Sniper Rifle** and **Slow Sniper Rifle** remain effective. This is a
  per-weapon exception; a mixed-weapon Asset's ordinary guns stay blocked.
- An opponent can also initiate **close combat**. Its contact weapon remains
  available, and entering the fight releases the civilian to run away. A unit
  with a melee weapon still cannot shoot through the shield with its guns.
- The carrier cannot fire **any** weapon while holding someone. Taking a
  hostage cancels unfinished burst rounds without resetting reload time or
  returning ammunition. Projectiles already fired remain in flight.
- An explicit **fire/attack order kills the hostage**, ends the shield, and
  leaves the ordinary attack order available to the operative. The gadget waits
  until the engine actually adds a new matching command to the queue. Rejected
  orders, invalid insertion tags, shift-click cancellation, and internal AI
  targeting cannot accidentally execute a hostage. A valid newly queued fire
  order has the same consequence as an immediate order.
- **Aim mode keeps the hostage.** Looking at or tracking a target, changing fire
  stance, moving, or an attack that was already queued before capture does not
  execute the captive. Actual weapon discharge remains blocked.
- **Release Hostage** replaces the capture button while holding someone.

| Activity or transition | Hostage behaviour |
| --- | --- |
| Standing, walking, turning, aim mode | Keep the hostage and animate the hold. |
| Riding in an ordinary civilian road car or truck | Keep the hostage; use seated poses. **The vehicle remains attackable.** |
| Entering disguise | Release the hostage before cloaking. Taking a hostage decloaks the operative. |
| Building, repairing, reclaiming, resurrecting, capture work, or interrogation | Cannot hold a hostage during the activity; release safely. |
| Rooftop approach, grappling, traversal, or perching | Release; no rooftop hostage use. |
| Parachuting, flight, motorcycles, or other unsupported transport | Release; cannot take a hostage in that state. |
| Entering melee | Release immediately and send the civilian running away from the fight. |
| Incapacitation or ownership change | Release and remove any unavailable command. |
| Operative death | Release a living hostage. |
| Hostage death | End protection immediately and run the normal civilian death animation. |

Car permission applies to the existing civilian road-vehicle pool. A vehicle
being carried by another transport is not a valid exception. The shield never
extends to the enclosing vehicle. Building the Steal Vehicle icon is still a
building activity and releases a hostage; boarding an existing car can retain
the hold.

The capture target must be a living, visible, unarmed Gaia pedestrian. Disguise
bodies, player-owned agents, already transported civilians, and participants in
interrogation or close combat cannot be taken. Aerosol effects release a hostage
before continuing their existing behaviour. Safehouse human-shield purchases
and propaganda retain their existing rules.

## Ordinary truck passengers

Civilian passengers also have a dedicated seated, bracing transport animation.
It pauses their ordinary walking and ambient poses, reacts to vehicle movement,
and restores the previous transforms and normal activity after unloading. The
hostage animation has priority when the civilian is held by an operative, so
boarding a car with a hostage does not replace the restraint pose. Parachute and
other airborne transport keep their own activity rules.

## Configuration and model integration

`luarules/configs/human_shield.lua` defines capture range, movement factor,
eligible carrier names, the attachment piece name, and sniper and melee weapon names.
The command IDs are 33461 and 33462. `game_operative_human_shield.lua` owns
attachment, owner/activity eligibility, targeting, damage filtering, accepted
fire-order handling, and cleanup. Each operative script exposes live activity
readiness and manages its animation and disguise state.

The attachment uses **`hostagePoint` exactly**, with no inferred center or
collision-volume offsets. A missing point disables capture. The marker geometry
is hidden while its transform continues to position the hostage. The repaired
Propagator export preserves the complete original body and rig together with
the newly authored point; the initial point-only export is not used as the
whole operative model.

The unit-script framework checks protection before existing `BlockShot`
callbacks. Native burst rounds also require the explicit capture-time salvo
cancellation described above. Projectile impact and counterintelligence handlers
use the same protection predicate. See the
[Recoil Lua API](https://recoilengine.org/docs/lua-api/).

Civilian traffic records remain registered while held or performing their escape
activity. Animation helpers replace outstanding native movement targets before
restoring saved transforms. Signal ownership and generation tokens prevent old
animation threads from taking over a later capture or transport cycle.

## Validation

Tests live in the external `mosaic-tests` suite, as required by `AGENTS.md`.
The Human Shield workflow runs the production gadget, animation helpers, and
relevant script callbacks under Lua 5.1 with mocked engine boundaries. Coverage
includes faction ownership, attachment failure, activity exclusions, vehicles,
melee escape, target and weapon rules, real command-queue evidence, burst
cancellation, animation ownership/restoration, and civilian traffic recovery.

An in-engine visual and multiplayer smoke test remains necessary:

1. Take and release civilians using both Antagon operatives, including while
   moving and while disguised. Check attachment height, feet, restrained arms,
   turns, aim tracking, and the movement penalty.
2. Try Protagon-owned versions and transfer a carrier between factions. Verify
   command availability changes and a held civilian is released.
3. Compare aim mode with a real attack order. Aim keeps the captive; a valid new
   fire order kills the captive and ends protection. Try capture during an
   Asset's SMG burst and confirm no remaining burst rounds fire.
4. Test normal Protagon infantry, interrogation, mixed-weapon Assets, sniper
   turrets, and Argus III. Only sniper fire and the close-combat contact weapon
   bypass protection; melee frees the hostage. Try taking a hostage while
   already interrogating someone and verify that capture is unavailable.
5. Board and leave a civilian car with a hostage. Attack the car itself. Also
   test roof movement, parachutes, building, disguise, stun, and melee escape.
6. Load ordinary male and female civilian variants onto trucks, drive, stop,
   and unload. Check seated bracing, absence of parachute/walking poses on the
   truck, and normal ambient behaviour after unloading.
7. Repeat release and death cases with parade participants, rain, aerosol
   effects, and multiple capture/transport cycles.

Lua regression results do not establish native visual alignment, frame rate,
or multiplayer synchronization results.
