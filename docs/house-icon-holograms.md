# House icon holograms

The enabled unsynced gadget `gfx_house_icon_holograms.lua` replaces residential
house billboards with small cyan architectural volumes when
`Spring.IsUnitIcon(unitID)` is true. Bright antialiased edges, faint additive
faces and a slowly moving horizontal scan pattern resemble a tactical hologram.
Selected houses turn amber. Zooming back to model range restores normal icons
and leaves normal model rendering to the engine.

Residential units use the `residential_house` icon type. In Recoil's distance-based
icon mode, the 0.5 multiplier switches houses at roughly 2,740 elmos with the
default `UnitIconDist` of 200. The **Strategic icon distance** slider in the
graphics settings scales that threshold. With `UnitIconsAsUI` enabled, Recoil
uses projected size and icon fade settings to decide when to drop the model.

## Geometry and scope

Each icon is a five-face box (20 vertices), scaled and offset from the house's
live collision volume and rotated by its heading. This is deliberately a simple
massing view: individual procedural roofs, balconies and decorative pieces are
not reproduced. Collision volumes may be coarser than the visible house. The
render uses one shared display list and one shader, without textures, full model
redraws or a full-screen postprocess.

Asian, Western and Arab base houses, structural variants identified by their
`house_*_base` custom parameter, and Asian residential megaprojects are included.
Other definitions can opt in with `customParams.house_icon_hologram = '1'` and
use `iconType = 'residential_house'` to get the same distance.
Advertising holograms, decals and other units retain their original rendering.

The pass checks current LOS, cloak, noDraw, view and icon state each frame.
Only full-view spectators bypass LOS. Radar-only and remembered houses are not
reconstructed. Missing bounds or shader/API failure retain engine billboards.
Icon suppression is restored on zoom, LOS loss, hiding the GUI, and shutdown.
The gadget owns the house drawIcon flags while active; other code should not
simultaneously override those flags. Model visibility and minimap flags are
untouched. This runs in LuaRules unsynced because SetUnitIconDraw requires
control permission, including over Gaia houses.

## Validation

Production vertex and fragment sources compiled and linked in Mesa OpenGL 4.5
compatibility. Actual GPU draws verified visible edges, cyan/amber selection,
animation changes, and no GL errors. A mocked Lua lifecycle harness verified
residential inclusion, advertising exclusion, LOS, spectator transitions,
cloak/noDraw filtering, missing bounds, zoom, GUI hiding, LOS loss, shutdown,
shader failure, and outward mesh winding. Checks ran in an external scratch
workspace; no in-game tests directory was added. The configured external suite
runner was unavailable in this environment.

Recoil appearance and frame time remain unverified. In game, zoom across the
icon threshold over houses of each culture, select houses, rotate the camera,
change spectator LOS, reload LuaRules and check infolog. Confirm dimensions
against procedural houses and measure zoomed-out FPS in a dense city before
merging. Disable the House icon holograms gadget to restore the original view.
