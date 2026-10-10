# Peaceful city reconstruction

Destroyed city houses retain their plot, building type, facing, route metadata and Asian split plan. A plot has one lifecycle: rubble → construction site → occupied house. Death without an attacker uses the same path. Scripted houses and map-authored houses are included; unrelated objective respawn rules are unchanged.

Rubble sinks as its decay clock advances. Default decay requires five minutes of peaceful simulation time, followed by one minute of construction. Nearby incidents restart a 90-second quiet period. Anarchy, postlaunch and game-over freeze both stages. Work resumes from its existing progress after peace returns. Configuration lives in `getGameConfig().city.rubble` and `luarules/configs/city_area.lua`.

Construction sites use the original house UnitDef in the engine's being-built state. Arabian and Western houses retain their construction props until completion; modular Asian houses reveal their pieces in height order as the construction clock advances. Single-mesh houses use the native build rendering. Sites stay outside the occupied-building/traffic registry. Safehouse placement, engine build masks and delayed script attachment all require a completed host. Player build/reclaim steps cannot advance a managed construction site. Battle damage is retained when work resumes.

Failed unit creation retains the plot and its current rubble. Removing rubble cannot trigger immediate reconstruction. Destroying a construction site resets that same plot to rubble, without creating another reconstruction job. A replacement keeps the original coordinates and facing. Routes are pruned on destruction and regenerated after completed replacements, batched once per update.

## Shared area metadata

`GG.CityAreaState` is the single sparse, synced spatial service for damage heat, nearby conflict and civilian danger. The old `GG.DamageHeatMap` name aliases the same object for compatibility; it is not a second map. Civilian per-person memories remain personal behavior records.

- `ReportIncident(x, z, damage, radius)` refreshes affected cells. The default radius is 700 world units. Projectile launches and impacts count even when no unit was hit; damage contributes heat. Utility weapons with default damage ≤1 do not generate firing/impact incidents.
- `IsDangerous(x, z)` and `IsConflictNearby(x, z)` share the same expiry; `IsPeaceful(x, z)` is their inverse. Citywide phase checks belong to the reconstruction policy.
- `getDangerAtLocation(x, z)` returns finite normalized heat. `getHighestDangerLocation()` returns world coordinates or nil if no active incidents exist.
- Cells are 256 world units; any cell touched by an incident's radius is conservatively unsafe. Queries do not allocate cells, and expired cells are removed every second. No per-building enemy scans are required.

## Validation

Run `tests/city_reconstruction_test.lua`, `tests/city_area_events_test.lua`, `tests/city_construction_animation_test.lua`, `tests/city_arcologies_test.lua` and `tests/civilian_daily_life_invalid_targets_test.lua` under Lua 5.1, or use the Peaceful city reconstruction workflow.

In Recoil, destroy one house; confirm visible sinking rubble, pause it with nearby firing, and wait for a native construction site. Try a safehouse during construction, trigger anarchy just before completion, then restore peace. Repeat with Arabian, Western, modular Asian and standalone models. Rendering and live-game performance require this engine check; the automated suite mocks engine calls.
