# Bag and trailer alignment

The branch fixes civilian and civilian-agent bags, plus the long-truck trailer.

Bags use the handle-to-bounds-centre direction of each selected piece, so sideways T-pose geometry does not assume local +Z is down. The controller uses the engine's already accumulated model-space piece matrix, factors out the current script rotation, and transforms gravity into that frame. Script angles follow Ry * Rx * Rz. Model uniform scale is normalized. Bags with an off-centre handle or unusual geometry may require an explicit authored down-axis override after visual testing.

The animation player reserves registered bag pieces for this controller and reports pose-command durations. One finite worker per civilian updates both bags every 100 ms during parent motion and swing settling, then finishes with gravity alignment. It has no permanent idle polling loop. Runtime cost scales with the number of bag-carrying civilians actively animating. Pose changes outside PlayAnimation must notify bagAlignment.wake(durationMs) as well.

The long truck subtracts wrapped signed tractor-heading changes from its local trailer yaw. Stationary trailer world yaw stays fixed; physical movement enables symmetric exponential straightening (six-second time constant). Existing motion sampling and terrain pitch adaptation stay in the trailer loop. The hitch's parent centre is assumed to have no independent scripted yaw, as in the current model script.

Validation:
- All five changed Lua files pass Lua 5.1 syntax parsing with luaparse.
- Independently checked 49 alignment direction pairs in JavaScript, including opposite directions and Euler poles.
- Added tests/bag_trailer_alignment_test.lua covering those directions, animated parent transforms, no correction feedback, finite worker restart/coalescing, both trailer turning directions and heading wrap.
- Lua execution and in-game rendering are unavailable in this session; the Lua regression suite has not been run here.

Run from the repository root:
    lua tests/bag_trailer_alignment_test.lua
    lua tests/event_thread_optimizations_test.lua
    lua tests/prayer_animations_test.lua

In game, inspect shopping bags and handbags across civilian variants while walking, stopping, talking and praying. Turn a stationary long truck clockwise and anticlockwise, including across the heading boundary, then drive it forward to check smooth straightening.
