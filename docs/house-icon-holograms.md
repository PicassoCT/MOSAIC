# House icon holograms

**Options → Graphics → House holograms** switches the local strategic view
between voxel silhouettes and regular house icons. The setting defaults to on
and persists across matches. Zooming inside the icon threshold shows the
ordinary building model. The residential icon distance multiplier is 0.5,
about 2,740 elmos at UnitIconDist 200 in Recoil's distance-based mode.

Selecting a safehouse or its installed upgrade colours the host amber on the
owning team's selecting player's screen. The synced attachment, replacement
and morph paths maintain the host ID in private player rules parameters.
The draw pass checks local selection and current team and excludes spectators.
Cyan geometry follows the building's normal line-of-sight and cloak checks.
Recoil builds without private player rules parameters use cyan silhouettes.

Each complete building has one screen-space identity mask. A bright cyan rim
follows the visible contour of the combined building, including openings.
Overlapping pieces and internal voxel boundaries have only faint grid detail.
Adjacent buildings keep separate identities and outlines. Border widths are
measured in screen pixels; a selected host gets a wider amber rim.

The renderer draws the cached geometry once into a shared viewport-sized mask
and composites it in one additional screen pass. A private copy of scene depth
resolves occlusion between pieces, houses and foreground terrain/units without
changing the main depth buffer. Glow extends inward, so it cannot spill onto
foreground objects. The RGBA8 mask and 24-bit depth target are reused until
the viewport changes. If framebuffer allocation fails, regular icons remain.
The extra screen pass and depth copy have not been profiled in-game.

Procedural Arab, Asian and Western houses reuse the assembled building's
shadow columns, including floor masks, terrain offsets, courtyards and updates
from structural damage. The renderer meshes the exterior of the occupied runs.
Arcologies, projects, camps and Luxor Combs use an 8×8×8 mask per selected main
mesh, its imported bounds and its unit-piece transform. The silhouettes omit
small decorations and animation. The preview shows three individually framed
building silhouettes rendered offscreen with the production shaders; the Luxor
Combs combines its plate and selected base, and Project 5 is shown selected.

![Three standalone building voxel silhouettes](images/house-icon-voxels.png)

The draw pass caches one display list per house and builds up to three changed
lists per frame. Ordinary icons cover houses awaiting geometry. To rebake the
standalone profiles after editing a model, run
`python tools/house_icons/bake.py` at the game root with NumPy and SciPy.
