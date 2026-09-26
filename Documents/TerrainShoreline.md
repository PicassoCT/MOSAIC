# Shore-wave handover

Built on master `6ea5d9fb161c625238306640b36714989e566f78`. This preserves its
randomized channel generation, original channel scale, foam/spray regimes,
geometric slope separation, retained wetness and scene-depth visibility fix.

The terrain rain pass now fades its complete surface contribution near sea
level. In `surfaceWater.glsl`, `TERRAIN_SHORE_CLEAR_HEIGHT = 2.0` keeps the lowest
two engine height units clear of terrain rain water. `TERRAIN_SHORE_FULL_HEIGHT
= 8.0` restores full strength at eight units; smoothstep blends between them.
These are heights above the existing y=0 water plane, not horizontal distances.

The final alpha, additive highlights/foam and `/rainview runoff` mask share the
same fade. It is applied after relief derivatives, so the cutoff cannot create
a new bright rim. Runoff spray is attenuated at its source with the same mask.
Roof water, falling rain, ordinary impact droplets and the engine's sea/shore
waves keep their existing rendering.

This is a fixed, inexpensive height band, not a mask of individual wave crests.
It needs no new texture, draw pass or terrain sampling. Its horizontal width
depends on beach slope: shallow beaches have a wider transition. Set the two
constants to the map's desired surf reach, then `/luaui reload` to retune.
A true shoreline-distance field would be needed for a constant-width band on
complex coastlines; the engine's internal wave/coast texture is not currently
bound to the rain shader.

In-game check: use `/Weatherman on`, allow the ground to wet, then inspect the
coast at a low camera angle. `/rainview runoff` should go dark before the water
edge and fade in uphill. `/rainview off` restores the scene. Check rooftops near
sea level as well: they should retain their water. `/rainsnap` retains the
existing settled levels and labels this shader `terrain-shore-handover-v6`.

Run `python tests/rain_shore_cutoff_gpu.py`,
`python tests/rain_shore_visibility_gpu.py`, and
`python tests/rain_flow_regimes_gpu.py` with Mesa EGL and Pillow. The cutoff probe
compares the complete production shader with an unfaded reference across both
depth conventions, wetness levels, slopes and terrain/model ownership.
