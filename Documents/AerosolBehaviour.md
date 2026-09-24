# Aerosol victim behaviour

The civilian and civilian-agent scripts use `lib_aerosol_behaviour.lua` for
Tollwutox, Wanderlost and Depressol. The existing aerosol drone/warhead exposure
and lifetimes remain: seven minutes for Tollwutox, three for the other two.
Orgyanyl keeps its existing controller.

| Aerosol | Movement and pose | Behaviour |
| --- | --- | --- |
| Tollwutox | Hunched, reaching arms; slow shamble, faster pursuit | Pursues unaffected civilians/recruits; 30 melee damage every 1.25 seconds at contact. Otherwise gathers loosely with afflicted units or roams. |
| Wanderlost | Uneven dragging steps, loose arms and lolling head | Approaches unaffected civilians for contact infection; forms loose groups when no fresh target is nearby. Does not deal melee damage. |
| Depressol | Bowed head, drooping arms, listless wounded gait | Seeks an available hivemind, a walkable shoreline, or hostile armed ground vehicles/robots/turrets. Deals 8 melee damage every 2.5 seconds to provoke military retaliation. |

Depressol chooses by distance, favouring hiveminds. Full or unfinished hives
are ignored; targets that die, cloak, become allied, leave range or stop being
eligible are released. A victim that makes no movement progress for eight
seconds rejects that goal for twenty seconds and chooses another. Military
retaliation still follows that unit's normal weapons, fire state and targeting.
Ordinary traffic, aircraft and allied military are not danger targets.

Water search samples up to eight directions and four distances, then refines
at most four shoreline candidates. It requires walkable shallows beside deeper
water. Upon reaching water the victim collapses and expires after three seconds.
This does not teleport units, force them through cliffs, or change shared move
definitions. Maps without accessible shallows use the other targets or roaming.
Terrain feasibility is checked before ordering movement; normal engine pathing
and the progress timeout handle blocked routes.

Hiveminds now accept Depressol victims, including affected civilian recruits on
their own team, through the existing charge/capacity system. Other aerosol types
remain excluded from integration. The victim registries are cleaned on death.

`animations_civilian_aerosols.lua` registers poses before the existing rig-axis
conversion. Upper and lower animation workers own separate bones. Standing no
longer transitions an affected victim into a walking animation by itself. Old
social, cover and firing workers are cancelled on infection; damage still applies,
but ordinary panic, prayer and gun aiming cannot replace the affected behaviour.

Tuning lives in `getGameConfig().Aerosols`: `searchRadius`, `shambleSpeed`,
`lungeSpeed`, `meleeDamage` and `waterSearchRadius`. Speeds are fractions of the
unit's maximum, as required by `setSpeedIntern`.

The existing 250 ms worker drives deadline-based thinking at approximately 2 Hz.
Searches are staggered by unit ID and occur only when a new goal is needed;
movement orders replace old orders and are throttled. Unit-type classification
is shared. Wanderlost spread runs only in the existing shared two-second
collateral update, using a snapshot so fresh victims spread on the next pass.

Validation: `tests/aerosol_behaviour.lua` exercises the production controller,
both owning scripts, rig conversion, infection pass and hive worker using Lua
5.1 mocks. It covers target exclusions, melee cadence, blocked routes, water,
lifetimes and hive capacity. In-game animation appearance and navigation remain
to be checked.
