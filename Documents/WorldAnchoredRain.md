# World-anchored falling rain

Falling precipitation now uses a separate `worldRain.glsl` include. A fullscreen
pass traverses a maximum of 48 world cells using DDA, evaluating one finite
analytic streak per occupied cell. It is not a density raymarch or particle
simulation. Cell identities translate with a fixed rain velocity, never with
the camera. Finite segments naturally become dots in a directly downward view.

The 64-unit grid, 1400-unit visible span (from entry into the existing 0–1024
rain-height slab), and 48-cell bound cover diagonal traversal. Distance fading
limits the far cutoff. Scene depth clips precipitation against opaque geometry.
Analytic coverage includes a bounded pixel footprint to soften thin streaks.
Sun/sky and the existing day/night palette remain; radiance is borrowed from
the existing local/global fields and sampled at each actual visible streak.
The existing occupancy field rejects light in occupied cells; it is not a full
3D roof/shelter mask and does not promise dry interiors.

Wet-surface reflection tracing, sheen, ripple scale and ripple animation remain.
Ground/model normal selection still chooses the nearest available surface by
depth, with the original nonblack-normal eligibility restored instead of
requiring deferred depth to be populated. Normal alpha no longer rejects unit
surfaces. The original encoded upward threshold (green >= 0.995) is unchanged.
Spring/Recoil world-up is Y, even if imported model authoring uses Z-up.
Legacy screen-texture precipitation is no longer called, including the fallback
that previously painted rain over non-puddle surfaces.

## Sloped surface runoff

`surfaceWater.glsl` adds world-space meandering rivulets. Highlights travel along
gravity projected onto the surface tangent plane. Decoded normal Y blends
puddles/ripples to channels across 0.995–0.94 (roughly 6–20 degrees from flat).
Channel wetness fades across normal Y 0.92–0.45 (roughly 23–63 degrees), reaching
zero on steep walls/down-facing surfaces. Terrain and unit roofs share the same
selected normal. Reflection eligibility stays at its original strict threshold;
the broader slope transition is only for surface water. Coverage multiplies
alpha after the original alpha floor so walls cannot retain a minimum water veil.

## Validation

Run `python tests/world_rain_gpu.py` (stdlib, libEGL and libGL only). Tests compile
and link the assembled production shader, render terrain/unit normal combinations,
check wall/ground depth ordering and empty sky, render cardinal/oblique rain,
test deterministic time, depth rejection and animation, and compare a shifted
orthographic camera's overlapping pixels for identical world-ray precipitation.
`rain_light_glitter_gpu.py` also assembles the new include.

Still required in Recoil: camera orbit/zoom and paused pan; rooftop and ground
ripples; day/night and neon/headlight glitter; low-angle horizon views; density
and GPU timing at native resolution on the target NVIDIA 1050 Ti. No speedup is
claimed over the old cheap 2D rain textures. No new render targets are allocated.
