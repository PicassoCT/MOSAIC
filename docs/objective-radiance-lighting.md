# Objective and street-placeable radiance

Material audit based on master ba78e02661d2e63c9434ef99b69a332e97d3835f.
Implementation rebased onto e446aca4, preserving the removal of the old taper
and the direct exterior-window lighting revision notifications.

## Lighting changes

- Oil rig: capture the platform's authored illumination mask, including the shared offshore variant.
- Refugee camp: emission follows the SigLightOn show/hide cycle.
- Combat outpost: a narrow downward searchlight attached to the tower roof beside its antenna. It sweeps 65 degrees to either side over a 16-second cycle using interpolated game time. Its direct wall/terrain lighting updates every rendered frame; the cascade receives only a small fixed bulb spill, preventing stale moving pools. The old `outpost_roof` record remains accepted after LuaUI reloads.
- UNATO/Westhem military headquarters: capture the main building and visible HyperLoop sections through the existing house_asian illumination mask. Hidden sections do not emit; the boundary section follows its actual visibility. Flying VTOLs and rotors do not enter radiance.
- Presidential palace: eight warm exterior uplights around the selected Palast mesh, placed from its scaled, rotated bounds. They illuminate its walls above the ground cascade band and contribute local radiance at the fixtures. Unselected palace variants never register. No texture mask replacement is required.
- Transrapid: capture the central mesh and visible endpoint stations through their illumination mask. Correct tex2 to house_asian_selfilu_reflection.png; the UnitDef normaltex remains unchanged.
- Airport: keep runway SwitchLight emission. The giant circling aircraft's navigation lights and the scramjet thrusters retain their visible animation but no longer inject radiance into the ground receiver band.
- Glacier piston: emission follows the rotating logo's actual flicker show/hide calls.
- Geoengineering: alternating emission follows the rotated BlinkyLight pieces. A long, thin sulfur-yellow FlamePainter aerosol plume starts beyond the blimp's long-axis tip, follows its transform, drifts with wind, fades to transparent and stops on death. It has no flame emission.
- house_asian procedural, standalone and comb street placeables: only selected/shown Placeable pieces and their selected children register. Capture uses their existing correct illumination mask. The parent must have a longest scaled dimension of at least 32 world units. The cutoff is placeableMinSize in luaui/widgets_mosaic/include/radiance_objective_sources.lua. Size calculations are cached per model/piece; hidden or out-of-LOS houses do not contribute.
- Static records are restored for late joiners and after unsynced Lua reloads.

Direct objective cones share the existing scene depth/normal pass and are limited to the nearest 24 fixtures. They have finite range, surface incidence and soft edges, with the existing receiver-band occupancy atlas providing approximate obstruction. They honor LOS, cloak, no-draw and unit removal. No Recoil shader framework or engine setting is enabled.

The headquarters connection was committed as 404315d0 after master 9a82bed8. Testing master 9a82bed8 alone does not include the headquarters source registration.

## Material audit

These are active tex2 assignments, verified from the full model metadata, with comments excluded. In the radiance material-capture shader, texture 2 red is self illumination and alpha is coverage. A normal texture is therefore not an appropriate emission mask. Normal mapping is supplied separately by UnitDef customparams.normaltex/the normal-texture binding.

This is a source/configuration audit, not confirmation that every entry has a visible defect in Recoil. In particular, active PBR tables need a runtime material-path check. The old custom-unit-shader gadget exits on engines newer than 100; no shader framework is restored by this change.

| Model metadata | Existing tex2 | Finding |
|---|---|---|
| `aicore.dae.lua` | `propagandaserver_normal.dds` | Normal map in the standard material slot |
| `assembly.dae.lua` | `component_atlas_normal.dds` | Normal map in the standard material slot |
| `hivemind.dae.lua` | `propagandaserver_normal.dds` | Normal map in the standard material slot |
| `safehouse.dae.lua` | `safehouse_normal.dds` | Normal map in the standard material slot |
| `barricade.dae.lua` | `CheckPoint_normal.dds` | Normal map in the standard material slot |
| `house_arab.dae.lua` | `house_arab_normal.dds` | Normal map in the standard material slot |
| `GreenHouse.DAE.lua` | `house_europe_normal.dds` | Normal map in the standard material slot |
| `checkpoint.dae.lua` | `CheckPoint_normal.dds` | Also has an active PBR table; renderer review needed |
| `brehmerwall.dae.lua` | `CheckPoint_normal.dds` | Also has an active PBR table; renderer review needed |
| `house_western.dae.lua` | `house_europe_normal.dds` | Normal map in the standard material slot |
| `mobile_assembly.dae.lua` | `component_atlas_normal.dds` | Normal map in the standard material slot |
| `propagandaserver.dae.lua` | `propagandaserver_normal.dds` | Normal map in the standard material slot |
| `objective_airport.dae.lua` | `house_europe_normal.dds` | Normal map in the standard material slot |
| `house_western_vtol.dae.lua` | `house_europe_normal.dds` | Normal map in the standard material slot |
| `objective_powerplant.dae.lua` | `component_atlas_normal.dds` | Normal map in the standard material slot |
| `objective_transrapid.dae.lua` | `house_asian_normal.dds` | Corrected in this branch |
| `objective_pumpstation.DAE.lua` | `component_atlas_normal.dds` | Normal map in the standard material slot |
| `house_western_spinner.dae.lua` | `house_europe_normal.dds` | Normal map in the standard material slot |
| `objective_factoryship.dae.lua` | `Factory_Ship_Normal.dds` | Normal map in the standard material slot |
| `objective_refugeegyland.dae.lua` | `component_atlas_normal.dds` | Normal map in the standard material slot |
| `objective_combatOutpost.dae.lua` | `CheckPoint_normal.dds` | Also has an active PBR table; renderer review needed |
| `objective_irrigationfarm.dae.lua` | `component_atlas_normal.dds` | Normal map in the standard material slot |
| `objective_geoengineering.dae.lua` | `component_atlas_normal.dds` | Normal map in the standard material slot |
| `objective_military_gyland.DAE.lua` | `component_atlas_normal.dds` | Normal map in the standard material slot |
| `objective_artificialglacier.dae.lua` | `component_atlas_normal.dds` | Normal map in the standard material slot |
| `objective_presidentialpalace.dae.lua` | `house_europe_normal.dds` | Normal map in the standard material slot |

Most affected atlases have no separately named illumination map in the repository. Replacing them all with another atlas's mask would map the wrong UV regions. Author masks for those atlases, or register dedicated lamp pieces. The house_asian material mappings and the oil rig already reference the proper house_asian mask and are left intact.

## Validation and in-game check

Automated coverage includes actual objective script blink/flicker events, station show/hide, mask selection, lamp placement under rotated/scaled pieces, palace variant selection, interpolated searchlight motion, source budgets, placeable parent-size and visibility gating, sulfur plume lifecycle/outlet, late-join snapshot, and the widget's real capture wiring. `tests/objective_spotlights_gpu.py` exercises the actual scene shader for a narrow moving pool, source removal, range/obstruction and warm elevated facade lighting. Existing GPU tests exercise real radiance emission and SmokeRibbon GLSL with Mesa's compatibility profile.

An in-game visual pass is still needed: inspect the headquarters on a version containing 404315d0, the palace facade uplights, the outpost's full searchlight sweep, both Transrapid endpoint stations, both phases of the warning lights, the glacier logo, and a large street placeable beside an unlit small one. Confirm the sulfur plume's visual scale at the geoengineering blimp. Use /radiancedebug on and /radiancedebug zoom 1024 for source inspection, then /radiancedebug off. Verify house hide/show and a LuaUI reload leave no stale lights.
