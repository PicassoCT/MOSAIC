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
- Guards explicitly target the reported attacker only while uncloaked, in Gaia
  line of sight, and within 1,200 units of the site. This also restricts a truck's
  mounted gun. Otherwise they return to their exit positions.
- The force stands down 120 seconds after the last objective hit. Captured guards
  leave this system immediately and are not removed by its cleanup.
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

Lua 5.1 tests: `tests/objective_security_test.lua`,
`tests/objective_income_test.lua`, and `tests/civic_objectives_test.lua` cover
response scaling/minimums, cooldown, spawn failure, blocked terrain, hidden
attackers, capture, reload, lethal hits, restoration and income conservation.
Recoil playtesting is still needed for actual vehicle exits, mounted-weapon
behavior and offshore shoreline placement.
