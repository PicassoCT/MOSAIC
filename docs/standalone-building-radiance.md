# Standalone building radiance occlusion

Standalone houses now supply a solid building block to the same static
height-band occlusion system used by procedural Asian and western houses. This
covers `house_asian1` and `house_asian3`, including the selected Arcology and
Project variants.

## Shape and lifetime

The block follows the bounds of the main building pieces actually selected by
the unit script. Piece scale, rotation and translation are applied before the
existing renderer applies the unit's world position and orientation. Hidden
alternate models, the icon and distant street furniture do not enlarge it.
When the script selects two main buildings, both contribute to the solid outer
envelope. Courtyards and interior openings are deliberately filled by this
simplified shadow model.

Geometry is cached after model selection and forwarded through the existing
building-column messages. Construction completion makes it available to the
renderer; actual destruction removes it. Temporarily hiding a house for the
raid presentation retains its physical blocker, matching procedural houses.

Building-shadow membership is centralized in
`getBuildingRadianceShadowTypeTable` in `scripts/lib_mosaic.lua`. It adds the
standalone solid profiles and preserves existing `throwsShadow`/`throwsshadow`
column providers. Consumers use that set instead of repeating unit names.

## Rendering limits

This uses the existing static building atlas and its 16 height bands across
2,048 elmos. Light paths in occupied bands are blocked; paths above those bands
remain clear. The building silhouette is a solid approximation, and the static
height bands retain their existing 128-elmo vertical resolution. Mobile units
continue to use the separate height-aware box/ellipsoid intersection path.

No additional building shadow texture or per-frame model capture is needed.

## In-game validation

Select a completed standalone house and enter:

```
/radiancedebug voxels
```

The displayed column volume should cover the selected main building, with its
unit rotation and placement. Aim vehicle headlights or another low light at
one side and check that the beam stops at the block instead of passing through
to the far side. Repeat with a Project and an Arcology, then destroy the house
and verify that the old blocker disappears.

```
/radiancedebug voxels off
```

To verify that the shared configuration import also enables mobile shadows:

```
/radiancelight shadows stats
```

The command should report caster statistics instead of the former `pairs`
initialization error.
