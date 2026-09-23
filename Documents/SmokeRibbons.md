# Procedural smoke ribbons

A narrow plume grows from a model emitter, rolls into irregular coils, widens,
and dissolves into translucent strands. The vertex shader evaluates advecting
vortex paths; the fragment shader adds soft density variation and folded wisps.
This approximates particle-brush smoke without storing or stepping particles.
It is an attached effect: already-drawn smoke follows the emitter when it moves.
It is not a world-space wake or a fluid simulation.

## Use from a unit script or synced gadget

The enabled `gfx_smoke_ribbons.lua` gadget provides `GG.SmokeRibbon`.
No include or polling thread is required. Call once when emission starts, again
when settings change, and disable/remove when it stops.

```lua
-- smokeEmitter must be a real piece handle from this unit's model.
local ok, err = GG.SmokeRibbon.Set(unitID, "exhaust", smokeEmitter, {
    direction = {0, 1, 0},          -- normalised internally
    directionSpace = "world",
    scale = 1,
    length = 60,                   -- engine world units, multiplied by scale
    width = 9,                     -- transverse size, multiplied by scale
    curl = 0.8,
    speed = 1,
    distanceFactor = 40,           -- cutoff = factor * max(length, 2*width) * scale
    windAffected = true,          -- default: on
    motionAffected = false,       -- default: off; turn on to trail behind movement
    windInfluence = 0.3,
    motionInfluence = 1,
    trailTime = 0.7,               -- response scale in simulation seconds
    colorStart = {0.65, 0.68, 0.72, 0.5}, -- RGBA at emitter
    colorEnd = {0.4, 0.43, 0.48, 0},      -- RGBA at far end
    emission = {0, 0},             -- illumination at emitter / far end
    strands = 3,
})
if not ok then Spring.Echo(err) end

GG.SmokeRibbon.SetEnabled(unitID, "exhaust", false)
GG.SmokeRibbon.SetEnabled(unitID, "exhaust", true)
GG.SmokeRibbon.Remove(unitID, "exhaust")
```

`Set` replaces the complete configuration in that unit's named slot; omitted
fields get defaults. Multiple slots can use one piece. Piece names also work.
Invalid unit/piece/direction/nonfinite values return `false, error`. The options
are copied, so later changes to the caller's tables do not modify the effect.

`directionSpace` accepts `world`, `unit` (right/up/front coordinates), or
`emitter` (use the engine's piece emission direction; `direction` is ignored).
An empty emitter piece is valid. Hidden pieces can intentionally keep emitting:
pair your script's Hide/Show or activation logic with `SetEnabled` if desired.

`speed = 0` freezes the procedural animation while the anchor continues to
follow the piece. Positive speed uses interpolated simulation time, so game
pause and game-speed changes are respected. Changing speed changes phase.
`seed` is optional; otherwise it is derived from unit and piece IDs.

Colour and illumination gradients run from emitter to tail independently.
Illumination 0 uses the engine unit ambient colour, 1 is fully self-lit, and
values above 1 increase brightness (maximum 8). Self-illumination affects the
ribbon itself; it does not register light in the radiance-cascade pipeline.
Alpha is also multiplied by a soft source/tail fade. The strip begins exactly
at the emitter; its width and density ease in over the first few percent.

## Try it in game

Select a unit and enter `/smokeribbon PIECE_NAME`, substituting a real piece
name (or numeric piece index). `/smokeribbon PIECE_NAME glow` previews pink
luminous wisps; `/smokeribbon PIECE_NAME steam` previews broad white steam.
`/smokeribbon off` removes the local preview. No cheat mode or synced changes
are required. The preview obeys the same visibility rules as registered effects.

## Wind, movement and the propagator cigarette

Wind is enabled by default. Set `windAffected=false` for sheltered effects.
Set `motionAffected=true` to bend the plume behind the unit's current velocity.
The two influences combine in world space after resolving the base direction:

`tailOffset = (windVector * windInfluence - velocityPerSecond * motionInfluence) * trailTime`

The shader applies this offset gradually as `age²`, keeping the emitter attached
and the initial direction intact. Unit velocity is converted from engine units
per frame to units per simulation second. The wind vector uses engine wind
strength units, with `windInfluence` providing the visual conversion. Tail offset
is capped at twice the plume length to bound geometry and overdraw. Frustum
bounds include that offset; the configured distance cutoff remains size-based.
Wind is sampled at most once per draw and velocity once per emitting unit,
only after distance culling. Zero strengths or `trailTime=0` remove the influence.

This is a current-velocity directional approximation, not stored smoke history:
the bend changes when the unit stops or turns, and teleporting moves the entire
plume. `speed=0` freezes the procedural curls but does not freeze attachment,
wind or motion response.

The propagator now emits subtle grey smoke from the currently shown cigarette
(`HeadDeco5` or one of the `Cig` burn-stage pieces), replacing its old head-centred
smoke bursts. Both wind and movement response are enabled for this preset.
Its 18-unit length gives a default 720-unit draw cutoff. The existing Show/Hide
and icon-mode events manage the effect without a new polling thread. Death
removes it and prevents the animation from registering it again. Cloaking also
suppresses drawing through the renderer's visibility filter. The investigator,
which shares this unit script, retains its previous CEG behaviour.

## Cost and rendering limits

### Objective flames

`scripts/lib_objective_ribbon_flames.lua` holds three animation-driven presets:

| Objective | Anchor | Active period | Length / width |
| --- | --- | --- | --- |
| Pump station | `Flame1` | Reignition through burning; stops at flame-out or forced collapse | 120 / 20 |
| Industrial complex | `Lava` in the melting pot | Pouring/melting phase; stops when the lava finishes lowering | 85 / 16 |
| Spaceport ship | `RocketFusionPlume`, a child of the moving main stage | Launch ignition until `HideRocket()` | 320 / 42 |

Each objective uses one slot, so repeated cycles replace rather than accumulate
emitters. Death removes the effect and blocks restart during the death animation.
The industrial flame follows the molten surface; this model has no dedicated
flare-stack piece. Pump and furnace flames rise with warm self-lit gradients;
the ship exhaust points downward, with a pale blue base fading through orange.
Wind is enabled for all three, with reduced influence on the rocket jet.
Unit-motion trailing is disabled: the spaceship is an animated model piece of
the stationary spaceport, and the plume follows that piece directly.
Existing mesh effects and their radiance registrations remain in place; the
new ribbons are self-lit but do not themselves inject radiance-cascade light.
Sizes are initial world-unit presets and still need in-game visual validation.

### Rendering budget

- Size-dependent distance culling: the default cutoff is 40 times the larger
  of scaled length and twice scaled width, measured from camera to emitter.
  A default 60-unit plume disappears at 2400 units; half scale disappears at
  1200, double scale at 4800. `distanceFactor` accepts 1–200.
  Opacity smoothly fades over the last 20% of that distance, including luminous
  wisps. Beyond the cutoff there is no direction calculation, frustum test,
  sort entry, uniform upload or draw for that plume. Anchor/visibility queries
  still run so moving emitters can re-enter range immediately.
- Default: three strips of 48 segments, 288 triangles per visible emitter.
  Far plumes use 24 segments; `strands` accepts 1–4.
- Mesh display lists are cached once. No per-particle Lua work, texture assets,
  framebuffer captures, ray marching, compute passes, or simulation buffers.
- Draws at most the nearest 128 visible emitters. Each strip is a draw inside a
  shared display list; this is not an instanced single-draw renderer.
- Pixel cost depends on smoke screen coverage and overlapping emitters; the
  fragment shader evaluates two small value-noise samples. No measured in-game
  frame-time or target-GPU performance claim is made.
- Plumes are sorted by centre, far to near, with premultiplied alpha, depth
  testing and no depth writes. Intersecting transparent strips can still show
  sorting artifacts. Surfaces cut the ribbon sharply; there is no soft-depth
  intersection pass. Viewing down the axis remains a ribbon approximation.
- Camera-facing width follows the local curve tangent. A fallback prevents
  undefined normalisation when the camera and tangent align.
- No drawing for radar-only, cloaked, transported, iconified or no-draw units.
  Full-view spectators bypass only LOS filtering. Plume bounds, rather than
  emitter location alone, determine camera-frustum culling.
- Live piece coordinates plus the unit's draw-position offset track moving
  anchors each draw. This does not reconstruct subframe piece rotations.
- Registry updates are event-driven, and an unsynced reload recovers the
  current registry. Unit destruction removes all of that unit's slots.

## Verification

From the repository root:

```sh
lua tests/smoke_ribbons_lifecycle.lua
lua tests/smoke_cigarette_lifecycle.lua
lua tests/objective_ribbon_flames_lifecycle.lua
MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/smoke_ribbons_gpu.py
```

The GPU test requires `moderngl` and `numpy`; it compiles and renders the actual
GLSL in EGL. `--preview /absolute/path.png` additionally requires Pillow.
Lifecycle tests cover API validation, copying, reload, visibility, anchor draw
offsets, direction modes, simulation clock, local preview and resource cleanup.
They also check size-dependent distance cutoffs, fading and re-entry into range.
The tests do not replace an in-game check on Recoil and the target GPU.

## Aerosol drones

All four aerosol drones use the hidden `emitor` piece for downward ribbons in
place of their spray CEGs. Blue Depressol, pink Tollwutox, orange Orgyanyl and
green Wanderlost retain their colour identities. The existing airborne/tank
condition controls registration and removal; chemical effects and consumption
are unchanged. Death removes the plume.

`groundDirected = true` forces world-down emission and fits length to terrain
(or water at zero height). Wind and motion bend it horizontally; vertical drift
is suppressed. The renderer samples terrain under the emitter for size culling
and at the displaced tail for its final length. This requires no synced height
updates. The ribbon fades toward the surface; it does not collide with buildings
or simulate pooling or terrain-following smoke on steep slopes. Width is 22,
with three strands, zero self-illumination and the usual size-based cutoff.
