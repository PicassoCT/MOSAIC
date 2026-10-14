# Reusable building fire and tank muzzle instrumentation

This branch is a retained debugging archive for future developers and coding
assistants. The instrumentation is stored in the repository, not only in a chat.
Do not delete this branch merely because its original commits are already in
master's history. It is not a feature branch to merge wholesale into master.

## Identity and scope

- Archive branch: `debug/building-fire-tank-muzzle-tracing`.
- Instrumentation commit: `cf2e2f04bdc4d9369b0eb0adda63b2030d9ad5fd`
  (`debug: trace building fire and tank muzzle delivery`).
- Preserved runtime snapshot: `c0982bac374dd211761eac305d393c193c1763a8`,
  the master head inspected on 2026-10-14. This retains the functional changes
  made after the original instrumentation commit; it is not a checkout of the
  older gameplay implementation.
- This documentation commit changes no runtime code. Creating the archive does
  not remove or disable the instrumentation on master.
- The separate `debug: trace remnant and finite-effect transitions` commit
  (`b96d1a177fa416b55c7ee4b4b866957f3e907a8a`) was already reverted in the
  preserved snapshot. It is not restored by this archive.

The runtime snapshot is historical, not automatically kept in sync with master.
The original instrumentation commit remains the identifiable diagnostic patch.

## What is preserved

`luarules/gadgets/include/execution_trace.lua` supplies bounded, deduplicated
`Spring.Echo` traces. The instrumented paths cover structural damage admission,
block lookup and collapse, building fire registration, synced-to-client ribbon
delivery, renderer rejection and CPU draw submission, tank shot publication,
muzzle source construction and budgets, and graphene electrical ribbon delivery.
Trace identity includes unit, cycle/frame, piece and slot where applicable.

The tests and CI configuration in the snapshot are preserved too. Diagnostics
are enabled by the instrumented code; this archive does not add a runtime toggle.
They have allocation, bookkeeping and output costs despite duplicate suppression.
Keep temporary tracing separate from gameplay or visual fixes.

The detailed stage guide is [docs/building-effects-tracing.md](docs/building-effects-tracing.md).
That guide describes the original diagnostic commit. Its 50% health threshold,
24-by-5 flame dimensions, distance cutoff and short lifetime examples are
historical, not instructions to restore those settings. Read the current
`scripts/lib_mosaic.lua`, `scripts/lib_building_damage.lua`,
`scripts/lib_building_damage_effects.lua` and renderer when interpreting a new run.

## Inspect without changing your working tree

Run these commands from a MOSAIC checkout:

```sh
git fetch origin
git show origin/debug/building-fire-tank-muzzle-tracing:DEBUG-INSTRUMENTATION.md
git show --stat cf2e2f04bdc4d9369b0eb0adda63b2030d9ad5fd
git show cf2e2f04bdc4d9369b0eb0adda63b2030d9ad5fd -- scripts luarules luaui
```

For the complete archived runtime, create an isolated worktree rather than
replacing files in your current checkout:

```sh
git worktree add --detach ../MOSAIC-tracing-archive origin/debug/building-fire-tank-muzzle-tracing
```

## Reapply tracing to a future version

First inspect the target branch. If the diagnostics are already active, do not
apply them twice. Check the helper's users, not only the presence of the helper:

```sh
git grep -n 'execution_trace.lua' origin/master -- scripts luarules luaui
```

If tracing has been removed, start from a clean working tree and make a new,
short-lived debugging branch from the then-current master. Review the actual
instrumentation-removal commit first: reverting that removal on the new branch
may be preferable because it can restore instrumentation adapted to newer code.
Only do that when the removal commit is diagnostic-only.

Alternatively, apply the original diagnostic patch explicitly:

```sh
git switch -c debug/reapply-building-fire-tank-muzzle origin/master
git cherry-pick -x cf2e2f04bdc4d9369b0eb0adda63b2030d9ad5fd
```

Conflicts are possible and must be resolved against the current implementation.
Do not select the entire archived version of a conflicting file. Preserve current
health thresholds, damage accounting, support/remnant rules, visibility, fire
geometry and lifetimes, muzzle timing, CEGs, LOS checks and rendering budgets.
Port only the logger, diagnostic metadata, logging calls and corresponding tests.
Use `git cherry-pick --abort` to abandon an unsuccessful attempt without guessing.
Inspect `git diff origin/master...HEAD` before publishing the debugging branch.

**Do not simply merge this archive to undo a later revert.** The original debug
commit can already be an ancestor of master even after its changes were reverted.
A merge does not replay that old patch. Do not reset master to this snapshot or
restore whole historical runtime files as a shortcut.

## Validation and log reading

After a reapplication, inspect the current versions of
`.github/workflows/building-block-damage.yml` and
`.github/workflows/effects-validation.yml` and run the relevant checks. Useful
entry points preserved here include:

```sh
lua5.1 tests/execution_trace_test.lua
lua5.4 tests/execution_trace_test.lua
lua5.1 tests/building_block_damage_test.lua
lua5.4 tests/building_block_damage_test.lua
lua5.1 tests/building_damage_header_test.lua
lua5.4 tests/building_damage_header_test.lua
lua5.1 tests/building_rubble_lifecycle_test.lua
lua5.4 tests/building_rubble_lifecycle_test.lua
lua5.1 tests/smoke_ribbons_lifecycle.lua
lua5.1 tests/tank_muzzle_effects.lua
```

These are reproduction instructions, not a claim that tests were rerun while
creating the archive. Engine/GPU validation is separate from mocked Lua tests.
Run a damaged-house and tank-firing scenario in Recoil and inspect `infolog.txt`:

```sh
rg '\[(BuildingDestruction|TankMuzzle|SmokeRibbon|GrapheneArcs)\]' infolog.txt
```

Correlate a unit and cycle through registration, receipt, source preparation,
rejection or draw submission. `draw_submitted` means the CPU draw call returned;
it does not prove that visible pixels appeared on the player's GPU.

After diagnosis, keep functional fixes in their own commits and remove temporary
instrumentation from the normal gameplay branch. Leave this archive available
for the next investigation.
