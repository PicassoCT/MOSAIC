# Neon radiance collision-volume atlas

Buildings opt into hologram-light occlusion through the shared building base
class:

```lua
customParams = {
    throwsShadow = true,
}
```

`gfx_building_shadow_volumes.lua` snapshots the unit's enabled piece
collision volumes. If no enabled piece volume exists, it falls back to the
unit-level collision volume. The cache is stored in
`GG.BuildingShadowVolume[unitID]`.

The cache is sent to LuaUI only after a structural change. The radiance widget
then rasterizes the primitives into sixteen shared 512x512 world-space slices
covering Y=0 through Y=2048. Normal rendering only samples those textures; it
does not iterate collision volumes.

## Dirty updates

Creation, completion, and destruction are handled automatically. A gadget that
changes a building's structural pieces or collision volumes must call:

```lua
GG.MarkBuildingShadowVolumeDirty(unitID)
```

This rebuilds that unit's cached primitives and then rebuilds the shared atlas
once. It must not be called every frame.

## Current approximation

Box volumes rasterize as rotated rectangles. Ellipsoid and sphere cross
sections shrink toward the top and bottom. Cylinders use an elliptical
cross-section. Piece positions are live, but piece-local rotations are not yet
applied; the unit heading is applied to every primitive.
