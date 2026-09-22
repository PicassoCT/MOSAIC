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
No existing unit is automatically assigned an emitter by this change.

## Cost and rendering limits

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
MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/smoke_ribbons_gpu.py
```

The GPU test requires `moderngl` and `numpy`; it compiles and renders the actual
GLSL in EGL. `--preview /absolute/path.png` additionally requires Pillow.
Lifecycle tests cover API validation, copying, reload, visibility, anchor draw
offsets, direction modes, simulation clock, local preview and resource cleanup.
They also check size-dependent distance cutoffs, fading and re-entry into range.
The tests do not replace an in-game check on Recoil and the target GPU.
