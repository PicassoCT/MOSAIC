# Vehicle headlights

The Night widget now uses two dipped spotlights per moving vehicle type, soft
horizontal falloff, warm lamp cores and depth-tested additive bulb halos. The
old polygon cones are retained only as a shader-initialization fallback. The
existing `night_setsearchlight`, `night_basetype` and `night_beam` actions still
control intensity, surface illumination and bulb halos respectively.

This is direct lighting inspired by the spotlight discussion in
https://www.adriancourreges.com/blog/2015/11/02/gta-v-graphics-study-part-2/ .
It reconstructs visible surfaces from one shared scene-depth copy each frame.
It does not enable engine settings or restore the Recoil model shader framework.
Shaders live separately in `shaders/headlights/`.

The existing radiance widget exposes a read-only building-occupancy texture for
beam blocking. Moving spotlights are not injected into the slow neon propagation
pass: their direction and location update every rendered frame. The rain widget
supplies its actual rain amount for a restrained view-dependent road highlight.
Both integrations are optional and cleaned up on widget shutdown.

## In-game check

- At night, examine each `truck_arab0` through `truck_arab8`, and `truck_western0`
  through `truck_western3`, driving and turning, near and far.
- Use `/headlights test on` for daytime positioning checks; restore with
  `/headlights test off`.
- Confirm two lamp glows at the front, smooth road pools ahead, no old cone,
  and no lights on transported, unfinished or cloaked vehicles.
- Park facing a completed voxel-registered building. Its occupied height band
  should block the beam. Try disabling the radiance widget and reloading LuaUI.
- Check dry and rainy nights, dawn (06:00–07:00), dusk (17:00–18:00), camera
  rotations, window resize, and a dense traffic scene.

## Placement and performance

Defaults use the collision-volume dimensions, not the model bounding radius
(which may include decorative light meshes). Optional unit custom parameters:

| Parameter | Default | Meaning |
| --- | --- | --- |
| `headlight_forward` | 0.48 × collision length | Forward offset from collision-offset origin, elmos |
| `headlight_height` | 0.32 × collision height | Upward offset from collision-offset origin, elmos |
| `headlight_spacing` | 0.32 × collision width | Half the distance between lamps, elmos |
| `headlight_range` | 3.5 × collision length | Beam reach, clamped to 100–360 elmos |
| `headlight_left_piece` | `headlight_left` | Optional exact left lamp anchor |
| `headlight_right_piece` | `headlight_right` | Optional exact right lamp anchor |

Named anchors track piece animation. Model-specific lamp placement still needs
in-game checking; the headless tests do not load the DAE models.

Only the nearest 48 visible vehicles receive surface illumination, with
conservative screen bounds per draw. All eligible visible vehicles retain bulb
glows. A single depth texture is capped at 16 MiB (4 million pixels); larger
viewports or allocation failure retain glows only. No textures are allocated
when there are no active headlights.

The occlusion atlas is coarse and conservative, and checks only the source's
height band. This is not per-headlight shadow mapping: vehicles, terrain and
unregistered buildings do not cast beam shadows. Depth testing still keeps
lamp halos behind visible geometry. Depth-derived normals lack detailed road
material data, so wet highlights are an approximation. No volumetric air beams
or radiance bounce have been added.

## Automated validation

- `tests/vehicle_headlights_lifecycle.lua`: visibility, construction, daytime,
  lamp height, 48-car cap, one depth copy, resize and failed-allocation recovery,
  cleanup and legacy shader fallback. Run from repository root with Lua.
- `MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/vehicle_headlights_gpu.py`:
  production GLSL compilation and offscreen numerical rendering; directional
  road light, finite range, fade, wall blocking, missing-atlas fallback,
  wetness, both depth conventions and sky rejection. Requires numpy, moderngl
  and Mesa EGL. Tested on llvmpipe; in-game GPU/visual validation is outstanding.
