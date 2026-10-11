# Height-aware mobile radiance shadows

Cars and ground vehicles cast oriented box shadows. Pedestrians cast stretched
ellipsoid shadows. The live collision dimensions, model midpoint, collision
offset, interpolated position, and full unit orientation place each proxy. Unit
membership is centralized in `getMobileRadianceShadowTypeTable` in
`scripts/lib_mosaic.lua`; buildings, aircraft, software icons, and hidden operative
models are excluded. The visible civilian disguise supplies its own shadow.

## Lighting path

The local radiance cascade now retains a representative emitting position in
paired RGBA32F buffers. Mesh emission preserves actual transformed height, even
when an objective source is projected into the active height band. Alpha in the
emission capture stores an additive luminance-weighted source-height moment.
Cascade and resolve select a discrete contributing source when merging samples.

The scene pass reconstructs the actual receiver position from scene depth. It
traces a finite 3D segment from the retained source to that receiver through
oriented boxes or ellipsoids. A ray can pass above a car, intersect its side, or
clear the rounded shoulder of a pedestrian. Receiver height changes the result.
Unshadowed radiance remains available for elevated receivers; ground shadows are
not baked into the reused cascade texture.

Direct headlights, police strobes, fire, and tank muzzle flashes retain the
actual lamp position and owning unit in a separate half of the same source
atlas. A depth comparison selects the brightest contributor, preserving one real
lamp rather than interpolating several lamp positions. Objective floodlights and
searchlights also use the finite mobile intersection test.

When a source lies inside its own simplified proxy, only that owning proxy is
exempted. A lamp outside its car can still cast a shadow backwards across it.
Neighboring units remain blockers. A proxy containing a visible receiver is
omitted for that ray to avoid blackening surfaces inside an approximate collision
shape; this does not clear a surrounding radius.

## Bounds and approximation

- The existing camera-local detail region is 1,024 or 2,048 elmos across, with
  its existing zoom hysteresis. Mobile casters are collected from that region
  plus a 512-elmo margin. Strategic zoom retains the ordinary global lighting.
- At most 128 nearby casters are uploaded. A 32 by 32 grid stores up to 16
  candidate indices per cell. A ray visits at most 65 cells, with early exits
  for empty cells, height clearance, and intersections. Over-budget selection is
  stable and prefers nearer units; diagnostic counters expose dropped entries.
- Visibility, position, and orientation refresh every draw. Spatial discovery
  normally scans every three simulation frames and invalidates on unit/LOS
  callbacks, camera jumps, ally/view changes, and paused-camera movement.
- Moving casters do not invalidate static building occupancy or window bakes.
  No per-unit shadow maps or per-frame texture allocations are introduced.
- Additional fixed texture storage is approximately 18.125 MiB: 8 MiB of local
  cascade source buffers, 8 MiB for the combined source atlas, approximately
  2 MiB for its depth attachment, and 128 KiB for packed caster/grid data. The
  scene uses 16 texture samplers, within the OpenGL 3.x minimum.

Shadow geometry is height-aware; the underlying static radiance transport
remains the existing height-band cascade. A representative source approximates
mixed illumination when several emitters contribute to one field sample.
Overlapping emission capture samples retain a weighted source height. This is
not a full multi-source volumetric radiance solver. The separately cached direct
window-ground projection keeps its current behavior.

## In-game checks

The feature is enabled by default. These commands support comparison and budget
inspection:

```
/radiancelight shadows on
/radiancelight shadows off
/radiancelight shadows stats
```

At a close camera distance, drive a car past a low light and an elevated light,
walk a civilian through a headlight beam, and fire a tank beside another unit.
Check that ground shadows move each draw, elevated receivers clear low blockers,
and rooftop police lights and muzzle flashes remain visible. Cloaked,
transported, unfinished, and removed units must leave no shadow. The existing
`/radiancelight test on` command supplies full-intensity daytime diagnostics.

Automated validation covers the actual GLSL proxy intersections, emission height
capture, paired cascade/resolve outputs, scene receiver heights, exact owner
clearance, visibility, resource lifetimes, and allocation failures. GPU fixtures
use EGL/llvmpipe in this workspace. They are not an in-game or GTX 1050 Ti frame
time measurement; visual tuning and hardware performance require the game.
