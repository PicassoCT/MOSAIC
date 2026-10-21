# Airport contrails and F35 exhaust

The airport's large circling plane has two pale condensation trails on its
outer steering fins. The F35 has a compact blue-white afterburner fading
through warm orange, with a separate faint grey smoke trail behind it.
Both use the existing procedural FlamePainter (`GG.SmokeRibbon`) renderer.

## Attachments and lifecycle

| Aircraft | Attachment | Active period |
| --- | --- | --- |
| Airport circling plane | Actual aft tips of `LeftWing` and `RightWing`; rearward direction from `MainBirdBody1` | `showPlane()` through `hidePlane()`, with cleanup on airport death |
| F35 | Actual nozzle center within `bodyFly`, ahead of the tail fins' rear bound | Completed, moving aircraft in engine `flying` state, above terrain/water, outside transport and crash states |

Airport trail roots inherit the animated fin transforms. The common hull
direction keeps steering deflections from swinging the trails sideways.
Their 680-unit length and 16-unit width are sized against the imported
48.66-unit fin chord and 44.05-unit fin height. The trails follow the airborne
pieces even when the airport building is shown as an icon. Normal visibility,
frustum and shared renderer limits still apply.

The F35 has no dedicated exhaust piece. Its nozzle location is expressed as
fractions of the `bodyFly` bounds, derived from the nozzle ring in the DAE.
Effect sizes include the imported piece-matrix scale. At the current model
scale the nozzle diameter is about 3.14 units, the hot plume is about 22 units
long, and the smoke extends about 163 units before motion/wind bending.
The smoke has zero emission; only the short afterburner illuminates itself.

F35 eligibility is checked every 250 milliseconds of simulation time, rounded
to engine frames, and on movement callbacks. The registry changes only when
emission starts/stops or its API is replaced. Engine flight state is checked
instead of treating a stop command as landing: holding circles remain flight.
`BeginAircraftCrash()` and `Killed()` immediately remove both slots and stop
the controller. Grounded, unfinished, transported and motionless aircraft do
not emit.

## Fading and cost

Both trail types fade to transparent along their length using FlamePainter's
existing density and alpha gradients. The renderer approximates attached
plumes: smoke follows the emitter and does not leave a persistent curved wake
in world space. Emission disappears when its flight condition ends.

There are two named slots per aircraft and two strands per slot. Repeated
cycles replace or remove those slots; they do not accumulate particles or
emitters. The cached strip meshes, shared shader, visibility filters and
128-emitter drawing limit are unchanged. No new render pass or texture is
introduced. Airport emission uses existing animation events without polling;
each F35 adds one lightweight flight-state check loop.

## Validation

Run from the repository root:

```sh
lua5.1 tests/aircraft_ribbon_lifecycle.lua
lua5.1 tests/f35_rearm_test.lua
lua5.1 tests/smoke_ribbons_lifecycle.lua
lua5.1 tests/objective_ribbon_flames_lifecycle.lua
```

`luatex --luaonly` can also run these tests. Aircraft lifecycle tests exercise
the real registration validator, mirrored wing attachments, imported scale,
flight gates, idempotence, API recovery, registration rollback and death.
The existing F35 bomb/rearm behavior is covered separately. These checks do
not replace an in-engine visual check of attachment, brightness and scale.

For a local visual check, use `/cheat` and `/give air_plane_fighterjet`, then
give it a flight order. Select it and run `/smokeribbon status`: an eligible
aircraft has two registered slots. Observe the airport plane through an
arrival/circling/departure cycle; both fin trails should appear and disappear
together. Existing airport scramjet flames remain separate slots.
