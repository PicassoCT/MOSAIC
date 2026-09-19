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

Wet-surface reflection tracing and sheen remain. Ripple diameter is now one-third
of the previous branch version; the shorter impact period also drives splashback.
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
puddles/ripples to channels across 0.9995–0.975 (roughly 2–13 degrees from flat).
Channels are spaced eight world units apart with a single screen-footprint fade,
so thin highlights survive ordinary gameplay zoom. Runoff receives atmosphere
and radiance colour rather than relying solely on a weak alpha mask.
Channel wetness fades across normal Y 0.92–0.45 (roughly 23–63 degrees), reaching
zero on steep walls/down-facing surfaces. Terrain and unit roofs share the same
selected normal. Reflection eligibility stays at its original strict threshold;
the broader slope transition is only for surface water. Coverage multiplies
alpha after the original alpha floor so walls cannot retain a minimum water veil.

## Splashback

`rainSplashback.glsl` adds sparse three-droplet bursts using the existing ripple
cell seeds and birth phase. One small ripple per coarse cell supplies splashback,
keeping its gather fixed despite the smaller rings. Initial velocity follows the combined terrain/unit
normal plus a small tangent spread; world gravity returns droplets to the surface
within 0.375 seconds (roughly one world unit peak height). This does not simulate
collisions with the falling streaks. Ripple and splash phases use the same shared speed constant.

The fullscreen pass gathers a bounded 3x3 ripple-cell neighbourhood. Inactive
impacts are rejected before texture reads; source depth and normal checks reject
hidden or discontinuous surfaces. Droplets are clipped against scene depth and
lit at their airborne positions by the existing atmosphere and radiance fields.
No particle objects, new textures, render targets or CPU per-unit work are added.
Intensity follows weather; density is sparse and the entire layer fades between
1200 and 2600 world units from the camera. Steep surfaces and grazing views fade
out to keep the small gather bounded. The gather is centred underneath the middle
of the airborne layer, allowing normal oblique RTS camera angles. Pixel-sized
filtering and a larger droplet radius preserve visibility; a footprint fade
removes unresolved distant spray. Skylight is added independently of radiance,
with brightness adjustment preserving the supplied blue/orange atmosphere hue. Surface water and reflections remain independently
composited beneath falling rain. Spray highlights add reflected light rather than
painting dim opaque dots onto bright roofs.

This is a conservative screen-space effect: it cannot seed hidden surfaces or
extend reliably beyond roof silhouettes. It also shares the existing rain's lack
of a full 3D shelter mask, so it cannot guarantee dry ground beneath an overhang.
Moving units sample the world-anchored ripple field rather than carrying persistent
object-local particles. Actual Recoil appearance and GPU cost need an in-game check.

## Validation

Run `python tests/world_rain_gpu.py` (stdlib, libEGL and libGL only). Tests compile
and link the assembled production shader, render terrain/unit normal combinations,
check wall/ground depth ordering and empty sky, render cardinal/oblique rain,
test deterministic time, depth rejection and animation, and compare a shifted
orthographic camera's overlapping pixels for identical world-ray precipitation.
`rain_light_glitter_gpu.py` also assembles the new include.

Run `python tests/rain_splashback_gpu.py` for the above suite plus rendered
splashback tests: ground and alpha-zero unit roofs, sparse animated droplets,
walls/sky/no-rain/distance rejection, hidden source and foreground-depth rejection,
both clip-depth conventions, camera-pan overlap, radiance colour/occupancy,
perspective reconstruction and sloped surfaces. These use Mesa software OpenGL;
they do not measure target-hardware performance.

Still required in Recoil: camera orbit/zoom and paused pan; rooftop and ground
ripples; day/night and neon/headlight glitter; low-angle horizon views; density
and GPU timing at native resolution on the target NVIDIA 1050 Ti. No speedup is
claimed over the old cheap 2D rain textures. No new render targets are allocated.

## Visibility regression checks

`python tests/rain_visibility_gpu.py` also renders at map coordinates (7492,1466),
30/45/60-degree cameras, distances 500/1000/1500 and corresponding gameplay pixel
footprints. It requires visible splash coverage rather than merely nonzero
floats, checks blue/orange sky-only lighting, and checks separated runoff channels
on a shallow incline. These are synthetic rendering checks, not an in-game
screenshot or a target-GPU performance measurement.
