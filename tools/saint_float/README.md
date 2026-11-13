# Mother and Child — saint from “another float”

Standalone interpretation of the central hooded mother and swaddled child in
`MosaicConcept/another float.png`. The revised treatment follows the reference's
biblical painting direction: a sorrowful downward gaze, sculpted facial planes,
warm skin, muted ivory clothing, deep blue-grey mantle, and broad cloth folds.
The saint and child are **one mesh object and one atlas material**, with **3,616
triangles**. Internal cage elements share that mesh; this is not a single welded
watertight statue. No existing float or parade selection is replaced.

- [Exported COLLADA model](../../objects3d/paradeSaintMother.dae)
- [3ds Max builder](Build_Saint.ms)
- [Front, three-quarter and back preview](../../docs/images/saint-float/preview.png)
- [Face and hands detail](../../docs/images/saint-float/detail.png)
- [Turntable](../../docs/images/saint-float/turntable.webp)

## 3ds Max

Run `Build_Saint.ms` with **Scripting → Run Script**. It offers two independent
builds, each creating one object:

1. **Build one textured mesh** creates the evaluated mesh with the exact exported
   atlas UVs. Geometry vertices are shared within elements; UV seams remain
   independent. This is the version to place on a float.
2. **Build one editable spline cage** creates one SplineShape containing all
   connected rings and rails, with a live Surface modifier. Edit the base spline
   knots. This is a neutral geometry editing source, not an atlas-unwrapped
   live equivalent of the textured mesh. Edits to it do not automatically update
   the separate mesh or the Python recipe.

The default atlas directory is the repository's `unittextures` folder. When the
script is copied elsewhere, set this in the MAXScript Listener first:

```maxscript
MOSAIC_SaintAtlasDir = @"Z:\path\to\MOSAIC\unittextures"
```

The builder uses the existing `house_asian_diffuse.dds` and the red emission
channel of `house_asian_selfilu_reflection.png`. The textures are unchanged.
It creates new nodes, does not reset the scene, and gives each build one undo
entry. Native 3ds Max 2018 execution has not been available for verification.
The emitted geometry and UV arrays are checked against the COLLADA export.

The implementation follows Autodesk's [Surface modifier API](https://help.autodesk.com/cloudhelp/2017/ENU/MAXScript-Help/files/GUID-26EFC722-00AF-47FA-869A-A1367C5D661E.htm)
and [mesh texture vertex API](https://help.autodesk.com/cloudhelp/2019/ENU/3DSMax-MAXScript/files/GUID-2E5C8194-F165-4D09-8A19-069BFCF83104.htm).

## Rebuilding and validation

```sh
python3 tools/saint_float/build.py
python3 tools/saint_float/preview.py --turntable
python3 tools/saint_float/validate.py
```

Requires NumPy, Pillow, lxml and assimp-py. `saint.py` is the authoring recipe;
`source.json` retains all knots, ring/rail curves and control faces. Closed cage
surfaces are triangulated directly, without voxelization. Atlas UVs encode broad
sculptural shading using existing illuminated gradients. The skin uses the warm
transition between two adjacent emissive ramps; distant mipmapped appearance
still needs review in Recoil.

The runtime export has one identity-transform node, metre=1, Y up, front +Z and
a pivot at the ground origin. The Max builds are Z up, front −Y, with identity
transforms. All scale and pose choices are in the authored cage coordinates.
The validator checks positive closed-cage volume, shared spline knots, geometry
and UV parity, finite normals, unit transforms, atlas emission/opacity, and native
Assimp import. Previews read the actual exported mesh and texture pixels; they
are not game captures. Live Recoil lighting and Max execution remain untested.
