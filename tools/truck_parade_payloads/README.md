# Lantern parade payloads

The six existing MOSAIC Lantern Float Cages designs are exported together as
`objects3d/truckPayloadParade.dae`. The bundle contains the Forest Dreamer,
Wandering Bathhouse, Moonwhale, Lantern Koi, Cloud Mill and Night Post. Each
vehicle shows one float, including its separately controlled articulated
pieces. The model contains no truck geometry.

## Source and rebuild

The source recipes in `source/recipes/`, `source/authoring.py`,
`source/geometry.py` and `source/palette.json` are copied from the user's
MOSAIC Lantern Float Cages package completed on 2026-11-02. They preserve its
connected spline control nets, absolute handles, parts and motion-group
pivots. The original editable 3ds Max files remain untouched. Only evaluated
game meshes are triangulated.

From the repository root:

```sh
python tools/truck_parade_payloads/generate.py
```

Python 3 and NumPy are required. The generator writes the DAE, its material
and culling sidecar, and `manifest.json`. All six designs retain their authored
parts and use the unmodified `house_asian_diffuse.dds` and
`house_asian_selfilu_reflection.png`. The verified palette addresses luminous
and opaque islands directly; no substitute glow texture is generated.

The source coordinate system (front `-X`, up `Z`) is rotated into the game's
front `+Z`, up `Y` and scaled by `0.08`. The mounting skid is 45.6 units long
and 17.6 units wide, with its floor at 2.1 units above the attachment origin.
The existing service payload's mounting system is reused, with offsets
measured for the float's narrower skid on `truck_arab6`, `truck_arab7` and
`truck_arab8`. All six native float pieces keep
their original container numbering, 66 through 71.

## Runtime

`scripts/lib_truck_parade_payloads.lua` contains the variant and carrier
catalog. `truckpayloadparade` inherits the ordinary payload's native transport
properties. `SetParadeVariant(index)` selects one of six floats deterministically
and returns a success boolean. It can be called before or after the unit's
`Create` callback. It never substitutes random cargo or consumes the ordinary
service-payload quota.

The Moonwhale's fins/tail and Night Post's wings retain their separate authored
hinges. The Cloud Mill's rotor turns around its horizontal axis with the
established three-second pause, five-second spin cadence. Visibility and
motion of every unselected variant are reset explicitly because Spring
piece visibility does not propagate to children.

Transport attachment supplies all motion. The payload waits up to five
seconds for its first attachment and retires after two seconds without a
carrier once attached. Its tooltip follows the carrier and preserves later
external tooltip edits. All articulated poses and mounting offsets fit inside
the exported culling bounds.

## Checks

```sh
lua tests/truck_parade_payloads_test.lua
python tests/truck_parade_payload_models_test.py --lua lua
```

The native model check requires `assimp_py` and NumPy. It validates Assimp
import, the actual Lua catalog, piece hierarchies and pivots, winding and
normals, luminous atlas UV islands, triangle budgets, culling bounds and
mounting clearance against the three original carrier meshes. In a sparse
checkout, `--carrier-dir PATH` can point to those exact carrier DAE files.
