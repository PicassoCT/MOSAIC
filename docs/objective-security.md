# Corporate objective security

Positive damage to an intact Gaia objective dispatches corporate security from
its perimeter. Paralysis also counts as an attack. Gaia/environmental damage
and invalid/zero damage do not. Either player's attack can trigger the response;
the objective's income beneficiary does not grant immunity to friendly fire.

Security uses the existing armed APC (`ground_truck_mg`, including its mounted
gun) and tank (`ground_tank_day`). They remain Gaia units and receive a corporate
security tooltip. No player pays for or controls this response.

## Value and force size

The response budget is **five minutes of the site's current money income**,
sampled when the response is triggered, after that hit updates attack pressure.
This uses the same risk-weighted, map-wide income budget as objective payouts;
the buildings' placeholder construction costs are not their economic value.

Every response includes at least one truck. Military objectives also include at
least one tank, even if these minimums exceed the budget. The military list is
Combat Outpost, Westhem HQ and Floating Military Gyland. Additional definitions
can opt in with `customParams.objective_military = 1`.

Remaining budget buys further vehicles at their UnitDef money cost: currently
750 per APC and 5,000 per tank. Military sites prefer another tank when affordable,
then trucks. The default cap is eight vehicles per site, excluding the mounted
gun objects attached to trucks.

| Site income | Civilian response | Military response |
|---|---|---|
| 60 money/min | 1 truck | 1 tank + 1 truck |
| 300 money/min | 2 trucks | 1 tank + 1 truck |
| 720 money/min | 4 trucks | 1 tank + 1 truck |

The minimums are floors, so low-value sites deliberately receive more protection
than their budget alone would buy. Payouts themselves remain unchanged.

## Dispatch and pursuit

- Creation is deferred out of the damage callback and staggered at one vehicle
  per second, beginning on the next half-second update.
- Exits use the building's horizontal collision boundary and footprint, then
  search outward for passable, unoccupied ground. Failed creation retries.
- Existing ground vehicles cannot drive on deep water. Offshore sites search
  nearby shore, up to 1,536 units beyond their perimeter. A wholly isolated
  offshore site cannot fulfill the minimum without suitable ground; the pending
  response retries until stand-down. No vehicle is spawned onto the seabed.
- A fresh attack after 90 seconds can replenish the force. Surviving vehicles
  count toward its budget, so sustained damage does not create endless convoys.
- Guards explicitly target the reported attacker while uncloaked and in Gaia
  line of sight, including beyond 1,200 units from the site. This also applies
  to a truck's mounted gun. Attack orders queue a return to the passable exit
  followed by GUARD on the surviving objective. Losing sight, cloak, death or
  capture of the attacker immediately cancels pursuit and clears the gun target.
- Security vehicles use the roaming movement stance. Objective APCs receive
  1,024 elmos of local patrol sight (or retain a larger existing radius), instead
  of the stock chassis's 50 elmos. The mounted MG's 300-elmo sight alone cannot
  acquire many ranged attackers. This is ordinary, terrain-occluded LOS; unseen
  and cloaked attackers remain untargetable. Capture restores the original
  sight radius and movement stance.
- Existing attack, return and guard commands persist across controller updates;
  changed targets/sites, moved approach destinations or interrupted orders rebuild the queue.
  A settled guard is not repeatedly sent back to its exit. Security APCs use
  an explicit MOVE ahead of ATTACK until within 90% of the mounted MG's range.
  Before the gun attaches, they close to 256 elmos. The movement destination
  updates at the existing three-second cadence when the attacker moves at least
  64 elmos; unchanged movement survives updates and reloads. ATTACK takes over
  in firing range, and a retreating attacker starts another approach. The aiming
  proxy also uses 90% of the mounted range; its adjustment is restored on capture.
- The truck's existing 100-ms order-forwarding loop preserves an unchanged
  ATTACK/FIGHT command on its mounted gun, rather than dropping its target lock
  on every pass. It reads only the first command of each queue and still repairs
  missing orders and forwards changed targets to replacement guns.
- An engaged security APC checks its mounted primary gun's native firing lane
  at most once every three seconds, only within the gun's range. Two consecutive
  blocked observations with less than 16 units of intervening movement trigger
  a short sidestep (96 sideways, 48 forward). It tries at most two passable,
  on-map, above-water destinations without querying surrounding units.
  The gun keeps its attacker; the truck queues ATTACK, return and GUARD after
  the sidestep. A clear lane, completed move or nine-second timeout resumes
  normal pursuit. Target loss/change, cloak, stand-down or gun loss cancels
  recovery. Reload preserves its state and probe deadline.
- Recovery adds no update loop. With the eight-vehicle site cap, it performs
  at most eight firing-lane probes per site per three seconds (tanks do not
  probe), plus at most two terrain/move tests per recovery attempt. Engine
  firing-lane checks retain their normal collision/avoidance semantics; this
  does not add custom civilian-building ray tests or guarantee a clear route.
- The force stands down 120 seconds after the last objective hit: it stops
  pursuing and returns before being removed within 128 units of its exit.
  Blocked returning vehicles remain tracked and retry their return. Captured
  guards leave this system immediately and are not removed by its cleanup.
- The already-triggered response finishes even after a lethal first hit destroys
  the building. Attacking the destroyed marker does not call further security.
- Site IDs retain the force and cooldown across destruction/restoration and
  LuaRules reloads. Restoration cannot manufacture another minimum convoy.

All tuning is in `getGameConfig().objectives.security` in `scripts/lib_mosaic.lua`.
The controller is `luarules/gadgets/include/objective_security.lua`, called by the
existing objective gadget.

## Restoration remains unchanged

Destroying an objective creates its **15,000-HP destroyed-objective marker** and
reverses the faction receiving that site's income. Destroying the marker queues
the original building, fully built, at the original position and facing, and
reverses the beneficiary again. Creation retries once per second. There is no
builder, payment, construction timer, or progress-driven building animation.

## Verification

Lua 5.1 tests: `tests/objective_security_test.lua`, `tests/truck_attack_forwarding_test.lua`,
`tests/objective_income_test.lua`, and `tests/civic_objectives_test.lua` cover
response scaling/minimums, local patrol sight, explicit movement toward a ranged
attacker, delayed gun attachment, moving targets, persistent guard/pursuit orders,
mounted-gun approach range, bounded blocked-shot recovery, command/probe counts, cooldown, spawn failure, blocked terrain, hidden
attackers, capture, reload, lethal hits, restoration and income conservation.
Recoil playtesting is still needed for actual vehicle exits, mounted-weapon
behavior and offshore shoreline placement.
