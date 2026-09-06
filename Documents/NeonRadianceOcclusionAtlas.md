# Neon radiance occlusion atlases

Buildings can provide a coarse vertical occupancy model for neon-light
raymarching. The LuaUI radiance widget composites those building-local assets
into sixteen shared world-space slices whenever the building set changes.

## UnitDef contract

Add these values to the building's `customParams`:

```lua
radianceOcclusionAtlas   = "unittextures/occlusion/house_arab_01.png",
radianceOcclusionLayers  = 16,
radianceOcclusionColumns = 4,
radianceOcclusionRows    = 4,
radianceOcclusionHeight  = 720,
radianceOcclusionSizeX   = 480,
radianceOcclusionSizeZ   = 360,
```

`Height`, `SizeX`, and `SizeZ` are in world units. The atlas dimensions
describe the building-local X/Z rectangle represented by every tile.

## Texture layout

The default asset is a 4x4 tile sheet containing sixteen bottom-to-top
occupancy slices. Layer zero is the lower-left tile in OpenGL texture
coordinates. Layers advance left-to-right, then bottom-to-top.

Pixels representing solid structure must be opaque. Empty space must have
alpha below 0.5. RGB should be white so the debug view is readable.

The tiles must use hard edges and padding should be avoided: the compositor
uses nearest filtering and exact tile UVs.

## Runtime behavior

- Only units declaring `radianceOcclusionAtlas` participate.
- Position and heading come from the live unit.
- The shared atlas rebuilds on creation, destruction, giving, or taking.
- Sixteen 512x512 world slices cover Y=0 through Y=2048.
- The diagnostic view currently displays slice 4 at Y=448.

Animated structural changes are not tracked yet. A later building-to-widget
dirty notification can rebuild the cache after doors, walls, or major pieces
change.
