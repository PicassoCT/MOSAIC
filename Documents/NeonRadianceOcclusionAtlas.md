# Neon radiance DAE voxel atlas

Buildings opt into hologram-light occlusion through the shared building base
class:

```lua
customParams = {
    throwsShadow = true,
}
```

The occluder is no longer inferred from collision volumes.
`gfx_building_shadow_volumes.lua` receives the building script's final visible
piece set and forwards only primitive values across the synced/unsynced
boundary:

```text
begin(unitID, unitDefID)
piece(unitID, pieceID)
piece(unitID, pieceID)
...
end(unitID)
```

LuaUI reads the unit's COLLADA (`.dae`) geometry once per model and caches it.
The DAE supplies the actual piece-local triangle mesh. Recoil's live
`Spring.GetUnitPieceMatrix` supplies the cumulative piece transform, including
the authored node transform / COLLADA unit scale as imported by the engine and
any final script movement or rotation.

The transformed triangle surfaces are conservatively voxelized on a 16-elmo
model-space grid. The current safety cap is 16000 occupied cells per building.
The voxel cells are transformed to world space once after the procedural build
has settled, then rasterized into sixteen shared 512x512 world-space slices
covering Y=0 through Y=2048. Normal lighting samples those textures; it does not
walk the DAE mesh or voxels every frame.

## Dirty updates

Building scripts should pass the exact visible structural piece set after their
procedural build is stable:

```lua
GG.MarkBuildingShadowVolumeDirty(unitID, visiblePieces)
```

This rebuilds that unit's voxel shell and the shared atlas once. It must not be
called every frame.

A parameterless dirty mark is retained only for older scripts: if an explicit
piece set has already been supplied for that unit, the gadget reuses that last
snapshot. It deliberately does **not** fall back to every model piece, because
hidden construction/placeable pieces were the source of the old oversized and
offset shadow volumes.

## Debugging

Select a completed shadow building and run:

```text
/radiancedebug voxels
```

or lock a specific unit:

```text
/radiancedebug voxels UNITID
```

The generated cells are drawn as a translucent cyan voxel shell directly over
the rendered building, with depth testing disabled so scale/offset mistakes are
immediately visible. The diagnostics line shows the DAE path, COLLADA `unit`
value, matched piece count, triangle count, voxel count, and whether the safety
cap was hit.

Disable the overlay with:

```text
/radiancedebug voxels off
```

The old `radiancedebug volumes` spelling remains as an alias while this branch
is being tested.
