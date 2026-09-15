# Transparent icon rendering

The Recoil icon pass previously called `gl.UnitRaw(unitID, true)` with no
explicit textures or shader, using additive blending. Raw drawing supplies
geometry, not the model material; an untextured draw can therefore produce white
silhouettes, and overlapping additive surfaces can wash out their colour.

The pass now binds the unit definition's two model textures and uses a small
standalone GLSL program in `luarules/gadgets/shaders/iconAlpha.*`:

- Texture 1 RGB supplies colour; its alpha selects team colour.
- Texture 2 alpha supplies the transparency/cutout mask.
- Overall opacity is 0.65, with ordinary source-alpha blending, depth testing,
  and no depth writes. Icons are sorted from far to near. Intersecting surfaces
  within an individual animated model are not triangle-sorted.
- Only `icon_emc` enables scanlines and intermittent coloured band dropouts.
  The effect never shifts UVs across the shared atlas or adds white bloom.
- The existing explicit world translation and animated piece draw are retained.
- Visibility checks exclude cloaked, out-of-view and out-of-LOS icons, with
  full-view spectators allowed to see uncloaked icons outside player LOS.
- Reload initialization recovers existing icons. Shader compilation failure
  leaves normal engine models visible and reports the shader log.

This changes the shared Recoil icon pass, including the raid and other abstract
icons. The existing Spring 105.0 DrawUnit path is unchanged; the glitch effect
is part of the Recoil path. No custom-unit shader framework is enabled.

## Validation

Both shaders compiled and linked in a Mesa OpenGL 4.5 compatibility context.
A mocked Lua harness exercised texture binding, blending, EMC-only glitch
selection, explicit positioning, LOS/cloak/view filtering, spectator visibility,
reload registration, removal, shader failure, shutdown and legacy drawing.
These checks do not replace a Recoil runtime test.

In game, check EMC and social-engineering colour over dark and bright ground,
the large EMC rings, and a raid icon. Rotate and zoom the camera, let the icons
animate/move, then reload LuaRules. Verify that social engineering stays stable
while EMC intermittently flickers, icons remain at their units, buildings occlude
them, and enemy icons do not appear outside LOS. Inspect infolog for shader errors.
