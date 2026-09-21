# World-anchored falling rain

Falling precipitation now uses a separate `worldRain.glsl` include. A fullscreen
pass traverses a maximum of 48 world cells using DDA, evaluating two independently seeded finite
analytic streak candidates per cell. It is not a density raymarch or particle
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

## Falling-rain light and final composition

The falling streaks now add reflected light instead of alpha-blending a dark
opaque colour over the scene. Skylight is sampled through the existing atmosphere
uniform, with hue-preserving brightness adjustment; radiance is sampled at actual
streak positions. Two candidates per cell improve sparse foreground coverage
without increasing the 48-step traversal bound. This increases per-cell arithmetic;
no target-hardware speed claim is made. Confirmed splash and ripple sizes remain.

Runoff light now has a separate additive contribution instead of passing through
both a channel mask and wet-layer alpha. Exactly flat normals retain puddles and
vertical normals remain dry. Rivulets are not expected on perfectly flat roofs.

The existing rain canvas uses RGBA16F to preserve highlight RGB above one until
straight-alpha composition. The previous default 8-bit canvas could clip those
values before blending, hiding small highlights on bright surfaces. This uses
four additional bytes per pixel for that target (about 8 MiB extra at 1080p),
without adding a render pass or a second target.

During rain, use `/rainview rain` to isolate only the fullscreen falling-rain
light on black (4x display gain), `/rainview runoff` to show the actual runoff
coverage, and `/rainview normals` to inspect selected terrain/unit normals.
`/rainview off` restores normal rendering. These default to off and do not change
weather. Hologram-piece rain is not generated by these diagnostic shader outputs;
bright hologram particles in a normal screenshot are not proof of rain lighting.

`python tests/rain_composite_gpu.py` renders the actual falling-rain helper with
sky-only blue/orange illumination and radiance-only green illumination. It also
renders final composition into an RGBA16F target, then checks the straight-alpha
result against bright/dark backgrounds, preserving surface blending and applying
weather once. This complements mask tests; in-game confirmation remains necessary.

## Surface-water art pass (2026-09-20)

The active surface path now replaces the old screen-derivative grey ripple sheen
with explicit expanding ring crests and neighbouring dark troughs. Nine seeded
impact cells supply the rings; phase matches splashback and maximum radius stays
within the approved 8/9-unit scale. Pixel filtering fades unresolved rings rather
than enlarging them with zoom.

A world-anchored, smoothly varying puddle mask controls wet darkening and existing
screen-space reflections. The uniform blue/grey surface veil and image-derived
sheen are no longer used in this path. Ring and runoff highlights receive both
atmosphere and radiance, with bounded, hue-preserving exposure for day/night.

Runoff uses the full 3D downhill tangent (including height). Dark channels with
travelling bright beads supply contrast on bright roofs as well as at night.
Wetness now fades across normal Y 0.25–0.8, allowing steep sloped roofs while
keeping vertical walls dry; flat normals still use puddles. Runoff remains a
surface effect, not a projected overlay from other buildings.

Falling streaks are thinner with tapered ends and compressed highlight intensity.
Splash size, positions and density remain unchanged; splash brightness is reduced
to avoid white confetti competing with small rings. These are artistic changes
towards the concept preview, not a claim to reproduce its architecture/materials.

Run `python tests/rain_surface_art_gpu.py` for rendered day/night, flat/shallow/
steep-surface contrast and animation tests without radiance. Optional `--preview`
writes enlarged synthetic shader samples under /tmp for inspection. The existing
visibility and final-composition suites remain applicable. In-game review of
materials, reflection artefacts and target-hardware performance is still required.

## Geometry-driven drainage and softer ripple relief (2026-09-20)

This revision supersedes the outlined-ring treatment above. Ripples retain their
impact seeds, ages and sizes, but use an analytic Gaussian ridge gradient to
perturb the water normal. Directional highlights and opposing dark faces replace
uniform crest emission and the dark outlined trough. Pixel filtering attenuates
unresolved slopes. Falling-rain and splash helper files are unchanged.

The stock Recoil [map shader](https://github.com/beyond-all-reason/RecoilEngine/blob/master/cont/base/springcontent/shaders/GLSL/SMFFragProg.glsl)
and [model shader](https://github.com/beyond-all-reason/RecoilEngine/blob/master/cont/base/springcontent/shaders/GLSL/ModelFragProgGL4.glsl)
encode world normals in RGB with the same signed-to-unsigned mapping. These are
shading normals, however, and can contain texture perturbations or interpolated
model normals. They are not a reliable drainage slope. This does not establish
which custom material caused the reported in-game mismatch.

For the visible surface, reconstruct geometry from its selected map/model depth
buffer. Choose the shorter valid tangent on each screen axis to avoid bridging
roof silhouettes; orient the cross product toward the camera. Flat roofs and
flat ground now use the same geometry-based puddle classification, independent
of material normal detail. Missing/degenerate depth retains the previous decoded
normal as a fallback. Normal alpha remains irrelevant to surface eligibility.
The normals diagnostic now displays the reconstructed geometry normal.

Runoff uses elongated, warped Voronoi UV cells in the surface downhill/across
basis. Cell boundaries provide varied channel widths, forks and junctions;
travelling pulses move downhill through this stationary pattern. This is a
procedural local surface effect, not a hydraulic simulation or tracked flow
between meshes. Rapidly varying geometry normals can still change the local
pattern orientation. The wetness fade extends to normal Y 0.05–0.65 so steep
exposed banks can carry runoff; exactly flat surfaces remain puddled and vertical
walls remain dry.

`python tests/rain_geometry_gpu.py` renders both depth conventions and both
perspective/orthographic cameras, deliberately wrong shading normals, identical
map/model planes, flat roofs, shallow/steep banks, silhouette boundaries and the
missing-depth fallback. The surface-art test checks bounded ring contrast,
day/night animation and reversal of ripple light/dark faces with light direction.
These are production GLSL tests on synthetic buffers, not screenshots of the
running game. Engine appearance and GPU cost still require in-game review; the
geometry reconstruction adds four neighboring depth samples per visible pixel.

## Runoff material split and footprint correction (2026-09-20)

Terrain now retains Voronoi runoff while selected model surfaces use mostly
straight, gently wandering lanes. Both runoff patterns use twice the spatial
frequency (half the former world-space size). Pond ripple code is unchanged.

Runoff pixel filtering now projects world-position derivatives into a fixed local
surface frame. Differentiating the entire position/normal dot product previously
introduced a position-times-normal-derivative term, which could falsely classify
channels as unresolved on curved or depth-quantized surfaces far from the origin.
This is a plausible contributor to the reported compass-dependent disappearance;
confirmation of the particular in-game banks still requires an engine capture.

`python tests/rain_runoff_gpu.py` checks matching coverage/patterns on four rotated
slopes, distinct building/terrain patterns and retained coverage with varying
normals at large map coordinates. Geometry, surface-art and visibility regression
suites also pass. The patterns remain procedural local flow, not a simulation.

## Additional roof droplets (2026-09-20)

Added sparse rounded beads and short wet wakes alongside the existing building
rivulets. Beads briefly gather, then accelerate downhill and fade before their
cycle resets. World-space tangent coordinates align bead centres with the roof
lanes. Analytic cap gradients provide curved highlights and dark faces using the
existing sky/sun/radiance lighting. Pixel filtering attenuates unresolved beads.
Terrain, flat puddles and vertical walls are excluded by the building/runoff mask;
existing rivulets and pond ripple functions are unchanged.

Visual reference: Martijn Steinrucken (BigWings), Heartfelt (2017),
https://www.shadertoy.com/view/ltffzl. This is a new analytic ellipsoidal-cap
implementation; no code from the supplied CC BY-NC-SA glass shader was copied.
It does not include that shader's screen-wide refraction, fog, heart or lightning.

`python tests/rain_roof_beads_gpu.py` verifies rounded gradients, sparse animated
coverage in four directions, and rejection on terrain/flat/vertical surfaces.
The surface-art regression also passes. Actual game appearance/performance remains
to be checked; this adds a nine-cell procedural evaluation on runoff roofs.

## Curved-surface projection repair (2026-09-20)

The earlier pixel-footprint correction did not fix the pattern coordinates
themselves. Dotting world position with a normal-dependent tangent is not a
valid general UV parameterization: on a sphere centred at the origin, both
coordinates collapse to zero. A translated sphere also develops severe distortion.
A fixed-camera dome regression reproduces this failure in commit 54b042f; the old
rotated-plane tests alone could not detect it.

Runoff and roof droplets now share fixed vertical world projections, selecting
XZ-facing charts by the dominant horizontal normal component. Across coordinates
stay fixed within each chart; the along coordinate uses negative world height,
so motion descends on every slope orientation. This avoids continuously rotating
pattern coordinates. There may be a seam where the dominant chart changes, and
features stretch on very shallow slopes; this is still procedural surface flow.

Runoff frequency is doubled again to make finer channels. Roof bead radii are
about 2.2–2.3 times larger, with proportional cap height and a wider pixel-filter
visibility range. Beads align to the finer building lanes. Pond ripple shading,
size and timing are unchanged.

The new dome test checks eight azimuth sectors from a fixed camera for both
terrain and building patterns. It fails with the previous shader and passes with
this repair. Roof bead, runoff and surface-art tests also pass. In-game appearance
and the specific reported orientation problem still need confirmation.

## Continuous channel lighting and bead visibility (2026-09-20)

Removed the effective fourth-power runoff brightness response that turned mild
flow modulation into bright dashes and almost-dark gaps. Channels retain a steady
lit contribution, with 8% shape modulation and a small additional lighting change.
World-anchored channel hashes vary pulse speed, wavelength and phase. They no
longer all share the same clock frequency. This is a lit-water approximation,
not a new reflection ray-tracing pass.

Roof beads retain their size but fade over 2–5 world units per pixel instead of
0.6–1.8. Their rounded shading now includes a broad lit response and a subtle dark
body, so visibility does not depend entirely on a narrow directional glint.
Existing building rivulets and terrain channels remain distinct; pond ripples
and falling rain are unchanged.

During rain, `/rainview scale` displays a checkerboard with four engine units per
square along the selected world projection axes: cyan models, orange terrain.
Squares can stretch along sloped surfaces because these are projected lengths,
not geodesic surface distances. `/rainview beads` displays roof bead/wake coverage
at 4x gain. `/rainview off` restores rendering. Both new views default to off and
use the current weather; they do not force rain.

Tests check continuous runoff coverage through a cycle, roof bead coverage at
0.6/1.2/2.0 units per pixel, and actual final surface composition with versus
without beads on bright/dark backgrounds. Curved-surface and material tests pass.
These synthetic GPU checks cannot establish a match to the concept render or
replace in-game review.

## Variable widths and transparent water highlights (2026-09-20)

Building lane widths now use deterministic channel seeds (0.45–1.8 width factor)
and smooth local variation along each lane. Terrain Voronoi boundary widths use
smooth world-anchored noise instead of a regular sinusoidal width. The continuous
lit baseline and independently timed gentle swells remain.

Splashback has a weaker body contribution and a stronger edge response from an
approximate rounded water cross-section. Alpha contribution is reduced and capped
at 0.22 instead of 0.45, while edge highlights retain their former peak lighting
factor. The compositor already preserves the background additively, so reduced
body light, not alpha alone, supplies the less opaque appearance. Splash geometry,
size, timing and source occlusion are unchanged.

Foreground rain adds rounded cross-section normals, directional highlights and a
Schlick air/water Fresnel approximation (F0=0.02). This treatment is strongest
within 80 world units and fades to the established streak lighting by 240 units.
It uses the existing sky/sun/radiance illumination; it is not environment-map
reflection or physically traced refraction. Distant precipitation keeps its prior
appearance, and pond ripple code is unchanged.

Production GPU suites pass for final half-float composition, near-rain lighting
hues, splash source/foreground occlusion and visibility, and runoff temporal and
curved-surface behavior. In-game review is still needed for the artistic balance.

## Separate runoff scales and staged impacts (2026-09-20)

Building runoff coordinates now use scale 8 (previously 4), halving lane spacing,
width and longitudinal detail. Terrain uses scale 1, restoring channels four times
larger than the previous fine network. The Voronoi boundary orientation suppresses
cross-slope links; a persistent 72% baseline supports independently timed travelling
swells up to 100%. Building swells retain their gentler 92–100% range. This is a
procedural downhill approximation, not a connected hydraulic simulation; dominant
projection seams remain possible.

Roof beads have 1.6x larger radii, wider independent spacing, stronger cap normals,
and slower independently seeded cycles. They grow for 55% of the cycle before
accelerating downhill. Bead size is independent of building channel scale.

Each splash event now has a bright impact core fading out by 85ms, a brief column
that separates into a central ballistic bead at 110ms, and five smaller outward
spray droplets. All share the ripple impact seed. The transparent body/rim shading
and source/foreground rejection remain; falling rain and pond ripples are unchanged.
The bounded gather now evaluates seven primitives per live impact instead of three;
in-game performance and artistic balance still need checking.

GPU validation covers sparse bead normals and gameplay footprints, final day/night
bead composition, splash depth rejection, curved runoff in eight azimuth sectors,
continuous wet channels, and final additive composition. The terrain dome test
samples a four-times larger world patch to accommodate the restored channel size.
A 24-frame synthetic splash render was inspected as a contact sheet (5x display
gain); it is not an in-game preview or evidence of a photographic match.

## Bead collection and relief shading (2026-09-20)

Building runoff replaces persistent lanes with seeded bead-and-wake events.
Beads grow in place; a larger head advances in three downhill bursts separated by
rests, clears the beads it passes, and leaves a short meandering wake that fades.
The head grows with travel to suggest collection. This is analytic visual
collection, not conserved water mass or a history buffer. Timing and path offsets
vary by event. Two fixed world charts crossfade over changing roof normals; both
advance along negative world Y, avoiding an abrupt dominant-axis switch.

Beads and wakes use rounded cap gradients, the ripple lighting scale, and opposing
highlight/shadow faces. Terrain channels also perturb the normal. Removed the
uniform additive channel/bead colour which made runoff look like painted stripes.
Terrain paths retain the previous Voronoi layout; this change addresses their
shading, not a new hydraulic path solver. Runoff and building beads are clipped at
world Y=0 (the engine sea plane), including the terrain gradient contribution.
Pond ripple profiles, falling rain and splashback are unchanged.

Validation: production shader compile/link; composition and lighting tests;
bead coverage at gameplay footprints; monotone paused downhill travel; building
coverage in all eight dome sectors over time; submerged terrain/building rejection.
A 32-frame synthetic shaded roof sequence was inspected as a contact sheet at
normal display gain. In-game direction, performance and visual balance still need
review. The paired chart evaluations increase building-water shader work.

## Smaller beads, sparse fixed streams and bank water film (2026-09-20)

Building bead/temporary-wake coordinates are 2.5x denser: diameters and lengths are
40% of the previous version, with 6.25x as many clusters per chart area. Their
rounded shading and stop/go collection remain. A separate thin stationary stream
layer uses one jittered candidate per visual metre, accepted by a deterministic
rain threshold. At rain=0.25, expected spacing is four metres; at rain=1, one metre.
Positions are stable as rain changes and contain no time-dependent animation.

Art calibration is explicit: RAIN_UNITS_PER_METRE=4, one debug checker square.
This is a visual convention, not a verified model-to-SI conversion. Spacing is
measured across projected charts; diagonal blends and slopes affect apparent
surface spacing. Statistical density testing over 4096 candidates gives 25.1%
activation at quarter rain. A separate GPU test verifies time-independent shapes.

Removed terrain Voronoi completely. Exposed terrain slopes now use two smoothly
blended world projections of advected, warped noise to make a continuous flowing
water film. Coarse/fine detail perturbs normals and creates moving lit highlights.
The existing compositor blends the effect with rain strength once. Sea-level
clipping remains. This replaces bank runoff, not the engine's ocean renderer or
pond ripple profile. Falling rain and splashback are unchanged.

GPU validation passes for density/static streams, smaller bead visibility at
camera footprints, bright/dark film composition, terrain orientations, submerged
rejection and additive rain composition. The film contrast test now checks softer
continuous detail instead of the previous discrete-channel contrast threshold.
Synthetic shaded terrain was inspected; game-scale appearance still needs review.

## Rain progression refinement (September 21)

Building stationary and moving bead radii are halved again without rescaling
cluster positions or rivulet widths. Temporary runoff activates by stable seeded
rain thresholds, leaving more resting beads at light rain. Fixed stream density
retains the calibrated linear rule (0.1 through 1.0 streams/visual metre).

Terrain film now contains softly filtered, elongated Voronoi ridges, continuously
advected downhill inside the existing noise film. Both world projections blend
smoothly and use the building/ripple normal-lighting treatment. The film fades
across 1.5 engine units above sea level and is absent below water. This supersedes
the preceding noise-only terrain treatment; ocean rendering remains independent.

A cheap three-sheet angular distant-rain layer supplements world-space rain at
900/1350/1800 units, clipped by scene depth and the rain-height slab. It is an
approximate 2D atmosphere effect, not world-anchored particles. Visibility scales
once with rainPercent in the compositor. Near rain and splashback are unchanged.

Validation: production GLSL compile/link and GPU suites for beads, fixed streams,
terrain directions, surface lighting, composition, distant depth/animation and
rain values 0.0–1.0. Rain-distance checks allow 8-bit readback quantization.
The ten-panel generated concept sheet is an artistic target, not a GPU result
or an engine capture. In-game scale, performance and appearance need review.
