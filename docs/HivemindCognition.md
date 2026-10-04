# Hivemind cognition and temporal ripples

Hiveminds and AI-Cores now show orange mathematical fragments, temporary
association graphs and outward-moving water-like ripples while their temporal
ability is active. The ripples have a fine crest, weaker trailing line, slight
refraction and a few suspended glints. They repeat for the full active duration.
They originate at each active node's world position, including when the node is
off-center on screen. The existing global slow-motion grade remains.

The graphs are decorative visual metaphors. They do not report recruitment
relationships, targets, routes or other intelligence. Their endpoints must be
visible units. Enemy cloaked or unseen nodes cannot reveal their position through
these effects. Allies can see the effect around their own cloaked node/icon.

## Preview in Recoil

Select a Hivemind or AI-Core and enter `/hivefx 20` for a twenty-second local
preview. `/hivefx off` stops it. This command does not change game speed, charge,
ownership or any gameplay state. The preview stops automatically after its time.

For the real ability, charge and activate the node normally. Observe at an
oblique camera angle, then pan so the node is near a screen edge. Ripples should
stay centered on it. Pause and resume: all effect animation should freeze and
resume without jumping. Deactivate or drain the node: its local effects end and
the global grade fades away. Reload LuaUI mid-ability: persistent rules params
restore the active effect. Test losing LOS and cloaking enemy sources and graph
endpoints; no stale links should remain. Check at daytime, night and strategic zoom.

## Cost and controls

Animation is unsynced and uses elapsed real time, frozen while paused. Only
changed source/team activity flags are published; no positions, symbols, graph
points, wave phases or per-frame visual messages cross the sync boundary.

The client draws at most four nearby sources, 96 three-symbol columns, twelve
association links and three ripples per source. All glyphs, curves and suspended
glints share one depth-tested line batch. Fine detail fades with camera distance;
off-screen sources are culled. Visible graph candidates refresh at 2 Hz.

The existing postprocess now reads a copied depth buffer to anchor refraction
and ring highlights to the scene. It uses one color and one 24-bit depth texture,
allocated on first use and recreated lazily after resize. No copies or draw calls
run when inactive. GLSL handles either OpenGL depth convention via Recoil's
`Platform.glSupportClipSpaceControl` flag. No deferred-rendering buffers or texture
assets are required. No extra radiance-cascade sources are registered.

Tuning: `include/hivemind_cognition.lua` contains detail budgets and glyph/link
appearance. `shaders/slowmo/slowmo.frag` contains ripple width, strength and height
fade. Wave period (6 seconds), lifetime (18 seconds), start radius (40) and speed
(62 world units/second) match the suspended glints in the cognition helper.

## Automated checks

`texlua tests/hivemind_cognition_test.lua` exercises the production synced gadget,
client lifecycle, visibility filtering, rendering budgets, pause, preview and reload.

`python tests/hivemind_ripple_gpu.py` compiles and renders the production shader
with an EGL OpenGL compatibility context. It checks outward motion, off-center
origins, long-running repetition, empty/sky surfaces, height occlusion, both depth
conventions and zero-strength identity. This does not replace the Recoil visual
check or establish a frame-rate result on the target NVIDIA 1050 Ti.
