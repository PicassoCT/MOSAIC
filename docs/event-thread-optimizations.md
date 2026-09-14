# Civilian, house, truck and groundwalker event threads

Based on master `dabc99d`. This pass replaces idle dispatchers and redundant
sensor threads while retaining animation playback and physical motion sampling.

## Prioritize by population

Future optimization priority is **live instance count × wake rate × cost per
wake**, including whether the thread actually starts and how long it is active.
Count instances by `UnitDefs[unitDefID].scriptName` in a representative match;
unit-definition counts are not a substitute for live population. Report estimated
wake reductions separately from measured Lua CPU time or frame time.

Mosaic's scheduler uses `max(1, floor(milliseconds / 33))` frames. At 30 simulation
frames/second, `Sleep(50)` wakes 30 times/second, `Sleep(125)` 10 times/second,
and `Sleep(250)` approximately 4.29 times/second.

| Population to count | Removed recurring wake-ups per instance per simulation second | Conditions |
| --- | ---: | --- |
| `civilianscript.lua` and `civilianagentscript.lua` | About 34.3 | Animation request and behaviour dispatchers waiting for work. Actual requests now create finite jobs. Aerosol takeover previously stopped normal behaviour dispatch. |
| Arabic, Asian and Western main house scripts | 1 | Stun watcher; effects now start only on request. |
| `LongTruckscript.lua` | 40 | Independent heading and position threads removed. Their necessary sampling now happens in the trailer animation. |
| `Truckscript.lua` | About 1.6 | Random 500–750 ms ownership watcher replaced by `UnitGiven`. |
| Trucks actively running `turnDeadGuyLoop` | Additional 40 | Heading and position threads merged into the towing animation. Do not apply this saving to every truck. |
| Groundwalkers | About 31 while the old detector was waiting | Idle heading detector and periodic turret reset removed. Moving aim now performs one bounded sample on demand. |

For example, **300 idle civilians** would avoid roughly **10,300 dispatcher
wake-ups/second**. This is an illustrative population, not a measured match or an
FPS claim. For truck motion, some query work remains in the animation consumer;
removing two coroutines does not remove all their computation.

The two garbage-simulation call sites share `GG.SimPlaceableCounter < 1`, with no
other writer found. The current startup cap is one instance across those call
sites, so the proposed many-house token queue is not part of this pass.

## External call and cancellation contract

`lib_event_threads.lua` is included once per unit-script environment and returns
a private keyed queue. Exposed functions remain callable by synced gadgets using
`Spring.UnitScript.CallAsUnit`. The queue creates its own unit-script coroutine,
clears the inherited signal mask before sleeping, and launches the actual handler
from that independent coroutine. Gadget callbacks themselves never sleep.

One pending key retains the latest arguments, including nil/trailing arguments.
Its first deadline is retained, so repeated requests cannot postpone it forever.
The pending key is cleared before execution, permitting a handler to schedule a
follow-up. Running handlers retain their existing signal masks and cancellation
rules. Unit destruction terminates the unit's threads through the existing engine
framework.

Civilian animation changes defer one simulation frame. Behaviour requests use the
existing 250 ms interval (seven frames), retaining the existing processing order
and aerosol takeover lockout. Existing exposed request functions are preserved;
the old flag-polling thread need not be started in `Create`.

The new ownership gadget forwards only `UnitGiven` to scripts which expose
`onUnitGivenEvent`. The truck handler queues the transfer and reads its current
owner when executing, so successive same-frame captures cannot apply stale
ownership. The broad, disabled generic-events gadget remains disabled.

## Related fixes

- House stun producers formerly set `boolStartThread`, while consumers checked
  `boolStartStunThread`. A single running effect now consumes accumulated stun;
  repeat requests extend it. Arabic houses also lacked their own `SIG_STUN`.
- Truck flee request functions shadowed the attacker argument, and their polling
  dispatcher was not started in `Create`. Requests now defer the actual enemy ID
  directly to the existing fleeing behaviour.
- Groundwalker moving aim waited for `boolUpdateRequestFlag`, but the detector
  manipulated `boolManualUpdate`. A short sample within the aim coroutine removes
  that endless wait. Turret restoration is scheduled after aim completion and
  cancelled by the next aim request.
- Truck motion still measures actual displacement, preserving detection of pushes
  and blocked motion. Position updates retain a minimum three-frame interval;
  heading is sampled when the animation consumes it, with wraparound handled.

## Validation

Run from the game root:

```sh
lua tests/event_thread_optimizations_test.lua
```

The test executes real changed functions and helpers with a deterministic mock of
unit context, coroutine scheduling, signals and destruction. It covers external
requests, inherited cancellation, argument preservation, coalescing, reentrant
requests, civilian behaviour order, aerosol takeover, repeated house stuns,
truck fleeing and ownership, physical displacement, heading wraparound, moving
aim completion, and 500 independent queues returning to zero pending threads.

Executed successfully with the available Lua 5.4 library. All 12 changed/new Lua
files also passed syntax checks. Spring/Recoil was not available for an in-game
run; the mock does not validate model-piece animation or visual timing.

In-game checks before merging:

1. Use a populated city. Walk/stop civilians and trigger filming, chatting,
   fleeing, prayer and aerosol behaviour; verify interrupted animations recover.
2. Stun each house culture twice during an effect, then again after it ends.
3. Move, stop, block and push long trucks; inspect trailer/tow alignment. Capture
   a loaded truck, and verify both its loadout team and subsequent fleeing.
4. Order a moving groundwalker to attack. Verify it shoots, restores its turret
   after aiming, and cancels restoration when a new target is acquired.
5. Count live script instances and compare profiler captures for the same map,
   population and activity. Avoid extrapolating rare-unit results city-wide.
