# Atmospheric clouds moved to Dhubai

The disabled `luaui/widgets_mosaic/gfx_volumetric_clouds.lua` and its
`shaders/fogShader.vert` / `shaders/fogShader.frag` now live in the Dhubai map:
`PicassoCT/MOSAIC_LastDayOfDubai`, branch `map/dhubai-volumetric-weather`.

The map enables its own **Dhubai volumetric weather** widget, with occasional
morning fog, smog and sandstorms. MOSAIC already loads `LuaUI/Widgets_Map/` from
the map archive. The map contains the noise texture needed by its renderer.

`luarules/gadgets/gfx_cloud_volumes.lua` remains the independent unit-effect
renderer for pump smoke, launch clouds, explosions and aerosol volumes. Shared
game noise textures also remain for other shaders.

## Lighting fog and dust

The radiance widget now exports `WG.GetMosaicFogRadiance()`. It returns `nil`
until a valid field and height atlas are available, otherwise a borrowed,
version-1 descriptor:

| Field | Meaning |
| --- | --- |
| `texture` | Existing global scene radiance, map XZ coordinates |
| `heights` | Nearest-filtered RGBA16F: world base, top, vertical fade, coverage |
| `occupancy` | Existing scene-layer occupancy |
| `strength` | Current scene-lighting gain |
| `headlights` | Optional live headlight field |
| `headlightIntensity` | Headlight day/night gain |

Consumers must reacquire the descriptor each draw, never modify it or delete
its textures, and require height data rather than falling back to the flat
rain field. The new export is registered only if its slot is empty and removed
only by its owner. Calling it requests height updates at the normal 5 Hz atlas
refresh. Without requests for 0.6 seconds, height refreshes stop. The 512-square
color/depth targets allocate lazily and are released at widget shutdown;
allocation failure disables this optional path without retrying every frame.

`include/radiance_fog_heights.lua` collects contributing, visible units using
world position plus imported model min/max Y. Unit height is the fallback;
unknown height is omitted. A separate read-only headlight source getter returns
the same visible lamp anchors and 48-vehicle budget used by the cone emitter.
Elevated lamps keep their world height rather than lighting ground-level fog.
Each metadata texel chooses the nearest source with a finite horizontal reach
and rounded vertical fade; different source heights are never averaged.

The Dhubai shader applies these bounds at every ray step and integrates local
light with foreground extinction. It uses the existing 2D radiance and occupancy,
so overlapping source colors and whole-building bounds remain approximations;
this is not per-emitter 3D illumination or a new shadow solve. The new textures
cost about 3 MiB, plus metadata capture and conditional ray-step lookups. In-game
visual review and GPU timing remain necessary.

Use `/dhubaiweather fog` (or `smog`, `sandstorm`) and
`/dhubaiweather light off` / `light on` for local comparisons on the paired map.

Validation: `tests/fog_radiance_heights.lua`,
`tests/neon_radiance_lifecycle.lua`, `tests/headlight_cone_lifecycle.lua`, and
`MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/fog_radiance_heights_gpu.py`.
The map's `tests/volumetric_weather.py` and `tests/volumetric_weather_gpu.py`
cover the consumer and actual fog shader. The headless GLSL checks do not replace
an in-engine run.
