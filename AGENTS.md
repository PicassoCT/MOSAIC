# Visual effect sizing

- When the emitting object's proportions are known, use those proportions to size new visual effects.
- When proportions are unknown, start oversized, then halve the effect's linear dimensions on each visual iteration until it fits.
- Preserve the effect's proportions while halving it unless the user requests a specific dimension or shape change.
- This is a development tuning process, not automatic shrinking during gameplay. Explicit user sizing instructions take precedence.

# Preserve content complexity

- Ask the user for explicit confirmation before removing, sanitizing, or simplifying existing content, procedural variation, dialogue branches, or combinatorial complexity.
- Refactors, readability improvements, performance work, and harness/tool suggestions do not authorize content reduction. Preserve existing content and reachable behavior while improving the surrounding system.
- If a proposed change would reduce that complexity, explain the concrete loss and wait for confirmation before making it.

# External regression tests

- Test sources and fixtures live outside the game checkout at `/home/picasso/MosaicDev/tests/MOSAIC`, on the separate `mosaic-tests` branch of this repository.
- Do not recreate an in-game `tests/` directory. Run `/home/picasso/MosaicDev/tests/MOSAIC/run.sh -- <test command>`; it provides a temporary external workspace with the original `tests/...` paths.
- GitHub checks use `.github/actions/external-tests` and the exact suite commit in `.github/mosaic-tests.ref`. Publish suite changes on `mosaic-tests`, then update that pin. Never merge the test-only branch into a game branch.
