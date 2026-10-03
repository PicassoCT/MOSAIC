# Frame Grapher

Enable **Frame grapher** in the developer options, or run:

```
/luaui enablewidget Frame Grapher
```

Disable it with `/luaui disablewidget Frame Grapher`. It is disabled by default.

The bottom-right graph shows the last 512 intervals between consecutive
`DrawScreen` callbacks, oldest on the left. Green bars meet the 40 ms / 25 FPS
target, amber bars take up to 80 ms, and red bars exceed 80 ms. The vertical
scale expands to keep long stalls visible. The header reports mean interval,
its reciprocal FPS, the 95th percentile, and the peak. Statistics refresh every
half-second, and immediately for a new peak. Hiding the GUI pauses sampling.

These are wall-clock frame intervals, including rendering, simulation, waits
and the graph's own overhead. They are not GPU timings or function flamegraphs.
Use the engine profiler, Widget Profiler or Tracy to attribute a slow frame.
The engine debug overlay has its own independent frame graph.

The widget uses standard timer and drawing APIs; it does not require the
`gl.LuaShader` / `gl.InstanceVBOTable` helpers that caused the previous load
failure. It no longer guesses sim/update/swap phases from callback ordering
or relies on the undispatched `GameFramePost` callback.

Regression check, from the repository root:

```
texlua tests/frame_grapher.lua
```

In-engine check: enable the widget, confirm it appears without a Lua error,
then resize the window and hide/show the GUI. A real long frame should raise
the graph scale and peak rather than vanish. Compare timings with the graph
and other debug overlays disabled when making performance measurements.
