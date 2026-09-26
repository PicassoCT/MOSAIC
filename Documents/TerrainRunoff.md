# Terrain runoff in the rain shader

This replaces the terrain Voronoi pattern inside `gfx_rain.lua`'s existing
fullscreen rain shader. It reads the same deferred ground position and geometric
normal as before. Roof beads, roof streams, landscape geometry, map textures and
the engine's ocean renderer are unchanged. No Recoil shader framework is needed.

The shipped `luaui/images/rain/terrain-runoff.png` contains a deterministic
recursive split/rejoin network. Streams divide around fixed synthetic islands,
collect tributaries and reunite downstream. Shared ports conserve graph flux;
both atlas axes repeat. One tile is 32 engine units. The 1024-square RGBA8 texture
uses texture unit 14, about 5.33 MiB including mipmaps, and replaces per-pixel
Voronoi searches with three filtered texture samples.

RG store square-root encoded bank and connected spill heights. Water expands
when its local head exceeds the spill threshold; it does not relocate channels
or regenerate obstacles as rain changes. BA store a complex wave phase, avoiding
a phase discontinuity at texture wrap. Waves match at graph junctions, with
varying spacing/speed along different branches. Filtering removes unresolved
crests. Distant masks blend toward mean coverage instead of thresholding a
single averaged bank height.

The texture is data, not a painted landscape. On slopes it uses fixed vertical
world projections with downhill height coordinates, blended using the geometric
normal. Level ground uses a horizontal bank field and impact rings. Falling rain
and impact rings respond to current rain; ground water persists during drainage.
High-flow crests receive a restrained foam highlight. Submerged ground is clipped.

## Rain levels and timing

The water head is `0.010 + 0.990 * wetness^1.85`. Settled atlas coverage for rain
10–100% is approximately 1.5, 4.5, 9.3, 15.9, 24.6, 34.3, 45.1, 57.3, 67.6 and
76.1 percent, before projection, antialiasing, slope and shoreline masks.
These are visual controls, not rainfall rates or a physical flood prediction.

Wetness approaches current rain exponentially: 8-second fill and 35-second drain
time constants. Starting dry, sustained full rain reaches about 86% wetness after
16 seconds and 95% after 24 seconds. After rain stops, roughly 37% remains after
35 seconds. Updates and crest motion pause with the game. Crest time integrates
changing speed so weather changes do not jump the animation's phase.

`/Weatherman on` forces rain and allows water to fill. `/Weatherman off` returns to
natural weather; a dry daytime map makes drainage easiest to inspect.
`/rainview runoff` shows the terrain water footprint; `/rainview off` restores
normal rendering. `/rainsnap` captures the existing 0–100% sequence with settled
water at each level, then restores both wetness and animation time on completion
or cancellation.

## Validation and limits

Run `python tests/world_rain_gpu.py`, `python tests/rain_network_gpu.py`,
`python tests/rain_channel_waves_gpu.py`, `python tests/rain_runoff_gpu.py`,
`python tests/rain_composite_gpu.py`, and `python tests/rain_surface_art_gpu.py`.
GPU probes require Mesa EGL/OpenGL and Pillow. The existing roof, geometry and
splashback probes also exercise the assembled production shader. Run
`lua tests/rain_capture_weather.lua` and `lua tests/rain_capture_lifecycle.lua`
for filling, drainage, pause, frame-rate and capture restoration checks.

Regenerate the asset with `python tools/rain/bake_runoff.py` using numpy, scipy
and Pillow. The generator validates graph flux, downhill edges and border ports,
then computes connected spill thresholds once; none of this runs in-game.

This is local visual runoff, not a terrain-wide drainage simulation. The fixed
network does not discover real boulders, buildings, watersheds or persistent
flood levels, and blended world projections can overlap on curved slopes. A
terrain-derived flow field would be a separate upgrade if those effects are
needed. GPU tests are synthetic shader renders; actual map appearance and target
hardware performance still need an engine run.
