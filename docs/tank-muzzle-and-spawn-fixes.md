# Tank muzzle, monetary labels and overlapping ruins

This audit starts from `master` at `33ff371ffae5f7da4d4270379732931661bcf49e`
and the supplied screenshots `screen00945.jpg`, `screen00946.jpg` and
`screen00947.jpg`. It accompanies the police-light correction documented in
[police-radiance.md](police-radiance.md).

The completed branch is rebased onto `d3a9efe3990c0dfa90d6aad004bb2680ec4d926c`,
which arrived during this audit and contains the all-culture reconstruction
and persistent rubble-blocking changes. Those changes are preserved.

## Tank firing effect

Both `ground_tank_day` and `ground_tank_night` use `scripts/tankscript.lua`.
Its existing `FireWeapon1` emitted the older muzzle CEGs and ejected a shell.
There was no tank FlamePainter firing hook. The generic projectile-derived
muzzle light was also restricted to the night window.

The new firing hook publishes `mosaic_tank_muzzle_frame` with `inlos` access.
The existing combat renderer reads that stamp and creates a paired FlamePainter
ribbon and radiance source for 12 simulation frames (0.4 seconds at 30 Hz).
Both use the same fading envelope, including in daylight. The client derives
the current origin from the `FireEmit` piece and the firing axis from
`Cannon1` toward `FireEmit`; the old CEG rotation on `FireEmit` therefore does
not turn the new flame backwards. The origin also follows render interpolation.

The two model assets have a barrel span of approximately 93.81 elmos. The
profile produces a plume approximately 79.74 elmos long and 9.57 elmos wide,
with a radiance radius of approximately 175.4 elmos at the default radius
setting. Its origin has two elmos of forward clearance beyond `FireEmit`.
The profile and day/night membership live centrally in `scripts/lib_mosaic.lua`.
The existing combat source and ribbon budgets apply; this feature allocates
no additional lighting texture or full-screen pass.

The old CEGs, shell ejection, aiming and weapon damage remain. The actual
appearance alongside the retained CEG smoke still needs a live Recoil check.

## Whole-number monetary labels

The red `$-540.00201` in the screenshot is produced by the unsynced
`GetMoneyMessage` formatter in `luarules/gadgets/game_collateral.lua`. That
formatter concatenated the raw numeric value. Its old lines trace to
[`8b3825aecf7`](https://github.com/PicassoCT/MOSAIC/commit/8b3825aecf7), dated
30 May 2024; the earlier requested integer display was absent from the audited
master source.

Only presentation changes: the formatter floors the absolute magnitude and
restores the debit sign. Thus `-540.00201` and `-540.99999` both display `-540`,
and `540.99999` displays `540`. A magnitude below one displays `0`, without a
negative-zero label. Existing credit/debit colors and nonnumeric messages
remain. Damage, collateral collection, balances and accumulated bank transfers
retain their fractional values.

`tests/collateral_display_test.lua` exercises the actual synced damage and
bank entry points, the unsynced receiver and the final `gl.Text` string. It
also checks that the financial values passed between those stages remain
precise. The screenshot case fails against the previous formatter.

## Why a ruin could appear inside an intact house

Two historical changes must be distinguished:

| Commit | Date | Change and evidence |
| --- | --- | --- |
| [`15e83c65f7a4c6c9404fec7c1d97955cb60729d0`](https://github.com/PicassoCT/MOSAIC/commit/15e83c65f7a4c6c9404fec7c1d97955cb60729d0), `add: house_ruin` | 24 April 2025 | Introduced `house_ruin` and `overrideRuinByChance`. The initial unit name was `Ruins of the warming wars`. City generation could choose a ruin for a building plot, with a distance-from-center chance and an additional random gate. |
| [`a983d4806de5206c3fc6ff1cc4443a23fa681b88`](https://github.com/PicassoCT/MOSAIC/commit/a983d4806de5206c3fc6ff1cc4443a23fa681b88), `VERSION{1.024}` | 30 November 2025 | Introduced `addRuinsToHouseTable` and called it unconditionally in both branches of `getCultureUnitModelNames_Dict_DefIDName`, including requests for `truck` and `civilian` pools. |

The first commit demonstrates intentional pre-existing war ruins as city
content. The second commit's terse message does not explain its rationale;
the helper name and surrounding code indicate an attempt to include ruins
in house lists. Adding them to mobile-unit lists is inconsistent with that
purpose.

The current civilian gadget takes its truck and pedestrian pools from that
shared helper. It chooses a random definition from the requested pool and
spawns it at a route node. `getRandomSpawnNode` takes the position directly
from a building unit. When the random choice was `house_ruin`, this could
create a separate, immobile ruin at the same position as an intact house.
This source path is consistent with the overlapping meshes in the screenshots;
the screenshots alone do not identify the individual spawned unit IDs.

The correction limits the helper's ruin insertion to `typeName == "house"`
in both the single-culture and international branches. Ruins remain valid
house content and the intentional city-plot ruin roll is preserved. All
existing pedestrian, truck and building variants remain available in their
appropriate pools. The fix does not delete already-spawned units in a saved
or running match; use a new match to validate initial population generation.

## Validation boundary

Focused Lua tests check the behavior and lifetime of the new source, its
visibility filtering, the monetary display, and the cultural pool membership.
The existing combat widget and shader checks cover the shared rendering path.
There is no live Recoil runtime in this workspace, so these checks do not
establish an in-game appearance result or a GTX 1050 Ti frame-time measurement.

Run the focused regressions from the repository root:

```sh
texlua tests/tank_muzzle_effects.lua
texlua tests/collateral_display_test.lua
texlua tests/collateral_collection_test.lua
texlua tests/culture_unit_type_membership.lua
texlua tests/light_effects_widget.lua
texlua tests/police_radiance_lifecycle.lua
MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/combat_light_gpu.py
MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/smoke_ribbons_gpu.py
```

The Python shader checks require Mesa EGL, `moderngl` and `numpy`.
The existing all-culture reconstruction, rubble-blocking and arcology suites
also pass after rebasing. The older broad `game_config_test.lua` has an
unrelated objective-definition fixture failure reproduced on the unmodified
starting master; it is not a passing gate claimed by this audit.
