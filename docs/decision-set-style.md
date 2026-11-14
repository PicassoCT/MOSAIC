# Decision set style for agents

MOSAIC expresses domain decisions through named sets, dictionaries, and profiles. When editing code, preserve this style and the existing behavior. A new unit, effect, command, or category should usually require a data entry in the relevant policy, rather than another comparison scattered through the code.

The reference patterns are in [lib_mosaic.lua](../scripts/lib_mosaic.lua): `structuralHouseBases`, `structuralHouseVariantKeys`, `buildingRuinNames`, the building shadow profiles, and `getTypeTable`. Inspect the actual helper before reusing it; similar names do not guarantee identical membership or return shapes.

## Choose the representation by meaning

| Decision | Representation |
| --- | --- |
| Does this name or ID belong to a category? | A named set with `true` values |
| Which value belongs to this key? | A dictionary |
| Which settings belong to this kind? | A profile dictionary |
| Which operation handles this exact key? | A function dictionary, if handler signatures and fallback behavior fit |
| Which rule takes precedence? | Explicit control flow or an ordered rule list |
| Is a live object valid, visible, in range, or ready? | Live checks with the existing evaluation order |

Use names that explain the decision: `roadSurfaceNames`, `transitCommands`, or `baselineIndependentTextFx`. Avoid names such as `allowed`, `lookup`, or `specialCases` when they obscure the policy.

## Use sets for membership

Do not extend this form:

```lua
return name == "wallImpactText" or name == "smilingFace"
    or name == "letterPlant" or name == "meteorCraterText"
    or name == "splineShapeFollowing"
```

Represent that same membership explicitly:

```lua
local shapedTextEffects = {
    wallImpactText = true,
    smilingFace = true,
    letterPlant = true,
    meteorCraterText = true,
    splineShapeFollowing = true,
}

local function isShapedTextEffect(name)
    return shapedTextEffects[name] == true
end
```

This example covers only the listed membership. When refactoring a larger function, retain every additional member, special case, and fallback. For example, `canProjectTextFx` has a matrix-specific upright rule and a horizontal-layout fallback; replacing the entire function with a set lookup would lose behavior.

For exclusions, use `if not excludedKinds[kind] then ... end`. In boolean-returning APIs, compare a boolean set lookup with `true` so an unknown key still returns `false`, rather than `nil`. Profile dictionaries contain records, so test their presence instead of comparing their entries with `true`.

Three or more equality comparisons against the same discriminator are a strong signal that a set is required. Two comparisons can also deserve a set when they express a named policy or recur. An ordinary binary choice does not need a table just to satisfy a count.

## Keep related values in one profile

When membership and several values depend on the same kind, use one profile instead of parallel comparison chains or separate dictionaries that must stay synchronized:

```lua
local explosionProfiles = {
    sticky = {life = .55, radius = 150},
    emp = {life = .45, radius = 95},
    mortar = {life = .45, radius = 115},
    gun = {life = .09, radius = 65},
}

local profile = explosionProfiles[kind]
if not profile then return false end
-- Existing visibility, ownership, and other live checks still apply here.
local expires = frame + math.max(1, math.ceil(profile.life * fps))
```

Likewise, use a name-to-note dictionary for fixed UI text. Function dispatch tables must store function references or closures, not invoke all handlers while constructing the table. Preserve the selected handler's arguments, return values, and unknown-key behavior.

## Put the policy at the right scope

- Build stable tables once at module scope or after their required `CMD`/unit definitions exist. Do not allocate an identical table inside every frame, unit loop, or predicate call.
- Use local tables for local decisions. Share a pure helper when multiple consumers implement the same policy; follow existing include boundaries rather than loading a large library just for a tiny set.
- Match the key to the caller: names and definition IDs are different domains. Build a definition-ID set once when IDs are needed in a hot path.
- Keep shared profiles read-only by convention. Copy a profile before attaching per-unit mutable state.
- Keep related but different policies separate. Operational satellites and all orbital objects differ; so do lighting/barrier placement and lighting/barrier/clutter placement.
- Do not cache live visibility, ownership, health, or command state in a static decision set. Preserve any existing invalidation or reload behavior for derived sets.

## Preserve Lua semantics and game behavior

An `and` chain checking different facts is not automatically a membership decision:

```lua
if target and Spring.ValidUnitID(target) and inRange(target) then
    attack(target)
end
```

Keep its guards and short-circuit behavior. Replacing it with a table of evaluated predicates would call `inRange` even when earlier checks fail. Numeric ranges, pattern matches, and priority-sensitive rules also need their existing semantics. A set can cover exact names alongside a separate pattern match; it cannot replace that pattern's open-ended membership.

Preserve these details in every conversion:

- `nil`, `false`, `0`, `1`, `"1"`, and `"true"` are distinct. Lua treats `0` and empty strings as truthy. Do not broaden accepted encodings with a truthiness test.
- `dictionary[key] or default` discards a stored `false`. Use an explicit `nil` check when `false` is a meaningful value.
- Computed table keys must exist at construction time. A nil key cannot be inserted; do not move initialization ahead of the definitions it requires.
- Sets are unordered. Do not replace an ordered array with `pairs` iteration where effect order, first-match priority, random-number consumption, weighted selection, or synced determinism matters.
- Preserve engine-call order, error/fallback behavior, and whether a function returns a boolean, a record, multiple values, or no values.
- Retain all authored entries and reachable branches. Style cleanup does not authorize removing variants, dialogue, effects, or procedural complexity.

## Review before finishing

1. Search for an existing set/helper and other consumers of the policy. Confirm that reuse preserves the exact membership and meaning.
2. Compare every old accepted and rejected case with the new representation, including missing/unknown keys and any special-case precedence.
3. Check defaults, return types, ordering, side effects, initialization timing, and allocation scope. Update the policy data directly when adding a member; do not append a comparison beside the lookup.
4. Run relevant existing external regression tests through the runner described in [AGENTS.md](../AGENTS.md). Add focused equivalence coverage when a meaningful behavior risk is otherwise untested; do not add tests that merely duplicate the dictionary.
5. Report what changed and what was checked. Keep unrelated bug fixes and content changes separate from the style refactor.

Apply these rules to the requested work. Do not launch a repository-wide rewrite, invent a generic predicate framework, or replace useful control flow solely to eliminate the words `if`, `and`, or `or`.
