# Civilian stops

Ambient Gaia traffic now finishes a movement leg before dwelling at a building
curb. The native mover supplies acceleration and braking. A stop begins only
when the move command has completed and velocity is below the configured
threshold. The existing travel loop issues the next leg once the hold expires;
it never reissues the leg that just finished. There are no movement orders or
speed writes during the dwell.

`luarules/configs/civilian_traffic.lua` contains participation chances, durations,
parking limits and junction settings. Ordinary cars have a 20% chance per
destination of parking for 60–180 seconds. Freight profiles use the existing
60–300 second truck-break bounds, divided into unloading and loading phases.
Buses keep short passenger stops. Motorcycles and other body classes have
separate profiles. Selection is deterministic per vehicle, trip and waypoint;
it does not consume the shared engine random stream or reroll every update.

At most 24 vehicles, and at most 30% of registered ambient vehicles (rounded
down, with a minimum allowance of one), can reserve parking simultaneously.
Nearby reservations and occupied curbs reject additional parking. Stop releases
are separated by at least five simulation frames. These are tuning limits,
not measured CPU guarantees.

## Junctions

Once the city road network is frozen, a spatially indexed intersection pass
selects 25% of actual junctions, up to 12. Ordinary bends are excluded. Straight
route legs aligned with both sides of a selected junction receive a stop point
and an exit point, with opposite approaches offset onto opposite sides. Both
points must pass the unit's native movement test. Short legs, turns, tightly
spaced junctions and paths that do not align with the road are left unchanged;
this is not a complete lane-routing or traffic-light simulation.

Vehicles stop for at least two seconds. Arrived vehicles are released in order,
with a unit-ID tie-break, a minimum headway, an exclusive crossing reservation,
and checks that the center and exit are clear. Intentional waits and nearby
queues bypass the old stuck/deletion logic. Failed approaches have a bounded
grace period before ordinary recovery resumes. A blocked exit retains its hold;
no timeout authorizes a vehicle to drive through an occupied intersection.

## Ownership and vehicle dynamics

The activity controller reads `vehicle_profile` from `GG.CivilianVehicles`'s
rules parameters, including the actual selected long-truck body. It never
changes max speed, acceleration, braking, payload identity or speed factors.
Capture, transport, parade ownership, internal behaviors, danger, destroyed
destinations and changed routes cancel reservations. Captured vehicles receive
no traffic orders from transfer callbacks.

Ownership callbacks deregister the unit and cancel pending speed restores.
Each travel event holds its original registration record; it expires if that
record is removed or replaced. New trips require a registered Gaia unit.
Flee scripts and emergency payload jobs check the same registration after
every sleep, so an old job cannot resume when ownership changes or the vehicle
later returns to Gaia.

`traffic_activity` and `traffic_activity_until` are published in LOS on state
transitions. Activities are `approaching`, `queued`, `parked`, `unloading`,
`loading`, `intersection` and `driving`. Loading/unloading currently describes
dwell phases; it does not replace cargo, change cargo mass, or animate doors.
This preserves the selected payload and the concurrent dynamics work.

## Verification

External regressions live in `/home/picasso/MosaicDev/tests/MOSAIC` and run with
that directory's `run.sh`. `civilian_traffic_activities_test.lua` exercises native
braking, profile selection, admission limits, cancellation, junction geometry,
opposing queues, release ordering and blocked exits. It also runs the actual
parent travel/stuck-recovery functions, checking zero orders during a stop and
exactly one next-leg order on departure. Related civilian, hostage, road and
vehicle-dynamics regressions pass on Lua 5.1.

In-engine appearance and pathfinding cost still need a live traffic run. Count
path requests separately from Lua movement orders: fewer Lua calls do not by
themselves establish lower pathfinding cost, especially around queued vehicles.
