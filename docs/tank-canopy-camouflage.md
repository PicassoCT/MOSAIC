# Tank canopy camouflage

The optional umbrella on `ground_tank_day` now projects the lit terrain seen
behind it from the current camera. The canopy alone gets the projection: the
barrel, tracks and any hull extending past its silhouette remain physical.
This is a visual effect; targeting, radar, LOS and gameplay cloaking are unchanged.

The existing 10% equipment roll remains. Equipped tanks always unfold their
canopy; the accidental second 10% roll has been removed. The unfolding panels,
all seven movement meshes and all seven evening meshes publish only their
currently visible pieces. Movement no longer resets to the same frame, evening
meshes are passed as lists, and the initial model reset finishes before unfolding.

`gfx_tank_camouflage.lua` copies the lit framebuffer in `DrawWorldPreUnit`, before
the engine draws units or features, and redraws those panels in `DrawWorld` with
depth testing. Sampling uses camera screen coordinates, so an oblique view shows
the ground behind the canopy instead of a vertically projected map texture.

The shader uses six-pixel cells, 48 colour levels, mild fixed calibration error,
roughly 2% temporary neighbour-sampling faults and a few darker cells. Faults
refresh seven times per second. There is no additive glow at night.

One RGB8 texture is shared by all visible equipped tanks (about 6 MiB at 1080p,
24 MiB at 4K). There is one framebuffer copy per rendered view containing an
eligible tank, no extra scene render and no CPU readback. Icons, incomplete units,
engine-cloaked units, dead/hidden units and units outside local LOS are excluded
before capture. Full-view spectators are supported. Resize/shutdown delete the
texture; shader/allocation failure leaves the ordinary engine panels visible.

## In-game check

1. Give several `ground_tank_day` tanks until one has the optional canopy. The
   variant is still random; it is not an upgrade applied to every tank.
2. Place it across a road/sand boundary. Check the terrain aligns from top-down
   and angled cameras; six-pixel blocks and small faulty tiles should reveal it.
3. Move, stop and turn it, then check the evening variants at night. Hidden
   animation frames must not accumulate or appear as floating panels.
4. Move behind a building and outside LOS. The projection must remain occluded.
   Also check icon zoom, construction, destruction, resizing and LuaRules reload.

The capture includes terrain lighting, existing terrain shadows and tracks. It
does not erase the tank's physical shadow or tracks, and it does not reproduce
water, units, features or effects drawn after the pre-unit pass. Those remain
limitations of a terrain-only camouflage projection. Reflections use the normal
engine material. Final appearance still needs an in-game Recoil check.

## Automated checks

From the repository root:

```sh
lua5.1 tests/tank_camouflage.lua
MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/tank_camouflage_gpu.py
```

The Lua harness also runs with `lupa.lua51`. The GPU test requires `moderngl`,
NumPy and an EGL compatibility context. It compiles the shipping shaders and
checks camera alignment, actual pixel blocks, sparse faults, darkness, opaque
output, foreground occlusion, panel bounds and a nonzero viewport origin.
