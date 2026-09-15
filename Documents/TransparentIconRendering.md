# Transparent icon rendering

The Recoil icon pass previously called `gl.UnitRaw(unitID, true)` with no
explicit textures or shader, using additive blending. Raw drawing supplies
geometry, not the model material; an untextured draw can therefore produce white
silhouettes, and overlapping additive surfaces can wash out their colour.

The pass now binds the unit definition's two model textures and uses a small
standalone GLSL program in `luarules/gadgets/shaders/iconAlpha.*`:

- Texture 1 RGB supplies colour; its alpha selects team colour.
- Texture 2 alpha supplies the transparency/cutout mask.
- Additive blending (`SRC_ALPHA, ONE`) at 0.25 emission restores the holographic
  look, with depth testing and no depth writes. It does not darken the scenery.
  Many overlapping surfaces can still saturate; intensity needs in-game tuning.
- Only `icon_emc` enables scanlines and intermittent coloured band dropouts.
  The effect never shifts UVs across the shared atlas or adds white bloom.
- EMC uses its unit transform so MoveCtrl yaw is visible. Other icons retain
  explicit world translation. All retain animated piece transforms.
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

## EMC turn and charge

EMC turns in place at 20 degrees/second (4.5 seconds for a right angle), then
charges at 1,800 elmos/second, with no acceleration ramp. A new target direction
stops translation until alignment is regained. Motion is normalized, so diagonal
orders are not faster, and the final step is clamped to prevent overshoot. It
holds its heading when idle and removes completed MOVE orders by tag so queued
moves proceed. Particle emission starts/stops on charge transitions instead of
restarting every frame. Settings live beside `hoverAboveGrounds` in ecmscript.lua.

Test short and long moves, 90/180-degree turns, a redirect during a charge, STOP,
shift-queued moves, and moving unit targets. Check that the visible model turns
with its movement controller and stays at the unit's world position. Runtime
appearance and gameplay timing still require testing in Recoil.

A coroutine test exercised stationary turns, charge speed, mid-charge redirects,
STOP, short-move arrival, queued moves, diagonal normalization, and yaw wrapping.
The renderer harness was rerun with additive blending and the EMC unit matrix.
