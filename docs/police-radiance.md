# Police radiance lights and mobile shadow assessment

## October 11 restoration

Two independent failures prevented the previous police source fix from reaching
the road and surrounding surfaces:

1. **The combat widget failed during initialization.** Its isolated
   `lib_mosaic.lua` include inherited `_G`, but MOSAIC's real LuaUI `System` table
   does not expose `_G` inside widgets. Consequently the central police-profile
   helper attempted to call a missing `pairs`, and initialization stopped before
   publishing `WG.CaptureCombatLightEmission`. The earlier source-only tests ran
   in a host environment with `_G`, so they did not exercise this failure.
   Commit `8c637f4` restores the real widget environment with `getfenv(1)`.
   The same startup failure also removed tank muzzle lights and FlamePainter.
2. **The police vehicle's simplified shadow box swallowed its own beacon.** The
   lamp is approximately 38.8 elmos above the unit origin, above the roughly
   34-elmo body. The mobile-shadow shader only exempted an owner's box if the
   lamp was *inside* it. Downward rays from a lamp just above the broad proxy roof
   re-entered that box, suppressing most of the nearby red-blue illumination.
   A production Lua/GL fixture measured the selected road patch's blue RGB sum
   dropping from 77.13 to 10.77 when that owning box was enabled.

Attached lamps now exclude exactly their owning unit's simplified proxy whether
the attachment is inside, above or outside its bounds. This deliberately leaves
the housing and own-vehicle self-shadow out of the coarse-proxy approximation.
Other units still cast finite, height-aware shadows; unowned sources and static
building occlusion remain subject to their normal tests. Lamp colors, strength,
radius, pulse timing, actual piece positions and visibility filters are retained.

`tests/radiance_capture_state_gpu.py` now loads the actual `luaui/system.lua`
sandbox and combat widget, then runs the central police profile, real collector,
real Lua capture, production GLSL and real scene renderer in Mesa OpenGL. It
checks outward red and blue road pixels, the owner-bearing source atlas,
neighboring-car shadows, live movement and cleanup when the unit becomes hidden.
The test deliberately sets unit LOS true and positional LOS false. It also starts
each direct capture with inherited alpha testing enabled. Neither the source
collector nor the capture or scene renderer is substituted by a test module.
World/engine queries use a geometric fixture, so this is not a live Recoil or
target-hardware appearance measurement.

The new own-proxy assertion fails after the startup fix with the old shadow
condition, and passes with exact-owner exclusion. `tests/mobile_radiance_shadows_gpu.py`
also checks sources inside and above/outside their owning box, a separate car
blocking an elevated source, and unowned rays still intersecting the box.

## Earlier source and model audit

Source/model audit: master `33ff371ffae5f7da4d4270379732931661bcf49e`.

The police light collector now follows the visibility of its owning vehicle.
Previously it accepted the vehicle, then independently rejected its lamp if the
lamp position was outside terrain LOS. Police scripts make the unit always
visible, so these two tests can disagree during an ordinary player view.

## Visibility and placement

`scripts/Policetruckscript.lua` calls `SetUnitAlwaysVisible(true)`. Recoil's
`CLosHandler::InLos(const CUnit*, int)` honors that flag, whereas its positional
overload only checks global LOS and the sight map. The combat collector used
both `GetUnitLosState` and `IsPosInLos`; the latter discarded otherwise visible
police lights. Full-view spectators bypassed that check, which can conceal the
regression during spectator testing.

Engine references: [unit LOS](https://github.com/beyond-all-reason/RecoilEngine/blob/master/rts/Sim/Misc/LosHandler.cpp)
and [positional LOS](https://github.com/beyond-all-reason/RecoilEngine/blob/master/rts/Sim/Misc/LosHandler.h).

The attached police lamp now uses the owner's validated visibility. Cloaked,
no-draw, transported, invalid and destroyed units remain excluded. Unattached
explosions, projectiles and fires retain their positional LOS checks.

The lightbar profile and membership set live in `scripts/lib_mosaic.lua` behind
`getPoliceLightTypeTable`. A scoped `MOSAIC_CONFIG_ONLY` include gives LuaUI the
pure helper without running the synced game configuration. The renderer checks
the resulting UnitDefID-keyed set and contains no police unit-name list.

The current police unit uses `objects3d/apc.dae`, with `Body2` shown. Its upright
body reaches approximately 33.983 elmos above the unit origin. The previous
fixed emitter at height 37 was therefore above that body by approximately
3.017 elmos. This was not a demonstrated case of emission inside the car.

The real roof helpers are **LightEmit01** and **LightEmit2**. Their pivots are at
height 28.783, below the top of the body/lightbar mesh. The existing CEG helper
adds ten elmos. The cascade now uses those same named pieces with ten elmos of
clearance along the vehicle's up vector, plus the engine's draw-position offset.
The source follows movement and tilt. A model-oriented rooftop fallback handles
unavailable helpers. The third legacy CEG helper and existing CEG animation remain.

The radius (135), strength (2.4), five-frame red/blue phase, daytime emission and
shared 96-light budget remain the same. Piece indices are cached per unit;
positions follow each draw frame. No new render pass or texture is allocated.

## Building occlusion

Current cascade occupancy contains the published building column meshes, not
ordinary cars or pedestrians. The car body cannot block its own light through
that atlas. Capture also disables depth testing, so a hidden helper mesh does
not hide the analytic light footprint.

Actual building occupancy still blocks police light. A source inside a building
cell can lose its outward projection, including at coarse cell boundaries. The
fix does not add a blanket clearance radius that would let lights cross walls.
The police dispatch already samples outside its chosen building and checks
`TestMoveOrder`; this is not a guarantee against every neighboring atlas cell.

## Validation and in-game check

`tests/police_radiance_lifecycle.lua` reproduces the original failure with unit
LOS true and positional LOS false. It covers real central profiles, visibility
guards, exact piece names, interpolation, tilt, fallback/recovery, same-frame
registration/removal, reused IDs and the shared source budget.

`tests/combat_light_gpu.py` renders the production GLSL at the 512-square / 8192
elmo whole-map resolution. Both police colors reach beyond the car's bounds;
neighboring buildings block them, and a source actually inside an occupied
building remains blocked. Mesa software OpenGL validation is not an in-engine
appearance or GTX 1050 Ti performance measurement.

In a normal player view, find police outside the area covered by friendly units.
Use `/police lights` to report tracked, visible and emitted sources, exact-anchor
versus fallback usage, and sources that would fail the old positional LOS check.
The emitted count reflects the shared light cap. Capture/occupancy status reports
provider availability; it does not prove that the scene overlay is enabled.
Use `/radiancelight on` if needed, and inspect the alternating road/wall light
while the car moves. Compare `/radiancedebug on` and `/radiancedebug zoom 1024`,
then hide the diagnostic with `/radiancedebug off`.

Live Recoil rendering and target-hardware performance require an in-game pass.

The focused police, Cinder and combat lifecycle suites pass under Lua 5.1, and
the cascade/live-field lifecycle suites and combat/live-scene GPU suites pass.
The broader `game_config_test.lua` currently fails on objective identifiers with
underscores. The same failure reproduces on the unmodified audited master; this
change does not alter the `getGameConfig()` section.

## Mobile shadows

The assessment below predates the implemented height-aware proxy renderer.
Its current behavior and limits are documented in
[`mobile-radiance-shadows.md`](mobile-radiance-shadows.md).

Oriented car boxes and vertically stretched pedestrian ellipsoids are suitable
approximations. The useful implementation is a medium feature: drawing the
proxies is simple, but their height and interaction with source/receiver
visibility require coordinated changes.

The global building atlas is 512 square, giving 16-elmo pixels on an 8192-elmo
map. Pedestrians are smaller than a pixel. Existing camera-local occupancy is
512 square over 1024/2048 elmos, giving two/four-elmo pixels. Start there, with a
bounded set of visible nearby units plus a margin for offscreen shadow casters.
Keep membership and shape profiles centralized in `lib_mosaic.lua`.

Keep a separate dynamic height atlas and lifecycle. A 512-square RG16F min/max
height pair costs approximately one MiB, excluding driver overhead or an owner
channel. Do not set the static building `occlusionDirty` flag on vehicle
movement: that also restarts the incremental exterior-window lighting bake.

The headlight and combat-light capture shaders must test the dynamic blockers,
because those fast direct fields otherwise fill in a shadow created only in the
cascade. Their source-to-receiver rays retain source height, making bounded-height
car/pedestrian shadows practical. Exclude the source's own blocker carefully and
sample receivers by height so car roofs do not become dark occupancy pixels.

Diffuse neon propagation is currently horizontal 2D transport in 128-elmo height
bands. A car footprint inserted directly into that binary atlas acts like a much
taller column. A min/max atlas improves direct-light shadows, but does not alone
make propagated neon fully three-dimensional: accurate vertical transport needs
additional slices or richer radiance data.

The recommended first version combines bounded-height direct shadows with
approximate local cascade shadows, retaining the five-Hz cascade schedule and
using the existing faster nearby direct-light path for motion. Profile the extra
ray texture samples before raising solve frequency. Use the visible disguise's
shape, and omit hidden/cloaked units so shadows cannot expose an operative.
