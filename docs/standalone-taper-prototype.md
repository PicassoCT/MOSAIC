# Standalone facade emission prototype

Unsynced experiment, **automatically enabled for every visible `house_asian3`
(Project)** on this prototype branch. Based on master `8c6ba642`.

## Try it

Load the prototype branch and wait for the buildings' visible models to finish
appearing. No activation command is needed. For this experiment, facade emission
also runs at full source intensity during daylight; other light sources retain
their normal schedule. Use `/radiancetaper test off` to restore time-of-day scaling.

To inspect a Project, select it and enter:

```text
/radiancetaper debug on
/radiancedebug on
/radiancedebug zoom 1024
```

Compare `/radiancetaper off` and `/radiancetaper auto`. The visible building itself
is never tapered. `/radiancetaper on` still switches to a single selected Arcology
or Project (`house_asian1` / `house_asian3`) for isolated experiments.

The small debug panel shows the **tapered source capture**, not propagated light.
`/radiancedebug on` shows the existing cascade emission/occlusion/result panels.

| Command | Effect |
| --- | --- |
| `/radiancetaper auto` | Restore automatic emission for all visible house_asian3 |
| `/radiancetaper test on/off` | Toggle full-intensity daylight testing for these sources |
| `/radiancetaper on UNITID` | Select a specific visible standalone |
| `/radiancetaper taper 0.18` | Roof contraction, clamped to 0.03–0.40 |
| `/radiancetaper strength 0.15` | Source intensity, 0–8 |
| `/radiancetaper falloff 256` | Height gap giving half intensity, in elmos |
| `/radiancetaper span 1536` | Capture width/depth around the unit origin |
| `/radiancetaper height 1536` | Height above the unit origin at full contraction |
| `/radiancetaper debug off` | Hide the source preview |
| `/radiancetaper off` | Remove this experimental light source |

Automatic bounds include the hidden model variants. If the chosen house is tiny
in the preview, reduce `span` until its footprint fills most of the square, and
set `height` to its approximate roof height. Keep the complete footprint inside
the capture; cut-off surfaces contribute no light. No settings persist on reload.

## Implementation

* The actual visible model pieces are rendered using their current transforms.
  The raw material draw bypasses Lua material/callin recursion.
* Only the offscreen vertex shader contracts X/Z with height. The capture stores
  original world positions, horizontal normals, RGB self-illumination and the
  original surface area represented by each texel.
* Texture 2 red gates self-illumination and alpha gates coverage. Unlit opaque
  surfaces still write depth; roofs occlude windows beneath them. Horizontal roof
  emission is deliberately excluded from this facade experiment.
* A 4×4 texture sampling pattern reduces aliasing of small window rows. Surface
  derivatives compensate for capture compression and capture resolution.
* GPU points splat the samples back beside the original facades, offset outward
  by four elmos plus the splat half-width. This avoids placing their centres at
  the artificially contracted positions inside the house.
* Each source is weighted **before** additive accumulation using
  `1 / (1 + (gap / falloff)^2)`, where `gap` is distance from its original world
  height to the receiver band. This is an artistic 2.5D approximation.
* Both whole-map and camera-local emission textures retain HDR accumulation.
  The existing cascade solve, scene composition and day/night scaling consume it.

Automatic mode discovers eligible units once per second, and captures/splats each
one into the global and local emission atlases at their refresh cadence. All
houses share two 256×256 RGBA32F targets, one depth target, two shader programs and
one fixed point list; memory does not grow with house count. GPU work does grow
with the number of houses. Resources are allocated when the first source is drawn.
Manual single-unit mode retains the once-per-second capture cache.
Missing capabilities or allocation failures disable only the prototype. Unit
death or lost LOS invalidates cached light. Resources are released on shutdown.

## Known limits

This is not a full 3D lighting solution. It cannot see all recessed windows or
surfaces under overhangs. It does not restore a removed voxelization/shader
framework. Standalone houses currently return no building shadow columns;
therefore self-occlusion during **propagation** remains incomplete, even though
occlusion during capture is tested. Other registered building blockers continue
to work through the existing cascade. RGB sources in this cascade do not retain
a full directional emission distribution.

Only the two standalone types listed above are supported. The Luxor Combs use a
different model and are not enabled by this experiment. In-game rendering still
needs visual verification on the target Recoil build/GPU.

## Verification

```text
python3 tests/standalone_taper_gpu.py
lua tests/standalone_taper_lifecycle.lua
lua tests/neon_radiance_lifecycle.lua
python3 tests/objective_emission_gpu.py
```

The GPU fixture runs the production capture/splat GLSL on a synthetic windowed
tower in a Mesa compatibility context: edge-on baseline, extracted windows,
masking, roof depth, unchanged source positions, taper energy stability, outward
injection, height falloff, zero intensity, HDR and global/local energy agreement.
Use `--preview PATH.png` to export the shader fixture. This is not an in-game
screenshot. Lifecycle tests cover activation, reuse, LOS/death, state cleanup and
all allocation-failure paths.
