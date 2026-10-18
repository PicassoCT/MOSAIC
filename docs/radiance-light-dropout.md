# Radiance light dropout: lamp and scene diagnostics

This branch adds diagnostics, not a verified fix for the October 18 missing-light
regression. It does not change shaders, light strength, capture cadence, source
selection, visibility rules, or the mobile-shadow approximation.

## Confirmed finding

`radianceDebugLampScript.lua` included `constants.lua`, which is absent from
MOSAIC's scripts directory. The unit-script loader's `LoadChunk` logs the failure;
`MemoizedInclude` returns without executing an include when no chunk was loaded.
It does not abort the surrounding lamp script. The prepended
`gamedata/unit_script_header.lua` already supplies the animation functions and
axis constants. Remove the redundant include to eliminate the misleading error.

The debug lamp's illumination is independent of this include: Light Effects
registers it through `getRadianceDebugLampTypeTable`, and the ordinary combat-light
collector samples the moving bulb and generates the color-cycling source. Removing
the warning is therefore NOT evidence that the missing illumination is fixed.

## One-command report

Run with the lamp visible; select it to prioritize its row:

```text
/radiancedebug status
```

The independent **Radiance Diagnostics** widget writes `[MOSAIC radiance]` lines
to `infolog.txt`, even when Light Effects or the cascade widget is absent. It has
no Update/Draw call-ins, no GPU capture/readback, and no repeating logs. The report
includes cascade/resolve readiness, published source providers, scene-band and
local-detail readiness, and a copied snapshot of the REAL combat-light queue.

Lamp diagnostics distinguish expected candidates, registered lamps, unit-level
visibility rejection, actual queue membership, bulb-piece availability, the
queued position/radius/strength, daylight gating, and basic ground/band reach.
At most 16 lamp rows are printed; selected lamps come first. No hidden lamp anchor
coordinates are queried or printed. A failed collector is reported as ERROR and
its queue size as UNKNOWN, never as an empty successful queue.

A queued source is not a successful GPU draw. A ready texture can still contain
black pixels. The existing `GetRainRadiance` API provides scene readiness but does
not identify which of its disable/not-ready/zero-gain/dirty-occupancy conditions
caused a nil result. The report keeps that ambiguity explicit.

## Next in-engine capture

Keep the current failing settings first. Run the report and then enable the
existing four-panel diagnostic:

```text
/radiancedebug on
```

Capture the panels and save the complete `infolog.txt`, including startup errors.
Only after recording the failing baseline, test the existing scene switches:

```text
/radiancelight on
/radiancelight test on
```

Run the report again. The test override removes normal time-of-day dimming; it is
not a repair. Restore it with `/radiancelight test off`. A `queued=no` lamp needs
collector/visibility/registration investigation. A `queued=yes` lamp with an
unavailable scene points downstream. A ready scene with a queued lamp but no
visible illumination still needs emission/occupancy/shader/depth-buffer evidence.

## Validation

```sh
lua5.4 tests/radiance_diagnostics_test.lua
```

The test executes the real diagnostics module, independent diagnostic widget,
Light Effects API wiring, and lamp idle/hop script against CPU mocks. It covers
missing registration, zero-index anchors, fallback, visibility rejection, range,
copy isolation, output bounds, collector/provider errors, lazy loading, renderer
failure, and cleanup. The lamp runs without a constants include using the axis
locals supplied by the unit-script-header contract.

All six test groups and the changed Lua files' syntax checks passed locally on
Lua 5.4. Recoil gameplay/GPU output has NOT been validated in this environment.
