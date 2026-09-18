# Rain and local light glitter

Headlights now break up their wet-road specular highlights with small world-fixed
facets and a slow ripple modulation. Both lamps reuse one computed wet normal.
The effect remains inside the beam and its existing building visibility mask,
applies only to upward-facing wet surfaces, and fades subpixel detail with zoom.
Dry-road diffuse lighting is unchanged.

Rain highlights borrow the current radiance scene field and its occupancy atlas.
Droplet texture coverage selects the glints; neon colour and brightness come from
the local light field. Two approximate drop depths in front of the visible
surface provide variation without tracing a volume. Samples outside the active
height band/map or inside an occupied building are rejected. Night intensity is
applied once. The camera-local radiance field is preferred inside its central
region; the whole-map field is used outside that region.

Cost of this change:

- No additional passes, render targets, scene copies, light lists or ray marches.
- Headlights: procedural arithmetic once per lit surface pixel, shared by both
  lamps; no new texture fetches. Existing 48-vehicle surface-light limit remains.
- Rain: at most four extra texture fetches (radiance + occupancy for two drop
  layers), only when the field is active and droplet coverage passes the mask.
  Texture units 10–13 are borrowed and unbound after drawing.
- Dry weather skips both rain rendering and compositing, avoiding stale output
  and the existing scene copies/reflection work when there is no rain.

No Recoil model shader framework or engine settings are enabled.

## Check in game

Use a rainy night beside neon signage with traffic passing through. Look across
the wet road toward the cars for warm glitter, then rotate/zoom to check that the
fine sparkle settles down at a distance. Near lit buildings, drop highlights
should pick up their local neon colours, rather than tinting the entire screen.
`/rainglitter off` and `/rainglitter on` toggle the neon drop enhancement for an
A/B comparison; headlights remain active. Test dawn/dusk and disabling/reloading
the radiance widget. `/rainreflection on` is reflection-only debugging and does
not display drop glitter.

These are economical approximations: the radiance field is a 2D height band,
not a full directional volume, and drop depths are representative rather than
simulated particles. Wet facets are procedural, without asphalt material maps.
The existing rain reflection implementation and its limitations remain.

Validation: production GLSL compilation and numerical GPU tests on Mesa
llvmpipe; rain colour, animation, drop mask, night scaling, occupancy, height/map
bounds, local-field fallback and binding lifecycle; existing headlight shader
and lifecycle tests including animated wet highlights. In-game appearance and
hardware frame-time comparison are still required; no FPS claim is made.

Run from the repository root:

- `MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/rain_light_glitter_gpu.py`
- `MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/vehicle_headlights_gpu.py`
- `lua tests/rain_light_glitter_lifecycle.lua`
- `lua tests/vehicle_headlights_lifecycle.lua`
