# Tooling location

- Store new authoring, export, and validation tooling outside the game checkout, under `/home/picasso/MosaicDev/Tools`.
- Do not add tooling to the game folder. External regression tests continue to use the dedicated location below.

# Preserve decision sets

- Read [Decision set style for agents](docs/decision-set-style.md) when adding or changing classification, eligibility, dispatch, or per-kind configuration.
- Represent a domain's membership rules as named lookup sets and its associated values as dictionaries or profiles. Extend existing sets instead of appending chains such as `name == "a" or name == "b" or name == "c"` or the equivalent exclusions.
- Follow the property-set and profile patterns in `scripts/lib_mosaic.lua`. Reuse an existing helper when its membership and meaning match exactly; do not merge distinct policies just because their members overlap.
- Construct stable sets once per owning module/environment, or once after the required definitions become available. Keep changing game-state checks live and preserve short-circuit evaluation.
- Preserve exact return values, defaults, accepted members, branch priority, iteration/random ordering, and side effects. A style refactor must not change reachable content or gameplay.
- Keep ordinary guards, range checks, and conditions on independent facts readable. Do not turn every `and`/`or` into a table or introduce a generic rule engine.

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
