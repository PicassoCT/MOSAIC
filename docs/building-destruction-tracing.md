# Temporary building destruction traces

The `debug: trace building destruction execution` commit enables `Spring.Echo`
breadcrumbs by default. The preceding fix commit repairs the reviewed gadget's
missing `UnitDefs` argument and removes two echoes that concatenated a table.
Revert only the debug commit when diagnosis is finished; keep the prerequisite fix.

## Read the infolog

Search `infolog.txt` for `[BuildingDestruction]`. Each line contains a simulation
frame, the house's unit ID, a stage, and named values. For example, the format of a
damage observation is:

```text
[BuildingDestruction] frame=... unit=... stage=block_damage_accumulated column=... damage=... increment=... level=... piece=... strength=...
```

Filter one house with `unit=<ID>` followed by a space. Rubble/reconstruction traces
keep the original house in that field and additionally carry `plot`,
`originalUnitID`, `sourceUnitID`, and `currentUnitID`. Creation messages include
the new `rubbleUnitID` or `siteUnitID` even before the lifecycle assigns it.
Use the plot ID to distinguish successive lifetimes if the engine reuses an ID.

```sh
rg '\[BuildingDestruction\]' infolog.txt
rg '\[BuildingDestruction\].* unit=42 ' infolog.txt
```

## Follow the path

| Stage group | Successful observations | Reasons a following stage may be absent |
| --- | --- | --- |
| Gadget startup | `damage_gadget_load_begin`, `damage_gadget_ready` | A load-time error between them; the ready message includes eligible type count and batch cadence. |
| Structure registration | `structure_initialize_begin`, `structure_piece_map_ready`, `structure_initialize_ready` | Initialization stopped; the ready message reports block and column counts, including empty structures. |
| Damage delivery | `damage_received`, `damage_accepted`, `damage_queued`, `damage_dispatch_begin`, `house_damage_callback`, `structural_update_received` | `damage_skipped` reports health/paralyzer gates; `damage_dispatch_skipped` reports missing scripts/callbacks or a dead unit. |
| Block damage | `block_lookup_begin`, `block_lookup_selected`, `block_damage_accumulated` | Missing eligible geometry, a pending failure, or an unavailable health value is reported explicitly. Selection logs identify the source, piece, coordinates and comparison metric. |
| Partial collapse | `block_failure_scheduled`, `block_failure_due`, `block_detach_begin`, `block_settle_begin`, `block_settle_issued`, `block_fall_hide_complete` | Deferred column limits are reported; scheduling includes the due frame, and movement includes drop/time and root count. |
| Full collapse | `house_killed_callback`, `collapse_begin`, `collapse_floor_begin`, `collapse_floor_complete`, `collapse_complete` | A not-yet-initialized structure takes the separately logged partial-cleanup path. |
| Rubble handoff | `city_house_destroyed`, `plot_queued`, `source_removal_observed`, `rubble_definition_selected`, `rubble_unit_created`, `rubble_visibility_applied`, `rubble_blocking_applied`, `rubble_spawned` | `source_removal_waiting` means the old unit ID still exists; failed creation and queue skips carry a reason. |
| Reconstruction | `rebuild_peaceful`, `site_spawned`, `rebuild_completed` | `rebuild_paused` carries the peace/global-state reason; failed site creation reports the attempt and preserves the existing retry behavior. |

The city's destruction observer can queue a plot before the Killed animation
finishes. Waiting for the old unit's removal is a logged lifecycle stage.

These messages confirm that the corresponding Lua statements ran or returned.
They do not prove that a model rendered correctly. In particular,
`block_settle_issued` confirms movement commands were issued; it is not a visual
or physical validation of the resulting geometry.

## Output volume and safety

- Repeated damage observations are sampled every 30 simulation frames per
  house/stage/piece/reason. Distinct pieces and reasons remain distinct.
- Repeated rubble waits and failed spawn attempts are sampled every 150 frames
  per plot. The next emitted sample includes the number of suppressed repeats.
- Actual state transitions are printed immediately. No per-frame heartbeat or
  per-vertex/piece-position scan was added for tracing.
- Only eligible buildings or already queued structural damage are traced by the
  damage gadget; unrelated unit destruction does not generate those messages.
- Logger state is cleared on unit destruction/reuse and completed reconstruction.
- Values are formatted as scalars, so a table cannot cause a concatenation error.
  Failure of the echo output sink is contained inside the logger.

## Verification

The existing damage and rubble lifecycle fixtures execute the real logger and
assert delivery of the important stages, including original-house/plot/replacement
correlation. `tests/building_destruction_trace_test.lua` checks formatting,
sampling, distinct-entity isolation, cleanup and a failing output sink.
All run with Lua 5.1. In-engine visual validation remains a separate step.

Find the diagnostics commit with `git log --oneline --grep='^debug: trace building destruction execution$'`.
Use `git revert <diagnostics-commit>` to remove the instrumentation, helper,
trace-specific test additions and this guide together.
