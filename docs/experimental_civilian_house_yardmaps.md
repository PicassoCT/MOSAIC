# Experimental residential high-resolution yardmaps

This branch contains an **isolated prototype**, not an enabled change to existing civilian houses.

`scripts/lib_house_yardmap_experiment.lua` produces an `h`-prefixed yardmap:
- 6×6 footprint → 12×12 (144 cells); 8×8 → 16×16 (256 cells).
- `o` blocks vehicle traversal; `y` remains traversable/buildable.
- Two or three three-cell-wide candidate exit corridors (24 elmos).
- Camera-opposite (model-local) side is completely blocked, including if a courtyard mask opens it.
- Optional surveyed `courtyardMask` uses `#` for geometry and `.` for existing open space; never carves openings through `#`.
- Without a mask, center/corridors are schematic, **not an accurate geometry collision map**.

Example in a house UnitDef, after verifying the model openings and orientation:
```lua
local yardmaps = VFS.Include("scripts/lib_house_yardmap_experiment.lua")
local map = yardmaps.make(6, 6, {cameraBack="north", exits=2})
-- house_arab.YardMap = map  -- enable only after checking model geometry
```

## Requirements before applying to gameplay

1. Determine which MODEL-LOCAL wall is away from the usual gameplay camera. This cannot dynamically follow the camera with a UnitDef yardmap.
2. Extract or author a per-model ground-floor aperture/courtyard mask (algorithmically assembled Asian-house variants may require unique masks).
3. Confirm exits actually reach the street, including rotated buildings, and allow a vehicle's footprint to clear. A 24-elmo opening is not automatically adequate for all trucks.
4. Make civilian spawning/production use an exterior clearance point, or an explicitly exit-only interior corridor if supported by the shipped engine; otherwise fully blocked interiors will trap vehicles.
5. Test pedestrians and rebuilding/demolition, and only then change UnitDef yards. The helper does not inspect DAE geometry or guarantee that pathways line up.

Run the lightweight checks with `lua tests/house_yardmap_experiment_test.lua`.
