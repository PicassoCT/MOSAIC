# Headlight cones in radiance cascades

**Update:** [HeadlightLiveMotion.md](HeadlightLiveMotion.md) supersedes the
refresh, memory and direct-light composition details below. This document
records the initial working 5 Hz cone integration.

This corrects the earlier independent screen-space implementation. The Night
widget now supplies paired cone footprints as geometry to the existing neon
emission capture. Soft cone intensity is written into the same atlas as hologram
pieces. Both whole-map and camera-local captures invoke the provider, and the
existing cascade/scene passes propagate and display that emission. Rain's
radiance sampling therefore also sees the warm vehicle light.

A cone must be clipped before emission: simply stamping its entire footprint
would create independent sources behind walls. The emission fragment shader
checks the source-to-fragment segment against the building occupancy atlas.
After that clipping, the existing radiance propagation handles light spread.

When radiance scene output is ready, the separate headlight surface pass and its
scene-depth copy are suppressed. Lamp glows remain. The earlier standalone
spotlight path remains a fallback when the radiance widget is absent/disabled.
Its procedural wet specular is likewise confined to that fallback; the active
cascade path uses the common radiance/rain scene rendering.

No extra FBO, cascade level or full-screen pass is added. At most 48 visible
vehicles emit two quads each per capture. Whole-map and close-up captures share
a vehicle snapshot for each draw frame. Occlusion tracing is capped at 96 atlas
samples and normally uses twice the number of crossed cells. The existing
0.20-second atlas refresh interval is unchanged, so fast vehicles may show some
lighting lag. All emission is cleared and redrawn each capture.

Limitations: these are projected cone footprints, not volumetric air beams.
Vehicle dimensions still supply default lamp positions; named piece anchors
remain supported. The configured radiance height band and coarse building
occupancy still limit terrain/bridge and fine-shadow accuracy. These changes
have not been visually verified in Recoil.

## Check

At night, park a civilian car facing a completed voxel-registered building.
Check road illumination, blockage at the building, turning, moving traffic and
near/far camera views. The cone should also be visible in the radiance emission
preview (`/radiancedebug on`); turn it off with `/radiancedebug off`.
For daytime inspection use `/radiancelight test on`, then restore with
`/radiancelight test off`. `/headlights test on` alone forces only the lamp and
standalone-fallback view, not the shared radiance night multiplier.

Validation:

- `MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/headlight_cone_emission_gpu.py`
  tests production cone shaders with the radiance capture matrices: world/local
  domains, rotation, soft falloff, range, disabled source and pre-emission wall
  clipping.
- `lua tests/headlight_cone_lifecycle.lua` checks capture sharing, layer/cloak/
  disable rejection, fallback suppression and provider cleanup.
