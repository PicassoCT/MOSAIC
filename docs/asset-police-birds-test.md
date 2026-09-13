# Asset rooftop, police and sniper birds

Branch: `fix/asset-rooftop-police-birds`.

Police report the victim's location. They do not know the shooter's location until
within 650 world units, in Gaia LOS, and the suspect is uncloaked. Existing civilian,
truck and building damage reports remain supported; closecombat is excluded.

Configuration in `scripts/lib_mosaic.lua`, `Police`:

- Report delay: 8 seconds, followed by driving time.
- Minimum response-building distance: 2200 world units from the report.
- Exposure expires 30 seconds after the last report or police sighting.
- Search expires 45 seconds after dispatch delay / last sighting.
- Search radius: 600 world units.

Police spawn outside a remote building footprint on a position accepted by
TestMoveOrder. Missing buildings or blocked spawn positions cause retries. Actual
road connectivity and travel remain engine pathfinding responsibilities. Searches
use reported / last-seen positions, never hidden live suspect positions. Repeated
hits update one incident. No permanent discovery flag is set by police.

## Standalone regression checks

Run from the repository root with Lua:

```
lua tests/asset_rooftop_test.lua
lua tests/police_response_test.lua
lua tests/sniper_birds_test.lua
```

These use mocked Spring APIs; they do not validate Recoil rendering or pathfinding.

## In-engine acceptance

1. Mount a roof and attack a civilian. Asset stays attached and fires while idle;
   movement / Stop retain their existing roof-release behaviour.
2. Observe sniper ravens inland, gulls near low coastal terrain. Birds originate
   above a nearby building and fly away for about 30 seconds. The same building
   has an eight-minute cooldown; another nearby eligible building may respond.
3. Shoot a civilian: no new response until eight seconds have passed. A truck
   appears beside a different distant building, then drives to the victim's last
   reported location. A killed victim must not erase the report.
4. Shoot again: one incident is updated, without a new truck for every hit.
5. Approach responding police uncloaked: they acquire and pursue the asset.
   Cloak requests are rejected during the exposure interval.
6. Escape their observation and stop shooting: after 30 seconds, recloaking is
   permitted. Police search around the last sighting rather than following the
   disguised asset's live position.
7. Stab a civilian: this report mechanism does not spawn police or add exposure.
8. Try a map with no qualifying distant building: no truck appears at the shooter.

The default timing/radii need gameplay tuning. Recoil attachment firing, collision
clearance, roof height and bird visuals still require an in-engine run.
