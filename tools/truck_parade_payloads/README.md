# Lantern parade payloads

The active `objects3d/truckPayloadParade.dae` is the user's November 5 export:
24 floats (`Float01` through `Float24`), 16 articulated children, and a shared
`center` root. Preserve these names, including the unpadded child names such
as `Float2Sub9`. Every float and its children are selected together; the small
center mesh remains hidden while its transform supplies carrier mounting.

## Animation mapping

- `Float1Sub1`: hanging lantern, gentle pendulum sway.
- `Float2Sub1`: rigid flag, small alternating turns around its upright pole.
- `Float2Sub2` through `Float2Sub9`: staggered lantern sways.
- `Float3Sub1`: whale tail, slow sway about its root.
- `Float3Sub2` through `Float3Sub5`: dangling ornaments, staggered sways.
- `Float24Sub1`: the only spinner, at 18 degrees/second with a three-second
  pause and five-second spin cadence.

The export's local X points along model -Z, local Y along model -X, and local
Z points up. The rotor therefore spins on local X. The old fins and Night
Post wings are integrated into their parent meshes and are not independently
animated in this export. The existing hologram themes are retained; additional
floats reuse those themes through `hologramTheme`.

`Float24Sub1` originally had its pivot at the platform. The repair moves the
pivot to the original authored axle `(-34, 0, 535)` in mesh coordinates and
compensates vertex coordinates, preserving every vertex's model position.
For a repeat export with the same mistake, run:

```sh
python3 tools/truck_parade_payloads/fix_rotor_pivot.py
```

The repair is idempotent and rejects unfamiliar rotor geometry. Fixing the
pivot in the editable source is preferable for future exports.

## Bounds and checks

After exporting, refresh metadata from the actual model and Lua catalog:

```sh
python3 tools/truck_parade_payloads/audit_export.py --write-metadata
lua tests/truck_parade_payloads_test.lua
python3 tests/truck_parade_payload_models_test.py --lua lua
```

The audit requires NumPy and Lua. It checks all piece names and parentage,
geometry indices, finite coordinates, nonzero triangles/normals, the rotor
axle, and bounds enclosing every articulated pose and carrier offset. The
model test also samples the actual animation axes; if `assimp_py` is installed,
it additionally checks native import. Lua tests read piece names from the real
DAE and cover all 24 selections, motion cancellation, and carrier lifecycles.

The export uses `meter=0.0254`. `centerMoveScale` converts model-space carrier
offsets into the imported parent's coordinates. Carrier offsets are inherited
from the previous installation; the larger re-exported skids still require
in-game fit review. Source UV triangles with zero area are reported rather
than silently remapped; tangent/normal-map appearance needs in-engine review.

## Legacy sources

`generate.py` and `source/` preserve the original six spline-cage recipes.
They are not the source of the current 24-float model. Do not run that legacy
generator in the active checkout: it overwrites the DAE, sidecar and manifest
with the old six-float export. Use the editable 3ds Max source for new exports.
